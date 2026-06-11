# Auto-generated client for Vercel API v0.0.1
# Source: https://openapi.vercel.sh/
# Auth: --token flag or $env.VERCEL_API_TOKEN

const BASE_URL = "https://api.vercel.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VERCEL_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.vercel.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def role-completer [] { ["ADMIN" "PROJECT_DEVELOPER" "PROJECT_VIEWER"] }
def role-completer-1 [] { ["" "ADMIN" "PROJECT_DEVELOPER" "PROJECT_VIEWER"] }
def sort-by-completer [] { ["destination" "source" "statusCode"] }
def sort-order-completer [] { ["asc" "desc"] }
def action-completer [] { ["discard" "promote" "restore"] }
def blocks-completer [] { ["build-start" "deployment-alias" "deployment-promotion" "deployment-start" "none"] }
def requires-completer [] { ["build-ready" "deployment-url" "none"] }
def requires-completer-1 [] { ["build-ready" "deployment-url"] }
def status-completer [] { ["completed" "queued" "running"] }
def conclusion-completer [] { ["canceled" "failed" "neutral" "skipped" "succeeded" "timeout"] }
def status-completer-1 [] { ["completed" "running"] }
def conclusion-completer-1 [] { ["canceled" "failed" "neutral" "skipped" "succeeded"] }
def direction-completer [] { ["backward" "forward"] }
def follow-completer [] { ["0" "1"] }
def delimiter-completer [] { ["0" "1"] }
def builds-completer [] { ["0" "1"] }
def accept-completer [] { ["application/json" "application/stream+json"] }
def status-completer-2 [] { ["failed" "running" "succeeded"] }
def forceNew-completer [] { ["0" "1"] }
def skipAutoDetectionConfirmation-completer [] { ["0" "1"] }
def type-completer [] { ["A" "AAAA" "ALIAS" "CAA" "CNAME" "HTTPS" "MX" "NS" "SRV" "TXT"] }
def type-completer-1 [] { ["" "A" "AAAA" "ALIAS" "CAA" "CNAME" "HTTPS" "MX" "NS" "SRV" "TXT"] }
def strict-completer [] { ["false" "true"] }
def deliveryFormat-completer [] { ["json" "ndjson"] }
def projects-completer [] { ["all" "some"] }
def status-completer-3 [] { ["disabled" "enabled"] }
def target-completer [] { ["preview" "production"] }
def type-completer-2 [] { ["encrypted" "sensitive"] }
def state-completer [] { ["active" "archived"] }
def kind-completer [] { ["boolean" "json" "number" "string"] }
def sdkKeyType-completer [] { ["client" "mobile" "server"] }
def provider-completer [] { ["bitbucket" "github" "github-custom-host" "github-limited" "gitlab"] }
def source-completer [] { ["backoffice" "cli" "deploy-button" "external" "marketplace" "oauth" "resource-claims" "v0"] }
def status-completer-4 [] { ["error" "onboarding" "pending" "ready" "resumed" "suspended" "uninstalled"] }
def ownership-completer [] { ["linked" "owned" "sandbox"] }
def action-completer-1 [] { ["refund"] }
def view-completer [] { ["account" "project"] }
def installationType-completer [] { ["external" "marketplace" "provisioning"] }
def grant-type-completer [] { ["authorization_code"] }
def category-completer [] { ["experiment" "flag"] }
def filter-completer [] { ["redirect" "rewrite" "set_status" "transform"] }
def gitForkProtection-completer [] { ["0" "1"] }
def elasticConcurrencyEnabled-completer [] { ["0" "1"] }
def staticIpsEnabled-completer [] { ["0" "1"] }
def buildQueueConfiguration-completer [] { ["SKIP_NAMESPACE_QUEUE" "WAIT_FOR_NAMESPACE_QUEUE"] }
def framework-completer [] { ["" "actix-web" "angular" "ash" "astro" "axum" "blitzjs" "brunch" "create-react-app" "django" "docusaurus" "docusaurus-2" "dojo" "eleventy" "elysia" "ember" "eve" "express" "fastapi" "fasthtml" "fastify" "flask" "gatsby" "go" "gridsome" "h3" "hexo" "hono" "hugo" "hydrogen" "ionic-angular" "ionic-react" "jekyll" "koa" "mastra" "middleman" "nestjs" "nextjs" "nitro" "node" "nuxtjs" "parcel" "polymer" "preact" "python" "react-router" "redwoodjs" "remix" "ruby" "rust" "saber" "sanity" "sanity-v2" "sapper" "scully" "services" "solidstart" "solidstart-1" "stencil" "storybook" "svelte" "sveltekit" "sveltekit-1" "tanstack-start" "umijs" "vite" "vitepress" "vue" "vuepress" "xmcp" "zola"] }
def nodeVersion-completer [] { ["10.x" "12.x" "14.x" "16.x" "18.x" "20.x" "22.x" "24.x"] }
def production-completer [] { ["false" "true"] }
def redirects-completer [] { ["false" "true"] }
def verified-completer [] { ["false" "true"] }
def order-completer [] { ["ASC" "DESC"] }
def redirectStatusCode-completer [] { ["" "301" "302" "307" "308"] }
def decrypt-completer [] { ["false" "true"] }
def type-completer-3 [] { ["encrypted" "plain" "sensitive" "system"] }
def state-completer-1 [] { ["ABORTED" "ACTIVE" "COMPLETE"] }
def sortBy-completer [] { ["createdAt" "currentSnapshotId" "name" "statusUpdatedAt"] }
def sortOrder-completer [] { ["asc" "desc"] }
def runtime-completer [] { ["node22" "node24" "node26" "python3.13"] }
def sortBy-completer-1 [] { ["createdAt" "name" "updatedAt"] }
def accept-completer-1 [] { ["application/json" "application/x-ndjson"] }
def wait-completer [] { ["false" "true"] }
def mode-completer [] { ["allow-all" "custom" "default-allow" "default-deny" "deny-all"] }
def action-completer-2 [] { ["firewallEnabled"] }
def role-completer-2 [] { ["BILLING" "CONTRIBUTOR" "DEVELOPER" "MEMBER" "OWNER" "SECURITY" "VIEWER" "VIEWER_FOR_PLUS"] }
def confirmed-completer [] { ["true"] }
def dpAccessRequestsMode-completer [] { ["all" "email-domain" "none"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-groups readAccessGroup" } } | get name | first)
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

# Reads an access group
#
# GET /v1/access-groups/{idOrName}
# operationId: readAccessGroup
export def "access-groups readAccessGroup" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<teamPermissions: list<string>, entitlements: list<string>, isDsyncManaged: bool, name: string, createdAt: string, teamId: string, updatedAt: string, accessGroupId: string, membersCount: float, projectsCount: float, teamRoles: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an access group
#
# POST /v1/access-groups/{idOrName}
# operationId: updateAccessGroup
# --projects item shape: {projectId: string, role: "ADMIN"|"PROJECT_VIEWER"|"PROJECT_DEVELOPER"|""}
export def "access-groups updateAccessGroup" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string # The name of the access group (e.g. My access group)
  --projects: list # item shape: {projectId: string, role: "ADMIN"|"PROJECT_VIEWER"|"PROJECT_DEVELOPER"|""}
  --membersToAdd: list # List of members to add to the access group. (e.g. [usr_1a2b3c4d5e6f7g8h9i0j, usr_2b3c4d5e6f7g8h9i0j1k])
  --membersToRemove: list # List of members to remove from the access group. (e.g. [usr_1a2b3c4d5e6f7g8h9i0j, usr_2b3c4d5e6f7g8h9i0j1k])
]: any -> record<entitlements: list<string>, name: string, createdAt: string, teamId: string, updatedAt: string, accessGroupId: string, membersCount: float, projectsCount: float, teamRoles: list<string>, teamPermissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($idOrName)" $qp)
  let body = {name: $name, projects: $projects, membersToAdd: $membersToAdd, membersToRemove: $membersToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an access group
#
# DELETE /v1/access-groups/{idOrName}
# operationId: deleteAccessGroup
export def "access-groups delete" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List members of an access group
#
# GET /v1/access-groups/{idOrName}/members
# operationId: listAccessGroupMembers
export def "access-groups-members listAccessGroupMembers" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit how many access group members should be returned. (e.g. 20)
  --next: string # Continuation cursor to retrieve the next page of results.
  --search: string # Search project members by their name, username, and email.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<members: table<avatar: string, email: string, uid: string, username: string, name: string, createdAt: string, teamRole: string>, pagination: record<count: float, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($idOrName)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List access groups for a team, project or member
#
# GET /v1/access-groups
# operationId: listAccessGroups
export def "access-groups listAccessGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # Filter access groups by project. (e.g. prj_pavWOn1iLObbx3RowVvzmPrTWyTf)
  --search: string # Search for access groups by name. (e.g. example)
  --membersLimit: int # Number of members to include in the response. (e.g. 20)
  --projectsLimit: int # Number of projects to include in the response. (e.g. 20)
  --limit: int # Limit how many access group should be returned. (e.g. 20)
  --next: string # Continuation cursor to retrieve the next page of results.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "membersLimit" $membersLimit "scalar") (serialize-qp "projectsLimit" $projectsLimit "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/access-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an access group
#
# POST /v1/access-groups
# operationId: createAccessGroup
# --projects item shape: {projectId: string, role: "ADMIN"|"PROJECT_VIEWER"|"PROJECT_DEVELOPER"|""}
export def "access-groups createAccessGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string # The name of the access group (e.g. My access group)
  --projects: list # item shape: {projectId: string, role: "ADMIN"|"PROJECT_VIEWER"|"PROJECT_DEVELOPER"|""}
  --membersToAdd: list # List of members to add to the access group. (e.g. [usr_1a2b3c4d5e6f7g8h9i0j, usr_2b3c4d5e6f7g8h9i0j1k])
]: any -> record<entitlements: list<string>, membersCount: float, projectsCount: float, name: string, createdAt: string, teamId: string, updatedAt: string, accessGroupId: string, teamRoles: list<string>, teamPermissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/access-groups" $qp)
  let body = {name: $name, projects: $projects, membersToAdd: $membersToAdd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List projects of an access group
#
# GET /v1/access-groups/{idOrName}/projects
# operationId: listAccessGroupProjects
export def "access-groups-projects listAccessGroupProjects" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit how many access group projects should be returned. (e.g. 20)
  --next: string # Continuation cursor to retrieve the next page of results.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<projects: table<projectId: string, role: string, createdAt: string, updatedAt: string, project: record>, pagination: record<count: float, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($idOrName)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an access group project
#
# POST /v1/access-groups/{accessGroupIdOrName}/projects
# operationId: createAccessGroupProject
export def "access-groups-projects createAccessGroupProject" [
  accessGroupIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  projectId: string # The ID of the project. (e.g. prj_ndlgr43fadlPyCtREAqxxdyFK)
  role: string@role-completer # The project role that will be added to this Access Group. (e.g. ADMIN)
]: any -> record<teamId: string, accessGroupId: string, projectId: string, role: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($accessGroupIdOrName)/projects" $qp)
  let body = {projectId: $projectId, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reads an access group project
#
# GET /v1/access-groups/{accessGroupIdOrName}/projects/{projectId}
# operationId: readAccessGroupProject
export def "access-groups-projects readAccessGroupProject" [
  accessGroupIdOrName: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<teamId: string, accessGroupId: string, projectId: string, role: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($accessGroupIdOrName)/projects/($projectId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an access group project
#
# PATCH /v1/access-groups/{accessGroupIdOrName}/projects/{projectId}
# operationId: updateAccessGroupProject
export def "access-groups-projects updateAccessGroupProject" [
  accessGroupIdOrName: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  role: string@role-completer-1 # The project role that will be added to this Access Group. (e.g. ADMIN)
]: any -> record<teamId: string, accessGroupId: string, projectId: string, role: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($accessGroupIdOrName)/projects/($projectId)" $qp)
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an access group project
#
# DELETE /v1/access-groups/{accessGroupIdOrName}/projects/{projectId}
# operationId: deleteAccessGroupProject
export def "access-groups-projects delete" [
  accessGroupIdOrName: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/access-groups/($accessGroupIdOrName)/projects/($projectId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Record an artifacts cache usage event
#
# POST /v8/artifacts/events
# operationId: recordEvents
export def "artifacts-events recordEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --x-Artifact-Client-Ci: string # The continuous integration or delivery environment where this artifact is downloaded. (e.g. VERCEL)
  --x-Artifact-Client-Interactive: int # 1 if the client is an interactive shell. Otherwise 0 (e.g. 0)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts/events" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"'x-Artifact-Client-Ci'": $x_Artifact_Client_Ci, "'x-Artifact-Client-Interactive'": $x_Artifact_Client_Interactive} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status of Remote Caching for this principal
#
# GET /v8/artifacts/status
# operationId: status
export def "artifacts-status status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a cache artifact
#
# PUT /v8/artifacts/{hash}
# operationId: uploadArtifact
export def "artifacts uploadArtifact" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --content-Length: float # The artifact size in bytes
  --x-Artifact-Duration: float # The time taken to generate the uploaded artifact in milliseconds. (e.g. 400)
  --x-Artifact-Client-Ci: string # The continuous integration or delivery environment where this artifact was generated. (e.g. VERCEL)
  --x-Artifact-Client-Interactive: int # 1 if the client is an interactive shell. Otherwise 0 (e.g. 0)
  --x-Artifact-Tag: string # The base64 encoded tag for this artifact. The value is sent back to clients when the artifact is downloaded as the header `x-artifact-tag` (e.g. Tc0BmHvJYMIYJ62/zx87YqO0Flxk+5Ovip25NY825CQ=)
  --x-Artifact-Sha: string # The SHA of the source control revision that generated this artifact.
  --x-Artifact-Dirty-Hash: string # A hash representing uncommitted changes in the working directory when this artifact was generated.
  --body: record
]: any -> record<urls: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/artifacts/($hash)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"'content-Length'": $content_Length, "'x-Artifact-Duration'": $x_Artifact_Duration, "'x-Artifact-Client-Ci'": $x_Artifact_Client_Ci, "'x-Artifact-Client-Interactive'": $x_Artifact_Client_Interactive, "'x-Artifact-Tag'": $x_Artifact_Tag, "'x-Artifact-Sha'": $x_Artifact_Sha, "'x-Artifact-Dirty-Hash'": $x_Artifact_Dirty_Hash} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Download a cache artifact
#
# GET /v8/artifacts/{hash}
# operationId: downloadArtifact
export def "artifacts downloadArtifact" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --x-Artifact-Client-Ci: string # The continuous integration or delivery environment where this artifact is downloaded. (e.g. VERCEL)
  --x-Artifact-Client-Interactive: int # 1 if the client is an interactive shell. Otherwise 0 (e.g. 0)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/artifacts/($hash)" $qp)
  let extra_headers = {"'x-Artifact-Client-Ci'": $x_Artifact_Client_Ci, "'x-Artifact-Client-Interactive'": $x_Artifact_Client_Interactive} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a cache artifact exists
#
# HEAD /v8/artifacts/{hash}
# operationId: artifactExists
export def "artifacts artifactExists" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/artifacts/($hash)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query information about an artifact
#
# POST /v8/artifacts
# operationId: artifactQuery
export def "artifacts artifactQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  hashes: list # artifact hashes (e.g. [12HKQaOmR5t5Uy6vdcQsNIiZgHGB, 34HKQaOmR5t5Uy6vasdasdasdasd])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/artifacts" $qp)
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List FOCUS billing charges
#
# GET /v1/billing/charges
# operationId: listBillingCharges
export def "billing-charges listBillingCharges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Inclusive start of the date range as an ISO 8601 date-time string in UTC. (e.g. 2025-01-01T00:00:00.000Z)
  --qp-to: string # Exclusive end of the date range as an ISO 8601 date-time string in UTC. (e.g. 2025-01-31T00:00:00.000Z)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/billing/charges" $qp)
  let accept_val = "application/jsonl"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List FOCUS contract commitments
#
# GET /v1/billing/contract-commitments
# operationId: listContractCommitments
export def "billing-contract-commitments listContractCommitments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/billing/contract-commitments" $qp)
  let accept_val = "application/jsonl"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purchase credits
#
# POST /v1/billing/buy
# operationId: buyCredits
# --item shape: {type: "credits", creditType: "v0"|"gateway"|"agent", amount: int}
export def "billing-buy buyCredits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # The source of the purchase request. Defaults to `api` if not specified.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  item: record # shape: {type: "credits", creditType: "v0"|"gateway"|"agent", amount: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/billing/buy" $qp)
  let body = {item: $item} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stages new redirects for a project.
#
# PUT /v1/bulk-redirects
# operationId: stageRedirects
# --redirects item shape: {source: string, destination: string, statusCode?: any, permanent?: bool, caseSensitive?: bool, query?: bool, preserveQueryParams?: bool}
export def "bulk-redirects stageRedirects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  projectId: string
  teamId: string
  --overwrite: string@bool-completer
  --name: string
  --redirects: list # default: [] — item shape: {source: string, destination: string, statusCode?: any, permanent?: bool, caseSensitive?: bool, query?: bool, preserveQueryParams?: bool}
]: any -> record<alias: string, version: record<id: string, key: string, lastModified: float, createdBy: string, name: string, isStaging: bool, isLive: bool, redirectCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects" $qp)
  let body = {projectId: $projectId, teamId: $teamId, overwrite: $overwrite, name: $name, redirects: $redirects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets project-level redirects.
#
# GET /v1/bulk-redirects
# operationId: getRedirects
export def "bulk-redirects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --versionId: string
  --q: string
  --diff: string
  --page: int
  --per-page: int
  --sort-by: string@sort-by-completer
  --sort-order: string@sort-order-completer
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "versionId" $versionId "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "diff" $diff "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete project-level redirects.
#
# DELETE /v1/bulk-redirects
# operationId: deleteRedirects
export def "bulk-redirects delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string
  redirects: list # The redirects to delete. The source of the redirect is used to match the redirect to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects" $qp)
  let body = {name: $name, redirects: $redirects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit a project-level redirect.
#
# PATCH /v1/bulk-redirects
# operationId: editRedirect
# --redirect shape: {source: string, destination?: string, statusCode?: float, permanent?: bool, caseSensitive?: bool, query?: bool, preserveQueryParams?: bool}
export def "bulk-redirects editRedirect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string
  redirect: record # The redirect object to edit. The source field is used to match the redirect to modify. — shape: {source: string, destination?: string, statusCode?: float, permanent?: bool, caseSensitive?: bool, query?: bool, preserveQueryParams?: bool}
  --restore: string@bool-completer # If true, restores the redirect from the latest production version to staging.
]: any -> record<alias: string, version: record<id: string, key: string, lastModified: float, createdBy: string, name: string, isStaging: bool, isLive: bool, redirectCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects" $qp)
  let body = {name: $name, redirect: $redirect, restore: $restore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore staged project-level redirects to their production version.
#
# POST /v1/bulk-redirects/restore
# operationId: restoreRedirects
export def "bulk-redirects-restore restoreRedirects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string
  redirects: list # The redirects to restore. The source of the redirect is used to match the redirect to restore.
]: any -> record<version: record<id: string, key: string, lastModified: float, createdBy: string, name: string, isStaging: bool, isLive: bool, redirectCount: float, alias: string>, restored: list<string>, failedToRestore: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects/restore" $qp)
  let body = {name: $name, redirects: $redirects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the version history for a project's redirects.
#
# GET /v1/bulk-redirects/versions
# operationId: getVersions
export def "bulk-redirects-versions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<versions: table<id: string, key: string, lastModified: float, createdBy: string, name: string, isStaging: bool, isLive: bool, redirectCount: float, alias: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Promote a staging version to production or restore a previous production version.
#
# POST /v1/bulk-redirects/versions
# operationId: updateVersion
export def "bulk-redirects-versions updateVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  id: string
  action: string@action-completer
  --name: string
]: any -> record<version: record<id: string, key: string, lastModified: float, createdBy: string, name: string, isStaging: bool, isLive: bool, redirectCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bulk-redirects/versions" $qp)
  let body = {id: $id, action: $action, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all checks for a project
#
# GET /v2/projects/{projectIdOrName}/checks
# operationId: listProjectChecks
export def "projects-checks listProjectChecks" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --blocks: string@blocks-completer
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<checks: table<id: string, name: string, ownerId: string, projectId: string, isRerequestable: bool, requires: string, source: any, blocks: string, targets: list, sourceKind: string, sourceIntegrationConfigurationId: string, timeout: float, createdAt: float, updatedAt: float, deletedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "blocks" $blocks "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a check
#
# POST /v2/projects/{projectIdOrName}/checks
# operationId: createProjectCheck
# --source shape: {kind?: string, externalResourceId?: string, webhookId?: string, externalCheckName?: string, provider?: "github"}
export def "projects-checks createProjectCheck" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string
  --isRerequestable: string@bool-completer
  requires: string@requires-completer # default: deployment-url
  --targets: list
  --blocks: string@blocks-completer # default: deployment-alias
  --body-source: record # shape: {kind?: string, externalResourceId?: string, webhookId?: string, externalCheckName?: string, provider?: "github"}
  --timeout: float # default: 300
]: any -> record<id: string, name: string, ownerId: string, projectId: string, isRerequestable: bool, requires: string, source: any, blocks: string, targets: list<string>, sourceKind: string, sourceIntegrationConfigurationId: string, timeout: float, createdAt: float, updatedAt: float, deletedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/checks" $qp)
  let body = {name: $name, isRerequestable: $isRerequestable, requires: $requires, targets: $targets, blocks: $blocks, source: $body_source, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a check
#
# GET /v2/projects/{projectIdOrName}/checks/{checkId}
# operationId: getProjectCheck
export def "projects-checks get" [
  projectIdOrName: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string, name: string, ownerId: string, projectId: string, isRerequestable: bool, requires: string, source: any, blocks: string, targets: list<string>, sourceKind: string, sourceIntegrationConfigurationId: string, timeout: float, createdAt: float, updatedAt: float, deletedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/checks/($checkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check
#
# PATCH /v2/projects/{projectIdOrName}/checks/{checkId}
# operationId: updateProjectCheck
export def "projects-checks updateProjectCheck" [
  projectIdOrName: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string
  --isRerequestable: string@bool-completer
  --requires: string@requires-completer-1 # default: deployment-url
  --targets: list
  --blocks: string@blocks-completer # default: deployment-alias
  --timeout: float # default: 300
]: any -> record<id: string, name: string, ownerId: string, projectId: string, isRerequestable: bool, requires: string, source: any, blocks: string, targets: list<string>, sourceKind: string, sourceIntegrationConfigurationId: string, timeout: float, createdAt: float, updatedAt: float, deletedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/checks/($checkId)" $qp)
  let body = {name: $name, isRerequestable: $isRerequestable, requires: $requires, targets: $targets, blocks: $blocks, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a check
#
# DELETE /v2/projects/{projectIdOrName}/checks/{checkId}
# operationId: deleteProjectCheck
export def "projects-checks delete" [
  projectIdOrName: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/checks/($checkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List runs for a check
#
# GET /v2/projects/{projectIdOrName}/checks/{checkId}/runs
# operationId: listCheckRuns
export def "projects-checks-runs listCheckRuns" [
  projectIdOrName: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<runs: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/checks/($checkId)/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List check runs for a deployment
#
# GET /v2/deployments/{deploymentId}/check-runs
# operationId: listDeploymentCheckRuns
export def "deployments-check-runs listDeploymentCheckRuns" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<runs: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($deploymentId)/check-runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a check run
#
# POST /v2/deployments/{deploymentId}/check-runs
# operationId: createDeploymentCheckRun
export def "deployments-check-runs createDeploymentCheckRun" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  checkId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($deploymentId)/check-runs" $qp)
  let body = {checkId: $checkId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a check run
#
# GET /v2/deployments/{deploymentId}/check-runs/{checkRunId}
# operationId: getDeploymentCheckRun
export def "deployments-check-runs get" [
  deploymentId: string
  checkRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($deploymentId)/check-runs/($checkRunId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check run
#
# PATCH /v2/deployments/{deploymentId}/check-runs/{checkRunId}
# operationId: updateDeploymentCheckRun
export def "deployments-check-runs updateDeploymentCheckRun" [
  deploymentId: string
  checkRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --externalId: string
  --externalUrl: string # format: uri
  --status: string@status-completer
  --output: record
  --completedAt: float
  --conclusion: string@conclusion-completer
  --conclusionText: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($deploymentId)/check-runs/($checkRunId)" $qp)
  let body = {externalId: $externalId, externalUrl: $externalUrl, status: $status, output: $output, completedAt: $completedAt, conclusion: $conclusion, conclusionText: $conclusionText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new Check
#
# POST /v1/deployments/{deploymentId}/checks
# DEPRECATED
# operationId: createCheck
@deprecated
export def "deployments-checks createCheck" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string # The name of the check being created (e.g. Performance Check)
  --path: string # Path of the page that is being checked (e.g. /)
  --blocking: string@bool-completer # Whether the check should block a deployment from succeeding (e.g. true)
  --detailsUrl: string # URL to display for further details (e.g. http://example.com)
  --externalId: string # An identifier that can be used as an external reference (e.g. 1234abc)
  --rerequestable: string@bool-completer # Whether a user should be able to request for the check to be rerun if it fails (e.g. true)
]: any -> record<id: string, name: string, createdAt: float, updatedAt: float, deploymentId: string, status: string, conclusion: string, externalId: string, output: record<metrics: record<FCP: record, LCP: record, CLS: record, TBT: record, virtualExperienceScore: record>>, completedAt: float, path: string, blocking: bool, detailsUrl: string, integrationId: string, startedAt: float, rerequestable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks" $qp)
  let body = {name: $name, path: $path, blocking: $blocking, detailsUrl: $detailsUrl, externalId: $externalId, rerequestable: $rerequestable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of all checks
#
# GET /v1/deployments/{deploymentId}/checks
# DEPRECATED
# operationId: getAllChecks
@deprecated
export def "deployments-checks list" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<checks: table<completedAt: float, conclusion: string, createdAt: float, detailsUrl: string, id: string, integrationId: string, name: string, output: record, path: string, rerequestable: bool, blocking: bool, startedAt: float, status: string, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single check
#
# GET /v1/deployments/{deploymentId}/checks/{checkId}
# DEPRECATED
# operationId: getCheck
@deprecated
export def "deployments-checks get" [
  deploymentId: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string, name: string, createdAt: float, updatedAt: float, deploymentId: string, status: string, conclusion: string, externalId: string, output: record<metrics: record<FCP: record, LCP: record, CLS: record, TBT: record, virtualExperienceScore: record>>, completedAt: float, path: string, blocking: bool, detailsUrl: string, integrationId: string, startedAt: float, rerequestable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks/($checkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check
#
# PATCH /v1/deployments/{deploymentId}/checks/{checkId}
# DEPRECATED
# operationId: updateCheck
# --output shape: {metrics?: record}
@deprecated
export def "deployments-checks updateCheck" [
  deploymentId: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string # The name of the check being created (e.g. Performance Check)
  --path: string # Path of the page that is being checked (e.g. /)
  --status: any@status-completer-1 # The current status of the check
  --conclusion: any@conclusion-completer-1 # The result of the check being run
  --detailsUrl: string # A URL a user may visit to see more information about the check (e.g. https://example.com/check/run/1234abc)
  --output: record # The results of the check Run — shape: {metrics?: record}
  --externalId: string # An identifier that can be used as an external reference (e.g. 1234abc)
]: any -> record<id: string, name: string, createdAt: float, updatedAt: float, deploymentId: string, status: string, conclusion: string, externalId: string, output: record<metrics: record<FCP: record, LCP: record, CLS: record, TBT: record, virtualExperienceScore: record>>, completedAt: float, path: string, blocking: bool, detailsUrl: string, integrationId: string, startedAt: float, rerequestable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks/($checkId)" $qp)
  let body = {name: $name, path: $path, status: $status, conclusion: $conclusion, detailsUrl: $detailsUrl, output: $output, externalId: $externalId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerequest a check
#
# POST /v1/deployments/{deploymentId}/checks/{checkId}/rerequest
# DEPRECATED
# operationId: rerequestCheck
@deprecated
export def "deployments-checks-rerequest rerequestCheck" [
  deploymentId: string
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoUpdate: string@bool-completer # Mark the check as running
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoUpdate" $autoUpdate "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/checks/($checkId)/rerequest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Secure Compute networks
#
# GET /v1/connect/networks
# operationId: listNetworks
export def "connect-networks listNetworks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeHostedZones: string@bool-completer # Whether to include Hosted Zones in the response (default: true)
  --includePeeringConnections: string@bool-completer # Whether to include VPC Peering connections in the response (default: true)
  --includeProjects: string@bool-completer # Whether to include projects in the response (default: true)
  --search: string # The query to use as a filter for returned networks
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> table<awsAccountId: string, awsAvailabilityZoneIds: list<string>, awsRegion: string, cidr: string, createdAt: float, egressIpAddresses: list<string>, hostedZones: record<count: float>, id: string, name: string, peeringConnections: record<count: float>, projects: record<count: float, ids: list>, region: string, status: string, teamId: string, vpcId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeHostedZones" $includeHostedZones "scalar") (serialize-qp "includePeeringConnections" $includePeeringConnections "scalar") (serialize-qp "includeProjects" $includeProjects "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connect/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Secure Compute network
#
# POST /v1/connect/networks
# operationId: createNetwork
export def "connect-networks createNetwork" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --awsAvailabilityZoneIds: list
  cidr: string # The CIDR block of the network (e.g. 192.168.0.0/16)
  name: string # The name of the network
  region: string # The region where the network will be created (e.g. iad1)
]: any -> record<awsAccountId: string, awsAvailabilityZoneIds: list<string>, awsRegion: string, cidr: string, createdAt: float, egressIpAddresses: list<string>, hostedZones: record<count: float>, id: string, name: string, peeringConnections: record<count: float>, projects: record<count: float, ids: list<string>>, region: string, status: string, teamId: string, vpcId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connect/networks" $qp)
  let body = {awsAvailabilityZoneIds: $awsAvailabilityZoneIds, cidr: $cidr, name: $name, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Secure Compute network
#
# DELETE /v1/connect/networks/{networkId}
# operationId: deleteNetwork
export def "connect-networks delete" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connect/networks/($networkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Secure Compute network
#
# PATCH /v1/connect/networks/{networkId}
# operationId: updateNetwork
export def "connect-networks updateNetwork" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string # The name of the Secure Compute network
]: any -> record<awsAccountId: string, awsAvailabilityZoneIds: list<string>, awsRegion: string, cidr: string, createdAt: float, egressIpAddresses: list<string>, hostedZones: record<count: float>, id: string, name: string, peeringConnections: record<count: float>, projects: record<count: float, ids: list<string>>, region: string, status: string, teamId: string, vpcId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connect/networks/($networkId)" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read a Secure Compute network
#
# GET /v1/connect/networks/{networkId}
# operationId: readNetwork
export def "connect-networks readNetwork" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<awsAccountId: string, awsAvailabilityZoneIds: list<string>, awsRegion: string, cidr: string, createdAt: float, egressIpAddresses: list<string>, hostedZones: record<count: float>, id: string, name: string, peeringConnections: record<count: float>, projects: record<count: float, ids: list<string>>, region: string, status: string, teamId: string, vpcId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connect/networks/($networkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a connector
#
# POST /v1/connect/connectors
# operationId: createConnector
export def "connect-connectors createConnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string # Known types: api-key, github, oauth, salesforce, slack, snowflake.
  --service: string # Service slug or URL for which the connector is used.
  --uid: string
  --name: string
  --projectId: string # Link to the specified project when specified. See environments.
  --environments: list # Use these environments when linking to the project specified by the projectId.
  --triggers: string@bool-completer # Whether the triggers are enabled for this connector.
  --events: list # The list of the defaults trigger events for this connector.
  --icon: string # Branding icon. Either a SHA-1 hash already uploaded to the Vercel avatar service or an https:// URL that will be downloaded and rehosted.
  --backgroundColor: string # Branding background color (6-digit hex, e.g. "#000000").
  --accentColor: string # Branding accent color (6-digit hex, e.g. "#000000").
  data: any
]: any -> record<id: string, ownerId: string, createdAt: float, updatedAt: float, deletedAt: float, createdBy: any, updatedBy: any, public: bool, uid: string, type: string, service: string, name: string, clientUrl: string, redirectUri: string, defaultInstallationId: string, data: record, typeName: string, typeIcon: string, website: string, devsite: string, docsite: string, icon: string, backgroundColor: string, accentColor: string, supportedSubjectTypes: list<string>, appTokens: record<crossInstallation: bool, supportsRefinement: bool, requiresReinstallation: bool, scopes: list<string>, supportedAuthorizationDetails: list<string>>, userTokens: record<crossInstallation: bool, supportsRefinement: bool, scopes: list<string>, supportedAuthorizationDetails: list<string>>, supportsInstallation: bool, supportsRevocation: bool, ownerTenantId: string, supportsTriggers: bool, supportsIcon: any, triggers: record<enabled: bool>, events: list<string>, triggerDestinations: table<projectId: string, branch: string, path: string>, includes: record<projects: record<items: list, hasMore: bool, cursor: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connect/connectors")
  let body = {type: $type, service: $service, uid: $uid, name: $name, projectId: $projectId, environments: $environments, triggers: $triggers, events: $events, icon: $icon, backgroundColor: $backgroundColor, accentColor: $accentColor, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Connect token
#
# POST /v1/connect/token/{connector}
# operationId: getConnectorToken
# --authorizationDetails item shape: {type?: string}
export def "connect-token post" [
  connector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subject: any
  --installationId: string
  --audience: list
  --scopes: list
  --resources: list
  --authorizationDetails: list # item shape: {type?: string}
  --validityBufferMs: float
]: any -> record<token: string, expiresAt: float, connector: record<id: string, uid: string, type: string>, name: string, installationId: string, tenantId: string, externalSubject: string, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connect/token/($connector)")
  let body = {subject: $subject, installationId: $installationId, audience: $audience, scopes: $scopes, resources: $resources, authorizationDetails: $authorizationDetails, validityBufferMs: $validityBufferMs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Connect authorization request
#
# POST /v1/connect/authorize/{connector}
# operationId: createConnectorAuthorizationRequest
# --authorizationDetails item shape: {type?: string}
export def "connect-authorize createConnectorAuthorizationRequest" [
  connector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subject: any
  --installationId: string
  --audience: list
  --scopes: list
  --resources: list
  --authorizationDetails: list # item shape: {type?: string}
  --validityBufferMs: float
  --returnUrl: string
  --webhook: string
  --prompt: string
  --deviceCode: string@bool-completer
  --expiresInMs: float
  --additionalParams: record
]: any -> record<url: string, request: string, verifier: string, deviceCode: string, expiresAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connect/authorize/($connector)")
  let body = {subject: $subject, installationId: $installationId, audience: $audience, scopes: $scopes, resources: $resources, authorizationDetails: $authorizationDetails, validityBufferMs: $validityBufferMs, returnUrl: $returnUrl, webhook: $webhook, prompt: $prompt, deviceCode: $deviceCode, expiresInMs: $expiresInMs, additionalParams: $additionalParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get deployment events
#
# GET /v3/deployments/{idOrUrl}/events
# operationId: getDeploymentEvents
export def "deployments-events get" [
  idOrUrl: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --direction: string@direction-completer # Order of the returned events based on the timestamp. (default: forward, e.g. backward)
  --follow: float@follow-completer # When enabled, this endpoint will return live events as they happen. (e.g. 1)
  --limit: float # Maximum number of events to return. Provide `-1` to return all available logs. (e.g. 100)
  --name: string # Deployment build ID. (e.g. bld_cotnkcr76)
  --since: float # Timestamp for when build logs should be pulled from. (e.g. 1540095775941)
  --until: float # Timestamp for when the build logs should be pulled up until. (e.g. 1540106318643)
  --statusCode: string # HTTP status code range to filter events by. (e.g. 5xx)
  --delimiter: float@delimiter-completer # e.g. 1
  --builds: float@builds-completer # e.g. 1
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "statusCode" $statusCode "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "builds" $builds "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/deployments/($idOrUrl)/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update deployment integration action
#
# PATCH /v1/deployments/{deploymentId}/integrations/{integrationConfigurationId}/resources/{resourceId}/actions/{action}
# operationId: update-integration-deployment-action
export def "deployments-integrations-resources-actions update-integration-deployment-action" [
  deploymentId: string
  integrationConfigurationId: string
  resourceId: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2
  --statusText: string
  --statusUrl: string # format: uri
  --outcomes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/integrations/($integrationConfigurationId)/resources/($resourceId)/actions/($action)")
  let body = {status: $status, statusText: $statusText, statusUrl: $statusUrl, outcomes: $outcomes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a deployment by ID or URL
#
# GET /v13/deployments/{idOrUrl}
# operationId: getDeployment
export def "deployments get" [
  idOrUrl: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withGitRepoInfo: string # Whether to add in gitRepo information. (e.g. true)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withGitRepoInfo" $withGitRepoInfo "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v13/deployments/($idOrUrl)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new deployment
#
# POST /v13/deployments
# operationId: createDeployment
# --gitMetadata shape: {remoteUrl?: string, commitAuthorName?: string, commitAuthorEmail?: string, commitMessage?: string, commitRef?: string, commitSha?: string, dirty?: bool, ci?: bool, ciType?: string, ciGitProviderUsername?: string, ciGitRepoVisibility?: string}
# --projectSettings shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, framework?: ""|"blitzjs"|"nextjs"|"gatsby"|"remix"|"react-router"|"astro"|"hexo"|"eleventy"|"docusaurus-2"|"docusaurus"|"preact"|"solidstart-1"|"solidstart"|"dojo"|"ember"|"vue"|"scully"|"ionic-angular"|"angular"|"polymer"|"svelte"|"sveltekit"|"sveltekit-1"|"ionic-react"|"create-react-app"|"gridsome"|"umijs"|"sapper"|"saber"|"stencil"|"nuxtjs"|"redwoodjs"|"hugo"|"jekyll"|"brunch"|"middleman"|"zola"|"hydrogen"|"vite"|"tanstack-start"|"vitepress"|"vuepress"|"parcel"|"fastapi"|"flask"|"fasthtml"|"django"|"ash"|"eve"|"sanity"|"sanity-v2"|"storybook"|"nitro"|"hono"|"express"|"h3"|"koa"|"nestjs"|"elysia"|"fastify"|"xmcp"|"python"|"ruby"|"rust"|"axum"|"actix-web"|"node"|"go"|"services"|"mastra", installCommand?: string, nodeVersion?: "24.x"|"22.x"|"20.x"|"18.x"|"16.x"|"14.x"|"12.x"|"10.x"|"8.10.x", outputDirectory?: string, rootDirectory?: string, serverlessFunctionRegion?: string, skipGitConnectDuringLink?: bool, sourceFilesOutsideRootDirectory?: bool}
export def "deployments createDeployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceNew: string@forceNew-completer # Forces a new deployment even if there is a previous similar deployment
  --skipAutoDetectionConfirmation: string@skipAutoDetectionConfirmation-completer # Allows to skip framework detection so the API would not fail to ask for confirmation
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --customEnvironmentSlugOrId: string # Deploy to a custom environment, which will override the default environment
  --deploymentId: string # An deployment id for an existing deployment to redeploy (e.g. dpl_2qn7PZrx89yxY34vEZPD31Y9XVj6)
  --files: list # A list of objects with the files to be deployed
  --gitMetadata: record # Populates initial git metadata for different git providers. — shape: {remoteUrl?: string, commitAuthorName?: string, commitAuthorEmail?: string, commitMessage?: string, commitRef?: string, commitSha?: string, dirty?: bool, ci?: bool, ciType?: string, ciGitProviderUsername?: string, ciGitRepoVisibility?: string}
  --gitSource: any # Defines the Git Repository source to be deployed. This property can not be used in combination with `files`.
  --meta: record # An object containing the deployment's metadata. Multiple key-value pairs can be attached to a deployment (e.g. {foo: bar})
  --monorepoManager: string # The monorepo manager that is being used for this deployment. When `null` is used no monorepo manager is selected (nullable)
  name: string # A string with the project name used in the deployment URL (e.g. my-instant-deployment)
  --project: string # The target project identifier in which the deployment will be created. When defined, this parameter overrides name (e.g. my-deployment-project)
  --projectSettings: record # Project settings that will be applied to the deployment. It is required for the first deployment of a project and will be saved for any following deployments — shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, framework?: ""|"blitzjs"|"nextjs"|"gatsby"|"remix"|"react-router"|"astro"|"hexo"|"eleventy"|"docusaurus-2"|"docusaurus"|"preact"|"solidstart-1"|"solidstart"|"dojo"|"ember"|"vue"|"scully"|"ionic-angular"|"angular"|"polymer"|"svelte"|"sveltekit"|"sveltekit-1"|"ionic-react"|"create-react-app"|"gridsome"|"umijs"|"sapper"|"saber"|"stencil"|"nuxtjs"|"redwoodjs"|"hugo"|"jekyll"|"brunch"|"middleman"|"zola"|"hydrogen"|"vite"|"tanstack-start"|"vitepress"|"vuepress"|"parcel"|"fastapi"|"flask"|"fasthtml"|"django"|"ash"|"eve"|"sanity"|"sanity-v2"|"storybook"|"nitro"|"hono"|"express"|"h3"|"koa"|"nestjs"|"elysia"|"fastify"|"xmcp"|"python"|"ruby"|"rust"|"axum"|"actix-web"|"node"|"go"|"services"|"mastra", installCommand?: string, nodeVersion?: "24.x"|"22.x"|"20.x"|"18.x"|"16.x"|"14.x"|"12.x"|"10.x"|"8.10.x", outputDirectory?: string, rootDirectory?: string, serverlessFunctionRegion?: string, skipGitConnectDuringLink?: bool, sourceFilesOutsideRootDirectory?: bool}
  --target: string # Either not defined, `staging`, `production`, or a custom environment identifier. If `staging`, a staging alias in the format `<project>-<team>.vercel.app` will be assigned. If `production`, any aliases defined in `alias` will be assigned. If omitted, the target will be `preview`. (e.g. production)
  --withLatestCommit: string@bool-completer # When `true` and `deploymentId` is passed in, the sha from the previous deployment's `gitSource` is removed forcing the latest commit to be used.
]: any -> record<aliasAssignedAt: any, alwaysRefuseToBuild: bool, build: record<env: list<string>>, buildArtifactUrls: list<string>, builds: table<use: string, src: string, config: record>, env: list<string>, inspectorUrl: string, isInConcurrentBuildsQueue: bool, isInSystemBuildsQueue: bool, projectSettings: record<nodeVersion: string, buildCommand: string, devCommand: string, framework: string, commandForIgnoringBuildStep: string, installCommand: string, outputDirectory: string, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>>, integrations: record<status: string, startedAt: float, claimedAt: float, completedAt: float, skippedAt: float, skippedBy: string>, images: record<sizes: list<float>, qualities: list<float>, domains: list<string>, remotePatterns: list<record>, localPatterns: list<record>, minimumCacheTTL: float, formats: list<string>, dangerouslyAllowSVG: bool, contentSecurityPolicy: string, contentDispositionType: string>, alias: list<string>, aliasAssigned: bool, bootedAt: float, buildingAt: float, buildContainerFinishedAt: float, buildSkipped: bool, creator: record<uid: string, username: string, avatar: string>, initReadyAt: float, isFirstBranchDeployment: bool, lambdas: table<id: string, createdAt: float, readyState: string, entrypoint: string, readyStateAt: float, output: list>, public: bool, ready: float, status: string, team: record<id: string, name: string, slug: string, avatar: string>, userAliases: list<string>, previewCommentsEnabled: bool, ttyBuildLogs: bool, customEnvironment: any, oomReport: string, readyStateReason: string, aliasWarning: record<code: string, message: string, link: string, action: string>, id: string, createdAt: float, readyState: string, name: string, type: string, errorMessage: string, aliasError: record<code: string, message: string>, aliasFinal: string, autoAssignCustomDomains: bool, automaticAliases: list<string>, buildErrorAt: float, checksState: string, checksConclusion: string, deletedAt: float, defaultRoute: string, canceledAt: float, errorCode: string, errorLink: string, errorStep: string, passiveRegions: list<string>, gitSource: any, manualProvisioning: record<state: string, completedAt: float>, meta: record, originCacheRegion: string, nodeVersion: string, project: record<id: string, name: string, framework: string>, prebuilt: bool, readySubstate: string, regions: list<string>, softDeletedByRetention: bool, source: string, target: string, undeletedAt: float, url: string, userConfiguredDeploymentId: string, version: float, oidcTokenClaims: record<iss: string, sub: string, scope: string, aud: string, owner: string, owner_id: string, project: string, project_id: string, environment: string, custom_environment_id: string, plan: string>, projectId: string, plan: string, platform: record<source: record<name: string>, origin: record<type: string, value: string>, creator: record<name: string, avatar: string>, meta: record>, connectBuildsEnabled: bool, connectConfigurationId: string, createdIn: string, crons: table<schedule: string, path: string>, functions: record, monorepoManager: string, ownerId: string, passiveConnectConfigurationId: string, routes: list<any>, gitRepo: any, flags: any, microfrontends: any, config: record<version: float, functionType: string, functionMemoryType: string, functionTimeout: float, secureComputePrimaryRegion: string, secureComputeFallbackRegion: string, isUsingActiveCPU: bool, resourceConfig: record<buildQueue: record, elasticConcurrency: string, buildMachine: record>>, checks: record<deployment_alias: record<state: string, startedAt: float, completedAt: float>>, seatBlock: record<blockCode: string, userId: string, isVerified: bool, gitUserId: any, gitProvider: string>, attribution: record<commitMeta: record<email: string, name: string, isVerified: bool>, gitUser: record<id: any, login: string, type: string, provider: string>, vercelUser: record<id: string, username: string, teamRoles: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceNew" $forceNew "scalar") (serialize-qp "skipAutoDetectionConfirmation" $skipAutoDetectionConfirmation "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v13/deployments" $qp)
  let body = {customEnvironmentSlugOrId: $customEnvironmentSlugOrId, deploymentId: $deploymentId, files: $files, gitMetadata: $gitMetadata, gitSource: $gitSource, meta: $meta, monorepoManager: $monorepoManager, name: $name, project: $project, projectSettings: $projectSettings, target: $target, withLatestCommit: $withLatestCommit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a deployment
#
# PATCH /v12/deployments/{id}/cancel
# operationId: cancelDeployment
export def "deployments-cancel cancelDeployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<aliasAssignedAt: any, alwaysRefuseToBuild: bool, build: record<env: list<string>>, buildArtifactUrls: list<string>, builds: table<use: string, src: string, config: record>, env: list<string>, inspectorUrl: string, isInConcurrentBuildsQueue: bool, isInSystemBuildsQueue: bool, projectSettings: record<nodeVersion: string, buildCommand: string, devCommand: string, framework: string, commandForIgnoringBuildStep: string, installCommand: string, outputDirectory: string, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>>, integrations: record<status: string, startedAt: float, claimedAt: float, completedAt: float, skippedAt: float, skippedBy: string>, images: record<sizes: list<float>, qualities: list<float>, domains: list<string>, remotePatterns: list<record>, localPatterns: list<record>, minimumCacheTTL: float, formats: list<string>, dangerouslyAllowSVG: bool, contentSecurityPolicy: string, contentDispositionType: string>, alias: list<string>, aliasAssigned: bool, bootedAt: float, buildingAt: float, buildContainerFinishedAt: float, buildSkipped: bool, creator: record<uid: string, username: string, avatar: string>, initReadyAt: float, isFirstBranchDeployment: bool, lambdas: table<id: string, createdAt: float, readyState: string, entrypoint: string, readyStateAt: float, output: list>, public: bool, ready: float, status: string, team: record<id: string, name: string, slug: string, avatar: string>, userAliases: list<string>, previewCommentsEnabled: bool, ttyBuildLogs: bool, customEnvironment: any, oomReport: string, readyStateReason: string, aliasWarning: record<code: string, message: string, link: string, action: string>, id: string, createdAt: float, readyState: string, name: string, type: string, errorMessage: string, aliasError: record<code: string, message: string>, aliasFinal: string, autoAssignCustomDomains: bool, automaticAliases: list<string>, buildErrorAt: float, checksState: string, checksConclusion: string, deletedAt: float, defaultRoute: string, canceledAt: float, errorCode: string, errorLink: string, errorStep: string, passiveRegions: list<string>, gitSource: any, manualProvisioning: record<state: string, completedAt: float>, meta: record, originCacheRegion: string, nodeVersion: string, project: record<id: string, name: string, framework: string>, prebuilt: bool, readySubstate: string, regions: list<string>, softDeletedByRetention: bool, source: string, target: string, undeletedAt: float, url: string, userConfiguredDeploymentId: string, version: float, oidcTokenClaims: record<iss: string, sub: string, scope: string, aud: string, owner: string, owner_id: string, project: string, project_id: string, environment: string, custom_environment_id: string, plan: string>, projectId: string, plan: string, platform: record<source: record<name: string>, origin: record<type: string, value: string>, creator: record<name: string, avatar: string>, meta: record>, connectBuildsEnabled: bool, connectConfigurationId: string, createdIn: string, crons: table<schedule: string, path: string>, functions: record, monorepoManager: string, ownerId: string, passiveConnectConfigurationId: string, routes: list<any>, gitRepo: any, flags: any, microfrontends: any, config: record<version: float, functionType: string, functionMemoryType: string, functionTimeout: float, secureComputePrimaryRegion: string, secureComputeFallbackRegion: string, isUsingActiveCPU: bool, resourceConfig: record<buildQueue: record, elasticConcurrency: string, buildMachine: record>>, checks: record<deployment_alias: record<state: string, startedAt: float, completedAt: float>>, seatBlock: record<blockCode: string, userId: string, isVerified: bool, gitUserId: any, gitProvider: string>, attribution: record<commitMeta: record<email: string, name: string, isVerified: bool>, gitUser: record<id: any, login: string, type: string, provider: string>, vercelUser: record<id: string, username: string, teamRoles: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v12/deployments/($id)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List existing DNS records
#
# GET /v5/domains/{domain}/records
# operationId: getRecords
export def "domains-records get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Maximum number of records to list from a request. (e.g. 20)
  --since: string # Get records created after this JavaScript timestamp. (e.g. 1609499532000)
  --until: string # Get records created before this JavaScript timestamp. (e.g. 1612264332000)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v5/domains/($domain)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DNS record
#
# POST /v2/domains/{domain}/records
# operationId: createRecord
# --srv shape: {priority: any, weight: any, port: any, target: string}
# --https shape: {priority: any, target: string, params?: string}
export def "domains-records createRecord" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  type: string@type-completer # The type of record, it could be one of the valid DNS records.
  --name: string # A subdomain name or an empty string for the root domain. (e.g. subdomain)
  --ttl: float # The TTL value. Must be a number between 60 and 2147483647. Default value is 60. (e.g. 60)
  --value: string # The record value must be a valid IPv4 address. (format: ipv4, e.g. 192.0.2.42)
  --comment: string # A comment to add context on what this DNS record is for (e.g. used to verify ownership of domain)
  --mxPriority: float # e.g. 10
  --srv: record # shape: {priority: any, weight: any, port: any, target: string}
  --https: record # shape: {priority: any, target: string, params?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/domains/($domain)/records" $qp)
  let body = {type: $type, name: $name, ttl: $ttl, value: $value, comment: $comment, mxPriority: $mxPriority, srv: $srv, https: $https} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing DNS record
#
# PATCH /v1/domains/records/{recordId}
# operationId: updateRecord
# --srv shape: {target: string, weight: int, port: int, priority: int}
# --https shape: {priority: int, target: string, params?: string}
export def "domains-records updateRecord" [
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string # The name of the DNS record (nullable, e.g. example-1)
  --value: string # The value of the DNS record (nullable, e.g. google.com)
  --type: string@type-completer-1 # The type of the DNS record (nullable, e.g. A)
  --ttl: int # The Time to live (TTL) value of the DNS record (nullable, e.g. 60)
  --mxPriority: int # The MX priority value of the DNS record (nullable)
  --srv: record # nullable — shape: {target: string, weight: int, port: int, priority: int}
  --https: record # nullable — shape: {priority: int, target: string, params?: string}
  --comment: string # A comment to add context on what this DNS record is for (e.g. used to verify ownership of domain)
]: any -> record<id: string, name: string, type: string, value: string, creator: string, domain: string, ttl: float, comment: string, recordType: string, createdAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/domains/records/($recordId)" $qp)
  let body = {name: $name, value: $value, type: $type, ttl: $ttl, mxPriority: $mxPriority, srv: $srv, https: $https, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a DNS record
#
# DELETE /v2/domains/{domain}/records/{recordId}
# operationId: removeRecord
export def "domains-records removeRecord" [
  domain: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/domains/($domain)/records/($recordId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get supported TLDs
#
# GET /v1/registrar/tlds/supported
# operationId: getSupportedTlds
export def "registrar-tlds-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/registrar/tlds/supported" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get TLD
#
# GET /v1/registrar/tlds/{tld}
# operationId: getTld
export def "registrar-tlds get" [
  tld: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<supportedLanguageCodes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/tlds/($tld)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get TLD price data
#
# GET /v1/registrar/tlds/{tld}/price
# operationId: getTldPrice
export def "registrar-tlds-price get" [
  tld: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --years: string # The number of years to get the price for. If not provided, the minimum number of years for the TLD will be used.
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<years: float, purchasePrice: any, renewalPrice: any, transferPrice: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "years" $years "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/tlds/($tld)/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get availability for a domain
#
# GET /v1/registrar/domains/{domain}/availability
# operationId: getDomainAvailability
export def "registrar-domains-availability get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/availability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get price data for a domain
#
# GET /v1/registrar/domains/{domain}/price
# operationId: getDomainPrice
export def "registrar-domains-price get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --years: string # The number of years to get the price for. If not provided, the minimum number of years for the TLD will be used.
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<years: float, purchasePrice: any, renewalPrice: any, transferPrice: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "years" $years "scalar") (serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get availability for multiple domains
#
# POST /v1/registrar/domains/availability
# operationId: getBulkAvailability
export def "registrar-domains-availability post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  domains: list # an array of at most 50 item(s)
]: any -> record<results: table<domain: string, available: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/registrar/domains/availability" $qp)
  let body = {domains: $domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the auth code for a domain
#
# GET /v1/registrar/domains/{domain}/auth-code
# operationId: getDomainAuthCode
export def "registrar-domains-auth-code get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<authCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/auth-code" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Buy a domain
#
# POST /v1/registrar/domains/{domain}/buy
# operationId: buySingleDomain
# --contactInformation shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string, additional?: record}
export def "registrar-domains-buy buySingleDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  --autoRenew: string@bool-completer # Whether the domain should be auto-renewed before it expires. This can be configured later through the Vercel Dashboard or the [Update auto-renew for a domain](https://vercel.com/docs/rest-api/reference/endpoints/domains-registrar/update-auto-renew-for-a-domain) endpoint.
  years: float # The number of years to purchase the domain for.
  expectedPrice: float
  contactInformation: record # The contact information for the domain. Some TLDs require additional contact information. Use the [Get contact info schema](https://vercel.com/docs/rest-api/reference/endpoints/domains-registrar/get-contact-info-schema) endpoint to retrieve the required fields. — shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string, additional?: record}
  --languageCode: string # The language code for the domain. For punycode domains, this must be provided. The list of supported language codes for a TLD can be retrieved from the [Get TLD](https://vercel.com/docs/rest-api/reference/endpoints/domains-registrar/get-tld) endpoint.
]: any -> record<orderId: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/buy" $qp)
  let body = {autoRenew: $autoRenew, years: $years, expectedPrice: $expectedPrice, contactInformation: $contactInformation, languageCode: $languageCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Buy multiple domains
#
# POST /v1/registrar/domains/buy
# operationId: buyDomains
# --domains item shape: {domainName: string, autoRenew: bool, years: float, expectedPrice: float, languageCode?: string}
# --contactInformation shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string, additional?: record}
export def "registrar-domains-buy buyDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  domains: list # item shape: {domainName: string, autoRenew: bool, years: float, expectedPrice: float, languageCode?: string}
  contactInformation: record # The contact information for the domain. Some TLDs require additional contact information. Use the [Get contact info schema](https://vercel.com/docs/rest-api/reference/endpoints/domains-registrar/get-contact-info-schema) endpoint to retrieve the required fields. — shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string, additional?: record}
]: any -> record<orderId: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/registrar/domains/buy" $qp)
  let body = {domains: $domains, contactInformation: $contactInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer-in a domain
#
# POST /v1/registrar/domains/{domain}/transfer
# operationId: transferInDomain
# --contactInformation shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string}
export def "registrar-domains-transfer transferInDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  authCode: string # The auth code for the domain. You must obtain this code from the losing registrar.
  --autoRenew: string@bool-completer # Whether the domain should be auto-renewed before it expires. This can be configured later through the Vercel Dashboard or the [Update auto-renew for a domain](https://vercel.com/docs/rest-api/reference/endpoints/domains-registrar/update-auto-renew-for-a-domain) endpoint.
  years: float # The number of years to renew the domain for once it is transferred in. This must be a valid number of transfer years for the TLD.
  expectedPrice: float
  contactInformation: record # shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string}
]: any -> record<orderId: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/transfer" $qp)
  let body = {authCode: $authCode, autoRenew: $autoRenew, years: $years, expectedPrice: $expectedPrice, contactInformation: $contactInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a domain's transfer status
#
# GET /v1/registrar/domains/{domain}/transfer
# operationId: getDomainTransferIn
export def "registrar-domains-transfer get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renew a domain
#
# POST /v1/registrar/domains/{domain}/renew
# operationId: renewDomain
# --contactInformation shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string}
export def "registrar-domains-renew renewDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  years: float # The number of years to renew the domain for.
  expectedPrice: float
  --contactInformation: record # shape: {firstName: string, lastName: string, email: string, phone: string, address1: string, address2?: string, city: string, state: string, zip: string, country: string, companyName?: string, fax?: string}
]: any -> record<orderId: string, _links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/renew" $qp)
  let body = {years: $years, expectedPrice: $expectedPrice, contactInformation: $contactInformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update auto-renew for a domain
#
# PATCH /v1/registrar/domains/{domain}/auto-renew
# operationId: updateDomainAutoRenew
export def "registrar-domains-auto-renew updateDomainAutoRenew" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  --autoRenew: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/auto-renew" $qp)
  let body = {autoRenew: $autoRenew} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update nameservers for a domain
#
# PATCH /v1/registrar/domains/{domain}/nameservers
# operationId: updateDomainNameservers
export def "registrar-domains-nameservers updateDomainNameservers" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
  nameservers: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/nameservers" $qp)
  let body = {nameservers: $nameservers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get contact info schema
#
# GET /v1/registrar/domains/{domain}/contact-info/schema
# operationId: getContactInfoSchema
export def "registrar-domains-contact-info-schema get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/domains/($domain)/contact-info/schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a domain order
#
# GET /v1/registrar/orders/{orderId}
# operationId: getOrder
export def "registrar-orders get" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l
]: nothing -> record<orderId: string, domains: list<any>, status: string, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/registrar/orders/($orderId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Domain's configuration
#
# GET /v6/domains/{domain}/config
# operationId: getDomainConfig
export def "domains-config get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectIdOrName: string # The project id or name that will be associated with the domain. Use this when the domain is not yet associated with a project.
  --strict: string@strict-completer # When true, the response will only include the nameservers assigned directly to the specified domain. When false and there are no nameservers assigned directly to the specified domain, the response will include the nameservers of the domain's parent zone.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<configuredBy: string, acceptedChallenges: list<string>, recommendedIPv4: table<rank: float, value: list>, recommendedCNAME: table<rank: float, value: string>, misconfigured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectIdOrName" $projectIdOrName "scalar") (serialize-qp "strict" $strict "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/domains/($domain)/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Domain Verification Record
#
# GET /v9/domains/{domain}/verification
# operationId: getDomainVerificationRecord
export def "domains-verification get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<txtRecord: string, verificationDomain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/domains/($domain)/verification" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Claim Domain Ownership
#
# POST /v9/domains/{domain}/claim
# operationId: claimDomainOwnership
export def "domains-claim claimDomainOwnership" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<domain: record<expiresAt: float, verified: bool, nameservers: list<string>, intendedNameservers: list<string>, customNameservers: list<string>, creator: record<username: string, email: string, customerId: string, isDomainReseller: bool, id: string>, name: string, teamId: string, boughtAt: float, createdAt: float, id: string, renew: bool, serviceType: string, transferredAt: float, transferStartedAt: float, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/domains/($domain)/claim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Information for a Single Domain
#
# GET /v5/domains/{domain}
# operationId: getDomain
export def "domains get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<domain: record<suffix: bool, expiresAt: float, verified: bool, nameservers: list<string>, intendedNameservers: list<string>, customNameservers: list<string>, creator: record<username: string, email: string, customerId: string, isDomainReseller: bool, id: string>, name: string, teamId: string, boughtAt: float, createdAt: float, id: string, renew: bool, serviceType: string, transferredAt: float, transferStartedAt: float, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v5/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all the domains
#
# GET /v5/domains
# operationId: getDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of domains to list from a request. (e.g. 20)
  --since: float # Get domains created after this JavaScript timestamp. (e.g. 1609499532000)
  --until: float # Get domains created before this JavaScript timestamp. (e.g. 1612264332000)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<domains: table<expiresAt: float, verified: bool, nameservers: list, intendedNameservers: list, customNameservers: list, creator: record, name: string, teamId: string, boughtAt: float, createdAt: float, id: string, renew: bool, serviceType: string, transferredAt: float, transferStartedAt: float, userId: string>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v5/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an existing domain to the Vercel platform
#
# POST /v7/domains
# operationId: createOrTransferDomain
export def "domains createOrTransferDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --method: string # The domain operation to perform. It can be either `add` or `move-in`. (e.g. add)
  --name: string # The domain name you want to add. (e.g. example.com)
  --cdnEnabled: string@bool-completer # Whether the domain has the Vercel Edge Network enabled or not. (e.g. true)
  --zone: string@bool-completer # Whether to create a DNS zone on Vercel. Set `true` if using Vercel nameservers.
  --body-token: string # The move-in token from Move Requested email. (e.g. fdhfr820ad#@FAdlj$$)
]: any -> record<domain: record<expiresAt: float, verified: bool, nameservers: list<string>, intendedNameservers: list<string>, customNameservers: list<string>, creator: record<username: string, email: string, customerId: string, isDomainReseller: bool, id: string>, name: string, teamId: string, boughtAt: float, createdAt: float, id: string, renew: bool, serviceType: string, transferredAt: float, transferStartedAt: float, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v7/domains" $qp)
  let body = {method: $method, name: $name, cdnEnabled: $cdnEnabled, zone: $zone, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update or move apex domain
#
# PATCH /v3/domains/{domain}
# operationId: patchDomain
@deprecated --flag renew
@deprecated --flag customNameservers
export def "domains patch" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --op: string # e.g. update
  --renew: string@bool-completer # This field is deprecated. Please use PATCH /v1/registrar/domains/{domainName}/auto-renew instead. (DEPRECATED)
  --customNameservers: list # This field is deprecated. Please use PATCH /v1/registrar/domains/{domainName}/nameservers instead. (DEPRECATED)
  --zone: string@bool-completer # Specifies whether this is a DNS zone that intends to use Vercel's nameservers.
  --destination: string # User or team to move domain to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/domains/($domain)" $qp)
  let body = {op: $op, renew: $renew, customNameservers: $customNameservers, zone: $zone, destination: $destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a domain by name
#
# DELETE /v6/domains/{domain}
# operationId: deleteDomain
export def "domains delete" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a Configurable Log Drain (deprecated)
#
# GET /v1/log-drains/{id}
# operationId: getConfigurableLogDrain
export def "log-drains get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<createdFrom: string, clientId: string, configurationId: string, projectsMetadata: table<id: string, name: string, framework: string, latestDeployment: string>, integrationIcon: string, integrationConfigurationUri: string, integrationWebsite: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/log-drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a Configurable Log Drain (deprecated)
#
# DELETE /v1/log-drains/{id}
# operationId: deleteConfigurableLogDrain
export def "log-drains delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/log-drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of all the Log Drains (deprecated)
#
# GET /v1/log-drains
# operationId: getAllLogDrains
export def "log-drains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --projectIdOrName: string
  --includeMetadata: string@bool-completer # default: false
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "projectIdOrName" $projectIdOrName "scalar") (serialize-qp "includeMetadata" $includeMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/log-drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Configurable Log Drain (deprecated)
#
# POST /v1/log-drains
# operationId: createConfigurableLogDrain
export def "log-drains createConfigurableLogDrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  deliveryFormat: any@deliveryFormat-completer # The delivery log format (e.g. json)
  --body-url: string # The log drain url (format: uri)
  --headers: record # Headers to be sent together with the request
  --projectIds: list
  sources: list
  --environments: list
  --secret: string # Custom secret of log drain
  --samplingRate: float # The sampling rate for this log drain. It should be a percentage rate between 0 and 100. With max 2 decimal points
  --name: string # The custom name of this log drain.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/log-drains" $qp)
  let body = {deliveryFormat: $deliveryFormat, url: $body_url, headers: $headers, projectIds: $projectIds, sources: $sources, environments: $environments, secret: $secret, samplingRate: $samplingRate, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Drain
#
# POST /v1/drains
# operationId: createDrain
# --filter shape: {version: string, filter: any}
# --delivery shape: {type?: string, endpoint?: string, compression?: "gzip"|"none", encoding?: "json"|"ndjson", headers?: record, secret?: string}
# --sampling item shape: {type: string, rate: float, env?: "production"|"preview", requestPath?: string}
# --transforms item shape: {id: string}
# --source shape: {kind?: string}
export def "drains createDrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string
  projects: string@projects-completer
  --projectIds: list
  --filter: record # shape: {version: string, filter: any}
  schemas: record
  --delivery: record # shape: {type?: string, endpoint?: string, compression?: "gzip"|"none", encoding?: "json"|"ndjson", headers?: record, secret?: string}
  --sampling: list # item shape: {type: string, rate: float, env?: "production"|"preview", requestPath?: string}
  --transforms: list # item shape: {id: string}
  --body-source: record # shape: {kind?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/drains" $qp)
  let body = {name: $name, projects: $projects, projectIds: $projectIds, filter: $filter, schemas: $schemas, delivery: $delivery, sampling: $sampling, transforms: $transforms, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of all Drains
#
# GET /v1/drains
# operationId: getDrains
export def "drains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --includeMetadata: string@bool-completer # default: false
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<drains: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "includeMetadata" $includeMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a drain
#
# DELETE /v1/drains/{id}
# operationId: deleteDrain
export def "drains delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find a Drain by id
#
# GET /v1/drains/{id}
# operationId: getDrain
export def "drains get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing Drain
#
# PATCH /v1/drains/{id}
# operationId: updateDrain
# --delivery shape: {type?: string, endpoint?: string, compression?: "gzip"|"none", encoding?: "json"|"ndjson", headers?: record, secret?: string}
# --sampling item shape: {type: string, rate: float, env?: "production"|"preview", requestPath?: string}
# --transforms item shape: {id: string}
# --source shape: {kind?: string}
export def "drains updateDrain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string
  --projects: string@projects-completer
  --projectIds: list # nullable
  --filter: any
  --schemas: record
  --delivery: record # shape: {type?: string, endpoint?: string, compression?: "gzip"|"none", encoding?: "json"|"ndjson", headers?: record, secret?: string}
  --sampling: list # nullable — item shape: {type: string, rate: float, env?: "production"|"preview", requestPath?: string}
  --transforms: list # nullable — item shape: {id: string}
  --status: string@status-completer-3
  --body-source: record # shape: {kind?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/drains/($id)" $qp)
  let body = {name: $name, projects: $projects, projectIds: $projectIds, filter: $filter, schemas: $schemas, delivery: $delivery, sampling: $sampling, transforms: $transforms, status: $status, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Drain delivery configuration
#
# POST /v1/drains/test
# operationId: testDrain
# --delivery shape: {type?: string, endpoint?: string, compression?: "gzip"|"none", encoding?: "json"|"ndjson", headers?: record, secret?: string}
export def "drains-test testDrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  schemas: record
  delivery: record # shape: {type?: string, endpoint?: string, compression?: "gzip"|"none", encoding?: "json"|"ndjson", headers?: record, secret?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/drains/test" $qp)
  let body = {schemas: $schemas, delivery: $delivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invalidate by tag
#
# POST /v1/edge-cache/invalidate-by-tags
# operationId: invalidateByTags
export def "edge-cache-invalidate-by-tags invalidateByTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectIdOrName: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  tags: any
  --target: string@target-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectIdOrName" $projectIdOrName "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/edge-cache/invalidate-by-tags" $qp)
  let body = {tags: $tags, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dangerously delete by tag
#
# POST /v1/edge-cache/dangerously-delete-by-tags
# operationId: dangerouslyDeleteByTags
export def "edge-cache-dangerously-delete-by-tags dangerouslyDeleteByTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectIdOrName: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --revalidationDeadlineSeconds: float
  tags: any
  --target: string@target-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectIdOrName" $projectIdOrName "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/edge-cache/dangerously-delete-by-tags" $qp)
  let body = {revalidationDeadlineSeconds: $revalidationDeadlineSeconds, tags: $tags, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invalidate by source image
#
# POST /v1/edge-cache/invalidate-by-src-images
# operationId: invalidateBySrcImages
export def "edge-cache-invalidate-by-src-images invalidateBySrcImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectIdOrName: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  srcImages: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectIdOrName" $projectIdOrName "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/edge-cache/invalidate-by-src-images" $qp)
  let body = {srcImages: $srcImages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dangerously delete by source image
#
# POST /v1/edge-cache/dangerously-delete-by-src-images
# operationId: dangerouslyDeleteBySrcImages
export def "edge-cache-dangerously-delete-by-src-images dangerouslyDeleteBySrcImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectIdOrName: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --revalidationDeadlineSeconds: float
  srcImages: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectIdOrName" $projectIdOrName "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/edge-cache/dangerously-delete-by-src-images" $qp)
  let body = {revalidationDeadlineSeconds: $revalidationDeadlineSeconds, srcImages: $srcImages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Edge Configs
#
# GET /v1/edge-config
# operationId: getEdgeConfigs
export def "edge-config list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> table<id: string, createdAt: float, ownerId: string, slug: string, updatedAt: float, digest: string, transfer: record<fromAccountId: string, startedAt: float, doneAt: float>, schema: record, purpose: record<type: string, projectId: string>, sizeInBytes: float, itemCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/edge-config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Edge Config
#
# POST /v1/edge-config
# operationId: createEdgeConfig
export def "edge-config createEdgeConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  slug: string
  --items: record
]: any -> record<id: string, createdAt: float, createdBy: string, ownerId: string, slug: string, updatedAt: float, digest: string, purpose: any, deletedAt: float, transfer: record<fromAccountId: string, startedAt: float, doneAt: float>, schema: record, syncedToDynamoAt: float, sizeInBytes: float, itemCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/edge-config" $qp)
  let body = {slug: $slug, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Edge Config
#
# GET /v1/edge-config/{edgeConfigId}
# operationId: getEdgeConfig
export def "edge-config get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string, createdAt: float, createdBy: string, ownerId: string, slug: string, updatedAt: float, digest: string, purpose: any, deletedAt: float, transfer: record<fromAccountId: string, startedAt: float, doneAt: float>, schema: record, syncedToDynamoAt: float, sizeInBytes: float, itemCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Edge Config
#
# PUT /v1/edge-config/{edgeConfigId}
# operationId: updateEdgeConfig
export def "edge-config updateEdgeConfig" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  slug: string
]: any -> record<id: string, createdAt: float, createdBy: string, ownerId: string, slug: string, updatedAt: float, digest: string, purpose: any, deletedAt: float, transfer: record<fromAccountId: string, startedAt: float, doneAt: float>, schema: record, syncedToDynamoAt: float, sizeInBytes: float, itemCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)" $qp)
  let body = {slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Edge Config
#
# DELETE /v1/edge-config/{edgeConfigId}
# operationId: deleteEdgeConfig
export def "edge-config delete" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Edge Config items
#
# GET /v1/edge-config/{edgeConfigId}/items
# operationId: getEdgeConfigItems
export def "edge-config-items get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> table<key: string, value: any, description: string, edgeConfigId: string, createdAt: float, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Edge Config items in batch
#
# PATCH /v1/edge-config/{edgeConfigId}/items
# operationId: patchEdgeConfigItems
export def "edge-config-items patch" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  items: list
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/items" $qp)
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Edge Config schema
#
# GET /v1/edge-config/{edgeConfigId}/schema
# operationId: getEdgeConfigSchema
export def "edge-config-schema get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Edge Config schema
#
# POST /v1/edge-config/{edgeConfigId}/schema
# operationId: patchEdgeConfigSchema
export def "edge-config-schema post" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dryRun: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  definition: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dryRun" $dryRun "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/schema" $qp)
  let body = {definition: $definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Edge Config's schema
#
# DELETE /v1/edge-config/{edgeConfigId}/schema
# operationId: deleteEdgeConfigSchema
export def "edge-config-schema delete" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Edge Config item
#
# GET /v1/edge-config/{edgeConfigId}/item/{edgeConfigItemKey}
# operationId: getEdgeConfigItem
export def "edge-config-item get" [
  edgeConfigId: string
  edgeConfigItemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<key: string, value: any, description: string, edgeConfigId: string, createdAt: float, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/item/($edgeConfigItemKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all tokens of an Edge Config
#
# GET /v1/edge-config/{edgeConfigId}/tokens
# operationId: getEdgeConfigTokens
export def "edge-config-tokens get" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<partialToken: string, label: string, id: string, edgeConfigId: string, createdAt: float, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete one or more Edge Config tokens
#
# DELETE /v1/edge-config/{edgeConfigId}/tokens
# operationId: deleteEdgeConfigTokens
export def "edge-config-tokens delete" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --tokens: list
  --ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/tokens" $qp)
  let body = {tokens: $tokens, ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Edge Config token meta data
#
# GET /v1/edge-config/{edgeConfigId}/token/{token}
# operationId: getEdgeConfigToken
export def "edge-config-token get" [
  edgeConfigId: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<partialToken: string, label: string, id: string, edgeConfigId: string, createdAt: float, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/token/($token)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Edge Config token
#
# POST /v1/edge-config/{edgeConfigId}/token
# operationId: createEdgeConfigToken
export def "edge-config-token createEdgeConfigToken" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  label: string
]: any -> record<token: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/token" $qp)
  let body = {label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Edge Config backup
#
# GET /v1/edge-config/{edgeConfigId}/backups/{edgeConfigBackupVersionId}
# operationId: getEdgeConfigBackup
export def "edge-config-backups get" [
  edgeConfigId: string
  edgeConfigBackupVersionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/backups/($edgeConfigBackupVersionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Edge Config backups
#
# GET /v1/edge-config/{edgeConfigId}/backups
# operationId: getEdgeConfigBackups
export def "edge-config-backups list" [
  edgeConfigId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --next: string
  --limit: float
  --metadata: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<backups: table<metadata: record, id: string, lastModified: float>, pagination: record<hasNext: bool, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next" $next "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/edge-config/($edgeConfigId)/backups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create one or more shared environment variables
#
# POST /v1/env
# operationId: createSharedEnvVariable
# --evs item shape: {key: string, value: string, comment?: string}
@deprecated --flag projectId
export def "env createSharedEnvVariable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  evs: list # item shape: {key: string, value: string, comment?: string}
  --type: string@type-completer-2 # The type of environment variable (e.g. encrypted)
  --target: list # The target environment of the Shared Environment Variable (e.g. [production, preview])
  --projectId: list # Associate a Shared Environment Variable to projects. (DEPRECATED, e.g. [prj_2WjyKQmM8ZnGcJsPWMrHRHrE, prj_2WjyKQmM8ZnGcJsPWMrHRCRV])
]: any -> record<created: table<created: string, key: string, ownerId: string, id: string, createdBy: string, deletedBy: string, updatedBy: string, createdAt: float, deletedAt: float, updatedAt: float, value: string, projectId: list, type: string, target: list, applyToAllCustomEnvironments: bool, customEnvironmentIds: list, decrypted: bool, comment: string, lastEditedByDisplayName: string>, failed: table<error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/env" $qp)
  let body = {evs: $evs, type: $type, target: $target, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all Shared Environment Variables for a team
#
# GET /v1/env
# operationId: listSharedEnvVariable
export def "env listSharedEnvVariable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --projectId: string # Filter SharedEnvVariables that belong to a project (e.g. prj_2WjyKQmM8ZnGcJsPWMrHRHrE)
  --ids: string # Filter SharedEnvVariables based on comma separated ids (e.g. env_2WjyKQmM8ZnGcJsPWMrHRHrE,env_2WjyKQmM8ZnGcJsPWMrHRCRV)
  --exclude-ids: string # Filter SharedEnvVariables based on comma separated ids (e.g. env_2WjyKQmM8ZnGcJsPWMrHRHrE,env_2WjyKQmM8ZnGcJsPWMrHRCRV)
  --exclude-ids: string # Filter SharedEnvVariables based on comma separated ids (e.g. env_2WjyKQmM8ZnGcJsPWMrHRHrE,env_2WjyKQmM8ZnGcJsPWMrHRCRV)
  --exclude-projectId: string # Filter SharedEnvVariables that belong to a project (e.g. prj_2WjyKQmM8ZnGcJsPWMrHRHrE)
  --exclude-projectId: string # Filter SharedEnvVariables that belong to a project (e.g. prj_2WjyKQmM8ZnGcJsPWMrHRHrE)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<data: table<created: string, key: string, ownerId: string, id: string, createdBy: string, deletedBy: string, updatedBy: string, createdAt: float, deletedAt: float, updatedAt: float, value: string, projectId: list, type: string, target: list, applyToAllCustomEnvironments: bool, customEnvironmentIds: list, decrypted: bool, comment: string, lastEditedByDisplayName: string>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "exclude_ids" $exclude_ids "scalar") (serialize-qp "'exclude-ids'" $exclude_ids "scalar") (serialize-qp "exclude_projectId" $exclude_projectId "scalar") (serialize-qp "'exclude-projectId'" $exclude_projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/env" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates one or more shared environment variables
#
# PATCH /v1/env
# operationId: updateSharedEnvVariable
export def "env updateSharedEnvVariable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  updates: record # An object where each key is an environment variable ID (not the key name) and the value is the update to apply (e.g. {env_2WjyKQmM8ZnGcJsPWMrHRHrE: {key: API_URL, value: https://api.vercel.com, target: [production, preview], projectIdUpdates: {link: [prj_2WjyKQmM8ZnGcJsPWMrHRHrE]}}})
]: any -> record<updated: table<created: string, key: string, ownerId: string, id: string, createdBy: string, deletedBy: string, updatedBy: string, createdAt: float, deletedAt: float, updatedAt: float, value: string, projectId: list, type: string, target: list, applyToAllCustomEnvironments: bool, customEnvironmentIds: list, decrypted: bool, comment: string, lastEditedByDisplayName: string>, failed: table<error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/env" $qp)
  let body = {updates: $updates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete one or more Env Var
#
# DELETE /v1/env
# operationId: deleteSharedEnvVariable
export def "env delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  ids: list # IDs of the Shared Environment Variables to delete (e.g. [env_abc123, env_abc124])
]: any -> record<deleted: list<string>, failed: table<error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/env" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the decrypted value of a Shared Environment Variable by id.
#
# GET /v1/env/{id}
# operationId: getSharedEnvVar
export def "env get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<created: string, key: string, ownerId: string, id: string, createdBy: string, deletedBy: string, updatedBy: string, createdAt: float, deletedAt: float, updatedAt: float, value: string, projectId: list<string>, type: string, target: list<string>, applyToAllCustomEnvironments: bool, customEnvironmentIds: list<string>, decrypted: bool, comment: string, lastEditedByDisplayName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/env/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disconnects a shared environment variable for a given project
#
# PATCH /v1/env/{id}/unlink/{projectId}
# operationId: unlinkSharedEnvVariable
export def "env-unlink unlinkSharedEnvVariable" [
  id: string
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/env/($id)/unlink/($projectId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Events
#
# GET /v3/events
# operationId: listUserEvents
export def "events listUserEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of items which may be returned. (e.g. 20)
  --since: string # Timestamp to only include items created since then. (e.g. 2019-12-08T10:00:38.976Z)
  --until: string # Timestamp to only include items created until then. (e.g. 2019-12-09T23:00:38.976Z)
  --types: string # Comma-delimited list of event "types" to filter the results by. (e.g. login,team-member-join,domain-buy)
  --userId: string # Deprecated. Use `principalId` instead. If `principalId` and `userId` both exist, `principalId` will be used. (e.g. aeIInYVk59zbFF2SxfyxxmuO)
  --principalId: string # When retrieving events for a Team, the `principalId` parameter may be specified to filter events generated by a specific principal. (e.g. aeIInYVk59zbFF2SxfyxxmuO)
  --projectIds: string # Comma-delimited list of project IDs to filter the results by. (e.g. aeIInYVk59zbFF2SxfyxxmuO)
  --withPayload: string # When set to `true`, the response will include the `payload` field for each event. (e.g. true)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<events: table<id: string, text: string, entities: list, type: string, categories: list, createdAt: float, user: record, principal: any, via: list, userId: string, principalId: string, viaIds: list, payload: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "principalId" $principalId "scalar") (serialize-qp "projectIds" $projectIds "scalar") (serialize-qp "withPayload" $withPayload "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Event Types
#
# GET /v1/events/types
# operationId: listEventTypes
export def "events-types listEventTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<types: table<name: string, description: string, categories: list, deprecated: bool, replacedBy: list>, categories: table<name: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/events/types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List flags
#
# GET /v2/projects/{projectIdOrName}/feature-flags/flags
# operationId: listFlagsV2
export def "projects-feature-flags-flags listFlagsV2" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # The state of the flags to retrieve. Defaults to `active`.
  --limit: int # Maximum number of flags to return. (default: 25)
  --cursor: string # Pagination cursor to continue from.
  --search: string # Search flags by their slug or description. Case-insensitive.
  --tags: list # Filter flags by tag. Repeat the parameter for multiple tags (all must match).
  --includeMarketplaceFlags: string@bool-completer # Whether to include Marketplace experimentation items in the paginated response. Defaults to false.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<pagination: record<next: string>, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "includeMarketplaceFlags" $includeMarketplaceFlags "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($projectIdOrName)/feature-flags/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List flags
#
# GET /v1/projects/{projectIdOrName}/feature-flags/flags
# operationId: listFlags
export def "projects-feature-flags-flags listFlags" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # The state of the flags to retrieve. Defaults to `active`.
  --withMetadata: string@bool-completer # Deprecated. Whether to include creator metadata in each flag in the response. Resolve creator identity client-side (e.g. via the team members endpoint) instead; this parameter will be removed in a future release. Use `GET /v1/projects/:id/feature-flags/flags/:flagIdOrSlug?withMetadata=true` for single-flag lookups that need creator metadata.
  --limit: int # Maximum number of flags to return. When not set, all flags are returned.
  --cursor: string # Pagination cursor to continue from.
  --search: string # Search flags by their slug or description. Case-insensitive.
  --tags: list # Filter flags by tag. Repeat the parameter for multiple tags (all must match).
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<data: table<description: string, maintainerIds: list, permanent: bool, tags: list, experiment: record, variants: list, id: string, environments: record, kind: string, revision: float, seed: float, state: string, slug: string, createdAt: float, updatedAt: float, createdBy: string, ownerId: string, projectId: string, typeName: string, metadata: record>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a flag
#
# PUT /v1/projects/{projectIdOrName}/feature-flags/flags
# operationId: createFlag
# --variants item shape: {id: string, label?: string, description?: string, value: any}
export def "projects-feature-flags-flags createFlag" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  slug: string # A unique (per project) key for the flag, composed of letters, numbers, dashes, and underscores
  kind: any@kind-completer # The kind of flag
  --variants: list # The variants of the flag — item shape: {id: string, label?: string, description?: string, value: any}
  environments: record # The configuration for the flag in different environments
  --seed: float # A random seed to prevent split points in different flags from having the same targets
  --description: string # A description of the flag
  --state: string@state-completer
  --maintainerIds: list # The user ids of the maintainers of the flag
  --permanent: string@bool-completer # Whether this flag is marked as permanent, indicating it should not be removed
  --tags: list # Tags for categorizing the flag
]: any -> record<description: string, maintainerIds: list<string>, permanent: bool, tags: list<string>, experiment: record<id: string, name: string, numVariants: float, surfaceArea: string, stickyRequirement: bool, layer: string, guardrailMetrics: list<record>, hypothesis: string, device: string, controlVariantId: string, startedAt: float, endedAt: float, decision: string, decisionReason: string, duration: float, durationUnit: string, allocationPercent: float, allocationUnit: string, primaryMetrics: list<record>, status: string>, variants: list<record>, id: string, environments: record, kind: string, revision: float, seed: float, state: string, slug: string, createdAt: float, updatedAt: float, createdBy: string, ownerId: string, projectId: string, typeName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/flags" $qp)
  let body = {slug: $slug, kind: $kind, variants: $variants, environments: $environments, seed: $seed, description: $description, state: $state, maintainerIds: $maintainerIds, permanent: $permanent, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a flag
#
# GET /v1/projects/{projectIdOrName}/feature-flags/flags/{flagIdOrSlug}
# operationId: getFlag
export def "projects-feature-flags-flags get" [
  projectIdOrName: string
  flagIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ifMatch: string # Etag to match, can be used interchangeably with the `if-match` header
  --withMetadata: string@bool-completer # Whether to include metadata in the response
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<description: string, maintainerIds: list<string>, permanent: bool, tags: list<string>, experiment: record<id: string, name: string, numVariants: float, surfaceArea: string, stickyRequirement: bool, layer: string, guardrailMetrics: list<record>, hypothesis: string, device: string, controlVariantId: string, startedAt: float, endedAt: float, decision: string, decisionReason: string, duration: float, durationUnit: string, allocationPercent: float, allocationUnit: string, primaryMetrics: list<record>, status: string>, variants: list<record>, id: string, environments: record, kind: string, revision: float, seed: float, state: string, slug: string, createdAt: float, updatedAt: float, createdBy: string, ownerId: string, projectId: string, typeName: string, metadata: record<creator: record<id: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ifMatch" $ifMatch "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/flags/($flagIdOrSlug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a flag
#
# PATCH /v1/projects/{projectIdOrName}/feature-flags/flags/{flagIdOrSlug}
# operationId: updateFlag
# --variants item shape: {id: string, label?: string, description?: string, value: any}
export def "projects-feature-flags-flags updateFlag" [
  projectIdOrName: string
  flagIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ifMatch: string # Etag to match, can be used interchangeably with the `if-match` header
  --withMetadata: string@bool-completer # Whether to include metadata in the response
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --createdBy: string # The user who created this patch
  --message: string # Additional message for this version
  --variants: list # The variants of the flag — item shape: {id: string, label?: string, description?: string, value: any}
  --environments: record # The configuration for the flag in different environments
  --seed: float # A random seed to prevent split points in different flags from having the same targets
  --description: string # A description of the flag
  --state: string@state-completer
  --maintainerIds: list # The user ids of the maintainers of the flag
  --permanent: string@bool-completer # Whether this flag is marked as permanent, indicating it should not be removed
  --tags: list # Tags for categorizing the flag
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ifMatch" $ifMatch "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/flags/($flagIdOrSlug)" $qp)
  let body = {createdBy: $createdBy, message: $message, variants: $variants, environments: $environments, seed: $seed, description: $description, state: $state, maintainerIds: $maintainerIds, permanent: $permanent, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a flag
#
# DELETE /v1/projects/{projectIdOrName}/feature-flags/flags/{flagIdOrSlug}
# operationId: deleteFlag
export def "projects-feature-flags-flags delete" [
  projectIdOrName: string
  flagIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ifMatch: string # Etag to match, can be used interchangeably with the `if-match` header
  --withMetadata: string@bool-completer # Whether to include metadata in the response
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ifMatch" $ifMatch "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/flags/($flagIdOrSlug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List flag versions
#
# GET /v1/projects/{projectIdOrName}/feature-flags/flags/{flagIdOrSlug}/versions
# operationId: listFlagVersions
export def "projects-feature-flags-flags-versions listFlagVersions" [
  projectIdOrName: string
  flagIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # default: 20
  --cursor: string # Pagination cursor
  --environment: string # Environment to filter by
  --withMetadata: string@bool-completer # Whether to include metadata (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<versions: table<createdBy: string, message: string, data: record, id: string, revision: float, createdAt: float, flagId: string, changedEnvironments: list, metadata: record>, pagination: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/flags/($flagIdOrSlug)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project flag settings
#
# GET /v1/projects/{projectIdOrName}/feature-flags/settings
# operationId: getFlagSettings
export def "projects-feature-flags-settings get" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<typeName: string, projectId: string, ownerId: string, enabled: bool, environments: list<string>, connections: table<edgeConfigId: string, edgeConfigItemKey: string>, entities: table<kind: string, label: string, attributes: list>, createdAt: float, updatedAt: float, metadata: record<activeFlagCount: float, archivedFlagCount: float, segmentCount: float, packSizeInBytes: float, packRevision: float, configUpdatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project flag settings
#
# PATCH /v1/projects/{projectIdOrName}/feature-flags/settings
# operationId: updateFlagSettings
# --entities item shape: {kind: string, label: string, attributes: list}
export def "projects-feature-flags-settings updateFlagSettings" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --enabled: string@bool-completer
  --entities: list # item shape: {kind: string, label: string, attributes: list}
  --environments: list # The environments to sync
]: any -> record<typeName: string, projectId: string, ownerId: string, enabled: bool, environments: list<string>, connections: table<edgeConfigId: string, edgeConfigItemKey: string>, entities: table<kind: string, label: string, attributes: list>, createdAt: float, updatedAt: float, metadata: record<activeFlagCount: float, archivedFlagCount: float, segmentCount: float, packSizeInBytes: float, packRevision: float, configUpdatedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/settings" $qp)
  let body = {enabled: $enabled, entities: $entities, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List team project flag settings
#
# GET /v1/teams/{teamId}/feature-flags/settings
# operationId: listTeamFlagSettings
export def "teams-feature-flags-settings listTeamFlagSettings" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of settings to return. (default: 20)
  --cursor: string # Pagination cursor to continue from.
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)/feature-flags/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all flags for a team
#
# GET /v2/teams/{teamId}/feature-flags/flags
# operationId: listTeamFlagsV2
export def "teams-feature-flags-flags listTeamFlagsV2" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # The state of the flags to retrieve. Defaults to `active`.
  --limit: int # Maximum number of flags to return. (default: 25)
  --cursor: string # Pagination cursor to continue from.
  --search: string # Search flags by their slug or description. Case-insensitive.
  --kind: string@kind-completer # The kind of flags to retrieve.
  --tags: list # Filter flags by tag. Repeat the parameter for multiple tags (all must match).
  --includeMarketplaceFlags: string@bool-completer # Whether to include Marketplace experimentation items in the paginated response. Defaults to false.
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<pagination: record<next: string>, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "includeMarketplaceFlags" $includeMarketplaceFlags "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($teamId)/feature-flags/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all flags for a team
#
# GET /v1/teams/{teamId}/feature-flags/flags
# operationId: listTeamFlags
export def "teams-feature-flags-flags listTeamFlags" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # The state of the flags to retrieve. Defaults to `active`.
  --withMetadata: string@bool-completer # Deprecated. Whether to include creator metadata in each flag in the response. Resolve creator identity client-side (e.g. via the team members endpoint) instead; this parameter will be removed in a future release.
  --limit: int # Maximum number of flags to return. (default: 20)
  --cursor: string # Pagination cursor to continue from.
  --search: string # Search flags by their slug or description. Case-insensitive.
  --kind: string@kind-completer # The kind of flags to retrieve.
  --tags: list # Filter flags by tag. Repeat the parameter for multiple tags (all must match).
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<data: table<description: string, maintainerIds: list, permanent: bool, tags: list, experiment: record, variants: list, id: string, environments: record, kind: string, revision: float, seed: float, state: string, slug: string, createdAt: float, updatedAt: float, createdBy: string, ownerId: string, projectId: string, typeName: string, metadata: record>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)/feature-flags/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a segment
#
# PUT /v1/projects/{projectIdOrName}/feature-flags/segments
# operationId: createFlagSegment
# --data shape: {rules?: list, include?: record, exclude?: record}
export def "projects-feature-flags-segments createFlagSegment" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  slug: string
  --createdBy: string # The entity who created the segment
  label: string
  --description: string
  data: record # The data of the segment — shape: {rules?: list, include?: record, exclude?: record}
  hint: string
]: any -> record<description: string, createdBy: string, usedByFlags: list<string>, usedBySegments: list<string>, data: record<rules: list<record>, include: record, exclude: record>, id: string, label: string, slug: string, createdAt: float, updatedAt: float, projectId: string, typeName: string, hint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/segments" $qp)
  let body = {slug: $slug, createdBy: $createdBy, label: $label, description: $description, data: $data, hint: $hint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List segments
#
# GET /v1/projects/{projectIdOrName}/feature-flags/segments
# operationId: listFlagSegments
export def "projects-feature-flags-segments listFlagSegments" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withMetadata: string@bool-completer # Whether to include metadata (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<data: table<description: string, createdBy: string, usedByFlags: list, usedBySegments: list, data: record, id: string, label: string, slug: string, createdAt: float, updatedAt: float, projectId: string, typeName: string, hint: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a segment
#
# GET /v1/projects/{projectIdOrName}/feature-flags/segments/{segmentIdOrSlug}
# operationId: getFlagSegment
export def "projects-feature-flags-segments get" [
  projectIdOrName: string
  segmentIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withMetadata: string@bool-completer # Whether to include metadata (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<description: string, createdBy: string, usedByFlags: list<string>, usedBySegments: list<string>, data: record<rules: list<record>, include: record, exclude: record>, id: string, label: string, slug: string, createdAt: float, updatedAt: float, projectId: string, typeName: string, hint: string, metadata: record<creator: record<id: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/segments/($segmentIdOrSlug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a segment
#
# DELETE /v1/projects/{projectIdOrName}/feature-flags/segments/{segmentIdOrSlug}
# operationId: deleteFlagSegment
export def "projects-feature-flags-segments delete" [
  projectIdOrName: string
  segmentIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withMetadata: string@bool-completer # Whether to include metadata (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/segments/($segmentIdOrSlug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a segment
#
# PATCH /v1/projects/{projectIdOrName}/feature-flags/segments/{segmentIdOrSlug}
# operationId: updateFlagSegment
# --operations item shape: {action: "add"|"remove", field: "include"|"exclude", entity: string, attribute: string, value: record}
# --data shape: {rules?: list, include?: record, exclude?: record}
export def "projects-feature-flags-segments updateFlagSegment" [
  projectIdOrName: string
  segmentIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withMetadata: string@bool-completer # Whether to include metadata (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --operations: list # item shape: {action: "add"|"remove", field: "include"|"exclude", entity: string, attribute: string, value: record}
  --label: string
  --description: string
  --data: record # The data of the segment — shape: {rules?: list, include?: record, exclude?: record}
  --hint: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withMetadata" $withMetadata "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/segments/($segmentIdOrSlug)" $qp)
  let body = {operations: $operations, label: $label, description: $description, data: $data, hint: $hint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the feature flags of a deployment
#
# GET /v1/deployments/{deploymentId}/feature-flags
# operationId: getDeploymentFeatureFlags
export def "deployments-feature-flags get" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<flags: list<record>, status: record<deploymentId: string, projectId: string, responseStatus: float, flagCount: float, createdAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/deployments/($deploymentId)/feature-flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all SDK keys
#
# GET /v1/projects/{projectIdOrName}/feature-flags/sdk-keys
# operationId: getSdkKeys
export def "projects-feature-flags-sdk-keys get" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<data: table<hashKey: string, projectId: string, type: string, environment: string, createdBy: string, createdAt: float, updatedAt: float, label: string, deletedAt: float, partialKeyValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/sdk-keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SDK key
#
# PUT /v1/projects/{projectIdOrName}/feature-flags/sdk-keys
# operationId: createSdkKey
export def "projects-feature-flags-sdk-keys createSdkKey" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  sdkKeyType: string@sdkKeyType-completer
  environment: string
  --label: string
]: any -> record<hashKey: string, projectId: string, type: string, environment: string, createdBy: string, createdAt: float, updatedAt: float, label: string, deletedAt: float, partialKeyValue: string, keyValue: string, tokenValue: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/sdk-keys" $qp)
  let body = {sdkKeyType: $sdkKeyType, environment: $environment, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SDK key
#
# DELETE /v1/projects/{projectIdOrName}/feature-flags/sdk-keys/{hashKey}
# operationId: deleteSdkKey
export def "projects-feature-flags-sdk-keys delete" [
  projectIdOrName: string
  hashKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectIdOrName)/feature-flags/sdk-keys/($hashKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List git namespaces by provider
#
# GET /v1/integrations/git-namespaces
# operationId: gitNamespaces
export def "integrations-git-namespaces gitNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --host: string # The custom Git host if using a custom Git provider, like GitHub Enterprise Server (e.g. ghes-test.now.systems)
  --provider: string@provider-completer
  --viewerMetadata: string@bool-completer # When true, includes the viewer object for each namespace.
]: nothing -> table<provider: string, slug: string, id: any, ownerType: string, name: string, isAccessRestricted: bool, installationId: float, requireReauth: bool, viewer: record<canCreateApp: bool, role: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host" $host "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "viewerMetadata" $viewerMetadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/git-namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List git repositories linked to namespace by provider
#
# GET /v1/integrations/search-repo
# operationId: searchRepo
export def "integrations-search-repo searchRepo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --namespaceId: string # nullable
  --provider: string@provider-completer
  --installationId: string
  --host: string # The custom Git host if using a custom Git provider, like GitHub Enterprise Server (e.g. ghes-test.now.systems)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "namespaceId" $namespaceId "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "installationId" $installationId "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/search-repo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List integration billing plans
#
# GET /v1/integrations/integration/{integrationIdOrSlug}/products/{productIdOrSlug}/plans
# operationId: getBillingPlans
export def "integrations-integration-products-plans get" [
  integrationIdOrSlug: string
  productIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integrationConfigurationId: string
  --metadata: string
  --qp-source: string@source-completer
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<plans: table<type: string, id: string, name: string, scope: string, description: string, paymentMethodRequired: bool, preauthorizationAmount: float, initialCharge: string, minimumAmount: string, maximumAmount: string, maximumAmountAutoPurchasePerPeriod: string, cost: string, details: list, highlightedDetails: list, quote: list, effectiveDate: string, disabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "integrationConfigurationId" $integrationConfigurationId "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/integration/($integrationIdOrSlug)/products/($productIdOrSlug)/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connect integration resource to project
#
# POST /v1/integrations/installations/{integrationConfigurationId}/resources/{resourceId}/connections
# operationId: connectIntegrationResourceToProject
export def "integrations-installations-resources-connections connectIntegrationResourceToProject" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  projectId: string
  --envVarEnvironments: list
  --makeEnvVarsSensitive: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/installations/($integrationConfigurationId)/resources/($resourceId)/connections" $qp)
  let body = {projectId: $projectId, envVarEnvironments: $envVarEnvironments, makeEnvVarsSensitive: $makeEnvVarsSensitive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Installation
#
# PATCH /v1/installations/{integrationConfigurationId}
# operationId: update-installation
# --billingPlan shape: {id: string, type: "prepayment"|"subscription", name: string, description?: string, paymentMethodRequired?: bool, cost?: string, details?: list, highlightedDetails?: list, effectiveDate?: string}
export def "installations update-installation" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-4
  --externalId: string
  --billingPlan: record # shape: {id: string, type: "prepayment"|"subscription", name: string, description?: string, paymentMethodRequired?: bool, cost?: string, details?: list, highlightedDetails?: list, effectiveDate?: string}
  --notification: any # A notification to display to your customer. Send `null` to clear the current notification.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)")
  let body = {status: $status, externalId: $externalId, billingPlan: $billingPlan, notification: $notification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Account Information
#
# GET /v1/installations/{integrationConfigurationId}/account
# operationId: get-account-info
export def "installations-account get-account-info" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, url: string, contact: record<email: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Member Information
#
# GET /v1/installations/{integrationConfigurationId}/member/{memberId}
# operationId: get-member
export def "installations-member get-member" [
  integrationConfigurationId: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, role: string, globalUserId: string, userEmail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/member/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Event
#
# POST /v1/installations/{integrationConfigurationId}/events
# operationId: create-event
export def "installations-events create-event" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/events")
  let body = {event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Integration Resources
#
# GET /v1/installations/{integrationConfigurationId}/resources
# operationId: get-integration-resources
export def "installations-resources get-integration-resources" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resources: table<partnerId: string, internalId: string, name: string, status: string, productId: string, protocolSettings: record, notification: record, billingPlanId: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Integration Resource
#
# GET /v1/installations/{integrationConfigurationId}/resources/{resourceId}
# operationId: get-integration-resource
export def "installations-resources get-integration-resource" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, internalId: string, name: string, status: string, productId: string, protocolSettings: record<experimentation: record<edgeConfigSyncingEnabled: bool, edgeConfigId: string, edgeConfigTokenId: string>>, notification: record<level: string, title: string, message: string, href: string>, billingPlanId: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Integration Resource
#
# DELETE /v1/installations/{integrationConfigurationId}/resources/{resourceId}
# operationId: delete-integration-resource
export def "installations-resources delete-integration-resource" [
  integrationConfigurationId: string
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
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import Resource
#
# PUT /v1/installations/{integrationConfigurationId}/resources/{resourceId}
# operationId: import-resource
# --billingPlan shape: {id: string, type: "prepayment"|"subscription", name: string, description?: string, paymentMethodRequired?: bool, cost?: string, details?: list, highlightedDetails?: list, effectiveDate?: string}
# --notification shape: {level: "info"|"warn"|"error", title: string, message?: string, href?: string}
# --secrets item shape: {name: string, value: string, prefix?: string, environmentOverrides?: record}
export def "installations-resources import-resource" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownership: string@ownership-completer
  productId: string
  name: string
  status: string@status-completer-4
  --metadata: record
  --billingPlan: record # shape: {id: string, type: "prepayment"|"subscription", name: string, description?: string, paymentMethodRequired?: bool, cost?: string, details?: list, highlightedDetails?: list, effectiveDate?: string}
  --notification: record # shape: {level: "info"|"warn"|"error", title: string, message?: string, href?: string}
  --extras: record
  --secrets: list # item shape: {name: string, value: string, prefix?: string, environmentOverrides?: record}
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)")
  let body = {ownership: $ownership, productId: $productId, name: $name, status: $status, metadata: $metadata, billingPlan: $billingPlan, notification: $notification, extras: $extras, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Resource
#
# PATCH /v1/installations/{integrationConfigurationId}/resources/{resourceId}
# operationId: update-resource
# --billingPlan shape: {id: string, type: "prepayment"|"subscription", name: string, description?: string, paymentMethodRequired?: bool, cost?: string, details?: list, highlightedDetails?: list, effectiveDate?: string}
export def "installations-resources update-resource" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownership: string@ownership-completer
  --name: string
  --status: string@status-completer-4
  --metadata: record
  --billingPlan: record # shape: {id: string, type: "prepayment"|"subscription", name: string, description?: string, paymentMethodRequired?: bool, cost?: string, details?: list, highlightedDetails?: list, effectiveDate?: string}
  --notification: any
  --extras: record
  --secrets: any
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)")
  let body = {ownership: $ownership, name: $name, status: $status, metadata: $metadata, billingPlan: $billingPlan, notification: $notification, extras: $extras, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Billing Data
#
# POST /v1/installations/{integrationConfigurationId}/billing
# operationId: submit-billing-data
# --period shape: {start: string, end: string}
# --usage item shape: {resourceId?: string, name: string, type: "total"|"interval"|"rate", units: string, dayValue: float, periodValue: float, planValue?: float}
export def "installations-billing submit-billing-data" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timestamp: string # Server time of your integration, used to determine the most recent data for race conditions & updates. Only the latest usage data for a given day, week, and month will be kept. (format: date-time)
  eod: string # End of Day, the UTC datetime for when the end of the billing/usage day is in UTC time. This tells us which day the usage data is for, and also allows for your "end of day" to be different from UTC 00:00:00. eod must be within the period dates, and cannot be older than 24h earlier from our server's current time. (format: date-time)
  period: record # Period for the billing cycle. The period end date cannot be older than 24 hours earlier than our current server's time. — shape: {start: string, end: string}
  billing: any # Billing data (interim invoicing data).
  usage: list # item shape: {resourceId?: string, name: string, type: "total"|"interval"|"rate", units: string, dayValue: float, periodValue: float, planValue?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/billing")
  let body = {timestamp: $timestamp, eod: $eod, period: $period, billing: $billing, usage: $usage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Invoice
#
# POST /v1/installations/{integrationConfigurationId}/billing/invoices
# operationId: submit-invoice
# --period shape: {start: string, end: string}
# --items item shape: {resourceId?: string, billingPlanId: string, start?: string, end?: string, name: string, details?: string, price: string, quantity: float, units: string, total: string}
# --discounts item shape: {resourceId?: string, billingPlanId: string, start?: string, end?: string, name: string, details?: string, amount: string}
# --test shape: {validate?: bool, result?: "paid"|"notpaid"}
export def "installations-billing-invoices submit-invoice" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalId: string # Partner-provided invoice identifier. If provided, it must be unique for this installation.
  invoiceDate: string # Invoice date. Must be within the period's start and end. (format: date-time)
  --memo: string # Additional memo for the invoice.
  period: record # Subscription period for this billing cycle. — shape: {start: string, end: string}
  items: list # item shape: {resourceId?: string, billingPlanId: string, start?: string, end?: string, name: string, details?: string, price: string, quantity: float, units: string, total: string}
  --discounts: list # item shape: {resourceId?: string, billingPlanId: string, start?: string, end?: string, name: string, details?: string, amount: string}
  --final: string@bool-completer # Set this to `true` if this is the final invoice for the installation. Can only be set when the installation is pending deletion.
  --test: record # Test mode — shape: {validate?: bool, result?: "paid"|"notpaid"}
]: any -> record<invoiceId: string, test: bool, validationErrors: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/billing/invoices")
  let body = {externalId: $externalId, invoiceDate: $invoiceDate, memo: $memo, period: $period, items: $items, discounts: $discounts, final: $final, test: $test} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finalize Installation
#
# POST /v1/installations/{integrationConfigurationId}/billing/finalize
# operationId: finalize-installation
export def "installations-billing-finalize finalize-installation" [
  integrationConfigurationId: string
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
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/billing/finalize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Invoice
#
# GET /v1/installations/{integrationConfigurationId}/billing/invoices/{invoiceId}
# operationId: get-invoice
export def "installations-billing-invoices get-invoice" [
  integrationConfigurationId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<test: bool, invoiceId: string, externalId: string, state: string, invoiceNumber: string, invoiceDate: string, period: record<start: string, end: string>, paidAt: string, refundedAt: string, memo: string, items: table<billingPlanId: string, resourceId: string, start: string, end: string, name: string, details: string, price: string, quantity: float, units: string, total: string>, discounts: table<billingPlanId: string, resourceId: string, start: string, end: string, name: string, details: string, amount: string>, total: string, refundReason: string, refundTotal: string, created: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/billing/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoice Actions
#
# POST /v1/installations/{integrationConfigurationId}/billing/invoices/{invoiceId}/actions
# operationId: update-invoice
export def "installations-billing-invoices-actions update-invoice" [
  integrationConfigurationId: string
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-1
  --reason: string # Refund reason.
  --total: string # The total amount to be refunded. Must be less than or equal to the total amount of the invoice.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/billing/invoices/($invoiceId)/actions")
  let body = {action: $action, reason: $reason, total: $total} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Prepayment Balances
#
# POST /v1/installations/{integrationConfigurationId}/billing/balance
# operationId: submit-prepayment-balances
# --balances item shape: {resourceId?: string, credit?: string, nameLabel?: string, currencyValueInCents: float}
export def "installations-billing-balance submit-prepayment-balances" [
  integrationConfigurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timestamp: string # Server time of your integration, used to determine the most recent data for race conditions & updates. Only the latest usage data for a given day, week, and month will be kept. (format: date-time)
  balances: list # item shape: {resourceId?: string, credit?: string, nameLabel?: string, currencyValueInCents: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/billing/balance")
  let body = {timestamp: $timestamp, balances: $balances} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deprecated: true. Update Resource Secrets (Deprecated)
#
# PUT /v1/installations/{integrationConfigurationId}/products/{integrationProductIdOrSlug}/resources/{resourceId}/secrets
# DEPRECATED
# operationId: update-resource-secrets
# --secrets item shape: {name: string, value: string, prefix?: string, environmentOverrides?: record}
@deprecated
export def "installations-products-resources-secrets update-resource-secrets" [
  integrationConfigurationId: string
  integrationProductIdOrSlug: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  secrets: list # item shape: {name: string, value: string, prefix?: string, environmentOverrides?: record}
  --partial: string@bool-completer # If true, will only update the provided secrets
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/products/($integrationProductIdOrSlug)/resources/($resourceId)/secrets")
  let body = {secrets: $secrets, partial: $partial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Resource Secrets
#
# PUT /v1/installations/{integrationConfigurationId}/resources/{resourceId}/secrets
# operationId: update-resource-secrets-by-id
# --secrets item shape: {name: string, value: string, prefix?: string, environmentOverrides?: record}
export def "installations-resources-secrets update-resource-secrets-by-id" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  secrets: list # item shape: {name: string, value: string, prefix?: string, environmentOverrides?: record}
  --partial: string@bool-completer # If true, will only overwrite the provided secrets instead of replacing all secrets.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/secrets")
  let body = {secrets: $secrets, partial: $partial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get configurations for the authenticated user or team
#
# GET /v1/integrations/configurations
# operationId: getConfigurations
export def "integrations-configurations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer
  --installationType: string@installationType-completer
  --integrationIdOrSlug: string # ID of the integration
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "installationType" $installationType "scalar") (serialize-qp "integrationIdOrSlug" $integrationIdOrSlug "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an integration configuration
#
# GET /v1/integrations/configuration/{id}
# operationId: getConfiguration
export def "integrations-configuration get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/configuration/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an integration configuration
#
# DELETE /v1/integrations/configuration/{id}
# operationId: deleteConfiguration
export def "integrations-configuration delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/configuration/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List products for integration configuration
#
# GET /v1/integrations/configuration/{id}/products
# operationId: getConfigurationProducts
export def "integrations-configuration-products get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<products: table<id: string, slug: string, name: string, protocols: record, primaryProtocol: string, metadataSchema: record>, integration: record<id: string, slug: string, name: string>, configuration: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/configuration/($id)/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SSO Token Exchange
#
# POST /v1/integrations/sso/token
# operationId: exchange-sso-token
export def "integrations-sso-token exchange-sso-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # The sensitive code received from Vercel
  --state: string # The state received from the initialization request
  --client-id: string # The integration client id
  --client-secret: string # The integration client secret
  --redirect-uri: string # The integration redirect URI
  --grant-type: string@grant-type-completer # The grant type, when using x-www-form-urlencoded content type
  --refresh-token: string # The refresh token received from previous token exchange
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/sso/token")
  let body = {code: $code, state: $state, client_id: $client_id, client_secret: $client_secret, redirect_uri: $redirect_uri, grant_type: $grant_type, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of Integration log drains (deprecated)
#
# GET /v2/integrations/log-drains
# operationId: getIntegrationLogDrains
export def "integrations-log-drains get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> table<clientId: string, configurationId: string, createdAt: float, id: string, deliveryFormat: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, url: string, sources: list<string>, createdFrom: string, headers: record, environments: list<string>, branch: string, samplingRate: float, source: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations/log-drains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new Integration Log Drain (deprecated)
#
# POST /v2/integrations/log-drains
# operationId: createLogDrain
export def "integrations-log-drains createLogDrain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string # The name of the log drain (e.g. My first log drain)
  --projectIds: list
  --secret: string # A secret to sign log drain notification headers so a consumer can verify their authenticity (e.g. a1Xsfd325fXcs)
  --deliveryFormat: any@deliveryFormat-completer # The delivery log format (e.g. json)
  --body-url: string # The url where you will receive logs. The protocol must be `https://` or `http://` when type is `json` and `ndjson`. (format: uri, e.g. https://example.com/log-drain)
  --sources: list
  --headers: record # Headers to be sent together with the request
  --environments: list
]: any -> record<clientId: string, configurationId: string, createdAt: float, id: string, deliveryFormat: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, url: string, sources: list<string>, createdFrom: string, headers: record, environments: list<string>, branch: string, samplingRate: float, source: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/integrations/log-drains" $qp)
  let body = {name: $name, projectIds: $projectIds, secret: $secret, deliveryFormat: $deliveryFormat, url: $body_url, sources: $sources, headers: $headers, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the Integration log drain with the provided `id` (deprecated)
#
# DELETE /v1/integrations/log-drains/{id}
# operationId: deleteIntegrationLogDrain
export def "integrations-log-drains delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/log-drains/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get logs for a deployment
#
# GET /v1/projects/{projectId}/deployments/{deploymentId}/runtime-logs
# operationId: getRuntimeLogs
export def "projects-deployments-runtime-logs get" [
  projectId: string
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/deployments/($deploymentId)/runtime-logs" $qp)
  let accept_val = "application/stream+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create one or multiple experimentation items
#
# POST /v1/installations/{integrationConfigurationId}/resources/{resourceId}/experimentation/items
# operationId: createInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationItems
# --items item shape: {id: string, slug: string, origin: string, category?: "experiment"|"flag", name?: string, description?: string, isArchived?: bool, createdAt?: float, updatedAt?: float}
export def "installations-resources-experimentation-items createInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationItems" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # item shape: {id: string, slug: string, origin: string, category?: "experiment"|"flag", name?: string, description?: string, isArchived?: bool, createdAt?: float, updatedAt?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/experimentation/items")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch an existing experimentation item
#
# PATCH /v1/installations/{integrationConfigurationId}/resources/{resourceId}/experimentation/items/{itemId}
# operationId: updateInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationItemsByItemId
export def "installations-resources-experimentation-items updateInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationItemsByItemId" [
  integrationConfigurationId: string
  resourceId: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string
  origin: string
  --name: string
  --category: string@category-completer
  --description: string
  --isArchived: string@bool-completer
  --createdAt: float
  --updatedAt: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/experimentation/items/($itemId)")
  let body = {slug: $slug, origin: $origin, name: $name, category: $category, description: $description, isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing experimentation item
#
# DELETE /v1/installations/{integrationConfigurationId}/resources/{resourceId}/experimentation/items/{itemId}
# operationId: deleteInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationItemsByItemId
export def "installations-resources-experimentation-items delete" [
  integrationConfigurationId: string
  resourceId: string
  itemId: string
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
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/experimentation/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the data of a user-provided Edge Config
#
# HEAD /v1/installations/{integrationConfigurationId}/resources/{resourceId}/experimentation/edge-config
# operationId: headInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationEdgeConfig
export def "installations-resources-experimentation-edge-config headInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationEdgeConfig" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/experimentation/edge-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the data of a user-provided Edge Config
#
# GET /v1/installations/{integrationConfigurationId}/resources/{resourceId}/experimentation/edge-config
# operationId: getInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationEdgeConfig
export def "installations-resources-experimentation-edge-config get" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: record, updatedAt: float, digest: string, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/experimentation/edge-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push data into a user-provided Edge Config
#
# PUT /v1/installations/{integrationConfigurationId}/resources/{resourceId}/experimentation/edge-config
# operationId: replaceInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationEdgeConfig
export def "installations-resources-experimentation-edge-config replaceInstallationsByIntegrationConfigurationIdResourcesByResourceIdExperimentationEdgeConfig" [
  integrationConfigurationId: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record
]: any -> record<items: record, updatedAt: float, digest: string, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/installations/($integrationConfigurationId)/resources/($resourceId)/experimentation/edge-config")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List microfrontends groups
#
# GET /v1/microfrontends/groups
# operationId: getMicrofrontendsGroups
export def "microfrontends-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/microfrontends/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List projects in a microfrontends group
#
# GET /v1/microfrontends/groups/{groupId}/projects
# operationId: getMicrofrontendsInGroup
export def "microfrontends-groups-projects get" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<projects: table<accountId: string, analytics: record, appliedCve55182Migration: bool, speedInsights: record, autoExposeSystemEnvs: bool, autoAssignCustomDomains: bool, autoAssignCustomDomainsUpdatedBy: string, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurations: list, connectConfigurationId: string, connectBuildsEnabled: bool, passiveConnectConfigurationId: string, createdAt: float, customerSupportCodeVisibility: bool, crons: record, dataCache: record, deploymentExpiration: record, expiration: any, devCommand: string, directoryListing: bool, installCommand: string, env: list, customEnvironments: list, framework: string, services: list, gitForkProtection: bool, gitLFS: bool, id: string, ipBuckets: list, jobs: record, latestDeployments: list, link: any, microfrontends: any, name: string, nodeVersion: string, optionsAllowlist: record, outputDirectory: string, passwordProtection: record, passport: record, protectionConfig: record, productionDeploymentsFastLane: bool, publicSource: bool, resourceConfig: record, rollbackDescription: record, rollingRelease: record, defaultResourceConfig: record, rootDirectory: string, serverlessFunctionZeroConfigFailover: bool, skewProtectionBoundaryAt: float, skewProtectionMaxAge: float, skewProtectionAllowedDomains: list, skipGitConnectDuringLink: bool, staticIps: record, sourceFilesOutsideRootDirectory: bool, enableAffectedProjectsDeployments: bool, enableExternalRewriteCaching: bool, ssoProtection: record, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float, live: bool, enablePreviewFeedback: bool, enableProductionFeedback: bool, permissions: record, lastRollbackTarget: record, lastAliasRequest: record, protectionBypass: record, hasActiveBranches: bool, trustedIps: any, trustedSources: record, gitComments: record, gitProviderOptions: record, paused: bool, concurrencyBucketName: string, webAnalytics: record, security: record, oidcTokenConfig: record, deploymentPolicy: record, tier: string, flatRateTier: string, usageStatus: record, features: record, v0: bool, v0Created: bool, abuse: record, internalRoutes: list, hasDeployments: bool, dismissedToasts: list, protectedSourcemaps: bool, tracing: record, avatar: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/microfrontends/groups/($groupId)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get microfrontends config for a deployment
#
# GET /v1/microfrontends/{deploymentId}/config
# operationId: getMicrofrontendsConfig
export def "microfrontends-config get" [
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<config: record<_schema: string, version: string, applications: record, options: record<disableOverrides: bool, localProxyPort: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/microfrontends/($deploymentId)/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get microfrontends config for a project
#
# GET /v1/microfrontends/projects/{projectIdOrName}/production-mfe-config
# operationId: getMicrofrontendsConfigForProject
export def "microfrontends-projects-production-mfe-config get" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<config: record<_schema: string, version: string, applications: record, options: record<disableOverrides: bool, localProxyPort: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/microfrontends/projects/($projectIdOrName)/production-mfe-config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a microfrontends group with applications
#
# POST /v1/microfrontends/group
# operationId: createMicrofrontendsGroupWithApplications
# --defaultApp shape: {projectId: string, defaultRoute?: string}
# --otherApplications item shape: {projectId: string, defaultRoute?: string}
export def "microfrontends-group createMicrofrontendsGroupWithApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  groupName: string # The name of the microfrontends group that will be used to identify the group (e.g. MFE Group 1)
  defaultApp: record # The default app for the new microfrontend group — shape: {projectId: string, defaultRoute?: string}
  otherApplications: list # The list of other applications that will be used in the new microfrontend group — item shape: {projectId: string, defaultRoute?: string}
]: any -> record<newMicrofrontendsGroup: record<id: string, slug: string, name: string, fallbackEnvironment: string, createdAt: float, updatedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/microfrontends/group" $qp)
  let body = {groupName: $groupName, defaultApp: $defaultApp, otherApplications: $otherApplications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists disabled Observability Plus projects
#
# GET /v1/observability/manage/configuration/projects
# operationId: getObservabilityConfigurationProjects
export def "observability-manage-configuration-projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<disabledProjects: table<id: string, name: string, disabledAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/observability/manage/configuration/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a disabled Observability Plus project setting
#
# PUT /v1/observability/manage/configuration/projects/{projectIdOrName}
# operationId: updateObservabilityConfigurationProject
export def "observability-manage-configuration-projects updateObservabilityConfigurationProject" [
  projectIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --disabled: string@bool-completer # Whether Observability Plus should be disabled for the project
]: any -> record<id: string, disabledAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/observability/manage/configuration/projects/($projectIdOrName)" $qp)
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List project members
#
# GET /v1/projects/{idOrName}/members
# operationId: getProjectMembers
export def "projects-members get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit how many project members should be returned (e.g. 20)
  --since: int # Timestamp in milliseconds to only include members added since then. (e.g. 1540095775951)
  --until: int # Timestamp in milliseconds to only include members added until then. (e.g. 1540095775951)
  --search: string # Search project members by their name, username, and email.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new member to a project.
#
# POST /v1/projects/{idOrName}/members
# operationId: addProjectMember
export def "projects-members addProjectMember" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --uid: string # The ID of the team member that should be added to this project. (e.g. ndlgr43fadlPyCtREAqxxdyFK)
  --username: string # The username of the team member that should be added to this project. (e.g. example)
  --email: string # The email of the team member that should be added to this project. (format: email, e.g. entity@example.com)
  role: string@role-completer # The project role of the member that will be added. (e.g. ADMIN)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/members" $qp)
  let body = {uid: $uid, username: $username, email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a Project Member
#
# DELETE /v1/projects/{idOrName}/members/{uid}
# operationId: removeProjectMember
export def "projects-members removeProjectMember" [
  idOrName: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/members/($uid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project routing rules
#
# GET /v1/projects/{projectId}/routes
# operationId: getRoutes
export def "projects-routes get" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string
  --q: string
  --filter: string@filter-completer
  --diff: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "diff" $diff "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stage routing rules
#
# PUT /v1/projects/{projectId}/routes
# operationId: stageRoutes
# --routes item shape: {id: string, name: string, description?: string, enabled?: bool, route: record}
export def "projects-routes stageRoutes" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --overwrite: string@bool-completer
  --routes: list # default: [] — item shape: {id: string, name: string, description?: string, enabled?: bool, route: record}
]: any -> record<version: record<id: string, s3Key: string, lastModified: float, createdBy: string, isStaging: bool, isLive: bool, ruleCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes" $qp)
  let body = {overwrite: $overwrite, routes: $routes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a routing rule
#
# POST /v1/projects/{projectId}/routes
# operationId: addRoute
# --route shape: {name: string, description?: string, enabled?: bool, srcSyntax?: "equals"|"path-to-regexp"|"regex", route: record}
# --position shape: {placement?: "start"|"end"|"after"|"before", referenceId?: string}
export def "projects-routes addRoute" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  route: record # shape: {name: string, description?: string, enabled?: bool, srcSyntax?: "equals"|"path-to-regexp"|"regex", route: record}
  --position: record # Controls where the route is inserted. Defaults to "end" if omitted. — shape: {placement?: "start"|"end"|"after"|"before", referenceId?: string}
]: any -> record<route: record<routeType: string, id: string, name: string, description: string, enabled: bool, staged: bool, route: record<src: string, dest: string, headers: record, methods: list, continue: bool, override: bool, caseSensitive: bool, check: bool, important: bool, status: float, has: list, missing: list, mitigate: record, transforms: list, env: list, locale: record, source: string, destination: any, statusCode: float, middlewarePath: string, middlewareRawSrc: list, middleware: float, respectOriginCacheControl: bool>, rawSrc: string, rawDest: string, srcSyntax: string>, version: record<id: string, s3Key: string, lastModified: float, createdBy: string, isStaging: bool, isLive: bool, ruleCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes" $qp)
  let body = {route: $route, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete routing rules
#
# DELETE /v1/projects/{projectId}/routes
# operationId: deleteRoutes
export def "projects-routes delete" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  routeIds: list # The IDs of the routes to delete
]: any -> record<deletedCount: float, version: record<id: string, s3Key: string, lastModified: float, createdBy: string, isStaging: bool, isLive: bool, ruleCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes" $qp)
  let body = {routeIds: $routeIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit a routing rule
#
# PATCH /v1/projects/{projectId}/routes/{routeId}
# operationId: editRoute
# --route shape: {name: string, description?: string, enabled?: bool, srcSyntax?: "equals"|"path-to-regexp"|"regex", route: record}
export def "projects-routes editRoute" [
  projectId: string
  routeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --route: record # The full route object to replace the existing route with — shape: {name: string, description?: string, enabled?: bool, srcSyntax?: "equals"|"path-to-regexp"|"regex", route: record}
  --restore: string@bool-completer # If true, restores the staged route to the value in the production version.
]: any -> record<route: record<routeType: string, id: string, name: string, description: string, enabled: bool, staged: bool, route: record<src: string, dest: string, headers: record, methods: list, continue: bool, override: bool, caseSensitive: bool, check: bool, important: bool, status: float, has: list, missing: list, mitigate: record, transforms: list, env: list, locale: record, source: string, destination: any, statusCode: float, middlewarePath: string, middlewareRawSrc: list, middleware: float, respectOriginCacheControl: bool>, rawSrc: string, rawDest: string, srcSyntax: string>, version: record<id: string, s3Key: string, lastModified: float, createdBy: string, isStaging: bool, isLive: bool, ruleCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes/($routeId)" $qp)
  let body = {route: $route, restore: $restore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a routing rule from natural language
#
# POST /v1/projects/{projectId}/routes/generate
# operationId: generateRoute
# --currentRoute shape: {name?: string, description?: string, pathCondition: record, conditions?: list, actions: list}
export def "projects-routes-generate generateRoute" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  prompt: string
  --currentRoute: record # shape: {name?: string, description?: string, pathCondition: record, conditions?: list, actions: list}
]: any -> record<route: record<name: string, description: string, pathCondition: record<value: string, syntax: string>, conditions: list<record>, actions: list<record>>, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes/generate" $qp)
  let body = {prompt: $prompt, currentRoute: $currentRoute} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get routing rule version history
#
# GET /v1/projects/{projectId}/routes/versions
# operationId: getRouteVersions
export def "projects-routes-versions get" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<versions: table<id: string, s3Key: string, lastModified: float, createdBy: string, isStaging: bool, isLive: bool, ruleCount: float, alias: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Promote, restore, or discard a routing rule version
#
# POST /v1/projects/{projectId}/routes/versions
# operationId: updateRouteVersions
export def "projects-routes-versions updateRouteVersions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  id: string
  action: string@action-completer
]: any -> record<version: record<id: string, s3Key: string, lastModified: float, createdBy: string, isStaging: bool, isLive: bool, ruleCount: float, alias: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/routes/versions" $qp)
  let body = {id: $id, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of projects
#
# GET /v10/projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Query only projects updated after the given timestamp or continuation token.
  --gitForkProtection: string@gitForkProtection-completer # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed (e.g. 1)
  --limit: string # Limit the number of projects returned
  --search: string # Search projects by the name field
  --repo: string # Filter results by repo. Also used for project count
  --repoId: string # Filter results by Repository ID.
  --repoUrl: string # Filter results by Repository URL. (e.g. https://github.com/vercel/next.js)
  --excludeRepos: string # Filter results by excluding those projects that belong to a repo
  --edgeConfigId: string # Filter results by connected Edge Config ID
  --edgeConfigTokenId: string # Filter results by connected Edge Config Token ID
  --deprecated: string@bool-completer
  --elasticConcurrencyEnabled: string@elasticConcurrencyEnabled-completer # Filter results by projects with elastic concurrency enabled (e.g. 1)
  --staticIpsEnabled: string@staticIpsEnabled-completer # Filter results by projects with Static IPs enabled (e.g. 1)
  --buildMachineTypes: string # Filter results by build machine types. Accepts comma-separated values. Use "default" for projects without a build machine type set. (e.g. default,enhanced)
  --buildQueueConfiguration: string@buildQueueConfiguration-completer # Filter results by build queue configuration. SKIP_NAMESPACE_QUEUE includes projects without a configuration set. (e.g. SKIP_NAMESPACE_QUEUE)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "gitForkProtection" $gitForkProtection "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "repoId" $repoId "scalar") (serialize-qp "repoUrl" $repoUrl "scalar") (serialize-qp "excludeRepos" $excludeRepos "scalar") (serialize-qp "edgeConfigId" $edgeConfigId "scalar") (serialize-qp "edgeConfigTokenId" $edgeConfigTokenId "scalar") (serialize-qp "deprecated" $deprecated "scalar") (serialize-qp "elasticConcurrencyEnabled" $elasticConcurrencyEnabled "scalar") (serialize-qp "staticIpsEnabled" $staticIpsEnabled "scalar") (serialize-qp "buildMachineTypes" $buildMachineTypes "scalar") (serialize-qp "buildQueueConfiguration" $buildQueueConfiguration "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v10/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project
#
# POST /v11/projects
# operationId: createProject
# --environmentVariables item shape: {key: string, target: any, gitBranch?: string, type?: "system"|"encrypted"|"plain"|"sensitive", value: string}
# --gitRepository shape: {repo: string, type: "github"|"github-limited"|"gitlab"|"bitbucket"|"vercel"}
# --ssoProtection shape: {deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
# --oidcTokenConfig shape: {enabled?: bool, issuerMode?: "team"|"global"}
# --resourceConfig shape: {buildMachineType?: "enhanced"|"turbo"|"standard"|"elastic", fluid?: bool, functionDefaultRegions?: list, functionDefaultTimeout?: float, functionDefaultMemoryType?: "standard_legacy"|"standard"|"performance", functionZeroConfigFailover?: any, elasticConcurrencyEnabled?: bool, buildMachineSelection?: "elastic"|"fixed", buildMachineElasticLastUpdated?: float, isNSNBDisabled?: bool, buildQueue?: record, enableFunctionsBeta?: bool}
@deprecated --flag skipGitConnectDuringLink
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --enablePreviewFeedback: string@bool-completer # Opt-in to preview toolbar on the project level (nullable)
  --enableProductionFeedback: string@bool-completer # Opt-in to production toolbar on the project level (nullable)
  --previewDeploymentsDisabled: string@bool-completer # Specifies whether preview deployments are disabled for this project. (nullable)
  --previewDeploymentSuffix: string # Custom domain suffix for preview deployments. Takes precedence over team-level suffix. Must be a domain owned by the team. (nullable)
  --buildCommand: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --commandForIgnoringBuildStep: string # nullable
  --devCommand: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --environmentVariables: list # Collection of ENV Variables the Project will use — item shape: {key: string, target: any, gitBranch?: string, type?: "system"|"encrypted"|"plain"|"sensitive", value: string}
  --framework: any@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected
  --gitRepository: record # The Git Repository that will be connected to the project. When this is defined, any pushes to the specified connected Git Repository will be automatically deployed — shape: {repo: string, type: "github"|"github-limited"|"gitlab"|"bitbucket"|"vercel"}
  --installCommand: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  name: string # The desired name for the project (e.g. a-project-name)
  --skipGitConnectDuringLink: string@bool-completer # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
  --ssoProtection: record # The Vercel Auth setting for the project (historically named \"SSO Protection\") (nullable) — shape: {deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
  --outputDirectory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --publicSource: string@bool-completer # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --rootDirectory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverlessFunctionRegion: string # The region to deploy Serverless Functions in this project (nullable)
  --serverlessFunctionZeroConfigFailover: any # Specifies whether Zero Config Failover is enabled for this project.
  --oidcTokenConfig: record # OpenID Connect JSON Web Token generation configuration. — shape: {enabled?: bool, issuerMode?: "team"|"global"}
  --enableAffectedProjectsDeployments: string@bool-completer # Opt-in to skip deployments when there are no changes to the root directory and its dependencies
  --resourceConfig: record # Specifies resource override configuration for the project — shape: {buildMachineType?: "enhanced"|"turbo"|"standard"|"elastic", fluid?: bool, functionDefaultRegions?: list, functionDefaultTimeout?: float, functionDefaultMemoryType?: "standard_legacy"|"standard"|"performance", functionZeroConfigFailover?: any, elasticConcurrencyEnabled?: bool, buildMachineSelection?: "elastic"|"fixed", buildMachineElasticLastUpdated?: float, isNSNBDisabled?: bool, buildQueue?: record, enableFunctionsBeta?: bool}
]: any -> record<accountId: string, analytics: record<id: string, canceledAt: float, disabledAt: float, enabledAt: float, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, appliedCve55182Migration: bool, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, autoExposeSystemEnvs: bool, autoAssignCustomDomains: bool, autoAssignCustomDomainsUpdatedBy: string, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurations: table<envId: any, connectConfigurationId: string, dc: string, passive: bool, buildsEnabled: bool, aws: record, createdAt: float, updatedAt: float>, connectConfigurationId: string, connectBuildsEnabled: bool, passiveConnectConfigurationId: string, createdAt: float, customerSupportCodeVisibility: bool, crons: record<enabledAt: float, disabledAt: float, updatedAt: float, deploymentId: string, definitions: list<record>>, dataCache: record<userDisabled: bool, storageSizeBytes: float, unlimited: bool>, deploymentExpiration: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, expiration: any, devCommand: string, directoryListing: bool, installCommand: string, env: table<target: any, type: string, sunsetSecretId: string, legacyValue: string, decrypted: bool, value: string, vsmValue: string, id: string, key: string, configurationId: string, createdAt: float, updatedAt: float, createdBy: string, updatedBy: string, gitBranch: string, edgeConfigId: string, edgeConfigTokenId: string, contentHint: any, internalContentHint: record, comment: string, customEnvironmentIds: list>, customEnvironments: table<id: string, slug: string, type: string, description: string, branchMatcher: record, domains: list, currentDeploymentAliases: list, createdAt: float, updatedAt: float>, framework: string, services: table<serviceName: string, serviceType: string, framework: string, runtime: string>, gitForkProtection: bool, gitLFS: bool, id: string, ipBuckets: table<bucket: string, default: bool, supportUntil: float>, jobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, latestDeployments: table<alias: list, aliasAssigned: any, builds: list, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, name: string, forced: bool, id: string, meta: record, plan: string, private: bool, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, microfrontends: any, name: string, nodeVersion: string, optionsAllowlist: record<paths: list<record>>, outputDirectory: string, passwordProtection: record, passport: record<deploymentType: string, connectorId: string>, protectionConfig: record<sandboxUrls: record<inheritDeploymentProtection: bool>>, productionDeploymentsFastLane: bool, publicSource: bool, resourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rollbackDescription: record<userId: string, username: string, description: string, createdAt: float>, rollingRelease: record<target: string, stages: list<record>, canaryResponseHeader: bool>, defaultResourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rootDirectory: string, serverlessFunctionZeroConfigFailover: bool, skewProtectionBoundaryAt: float, skewProtectionMaxAge: float, skewProtectionAllowedDomains: list<string>, skipGitConnectDuringLink: bool, staticIps: record<builds: bool, enabled: bool, regions: list<string>>, sourceFilesOutsideRootDirectory: bool, enableAffectedProjectsDeployments: bool, enableExternalRewriteCaching: bool, ssoProtection: record<deploymentType: string, cve55182MigrationAppliedFrom: string, april2026SecurityIncidentMigrationAppliedFrom: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float, live: bool, enablePreviewFeedback: bool, enableProductionFeedback: bool, permissions: record<oauth2Connection: list<string>, user: list<string>, userConnection: list<string>, userMfaConfiguration: list<string>, userPreference: list<string>, userSudo: list<string>, webAuthn: list<string>, accessGroup: list<string>, agent: list<string>, aiGatewayUsage: list<string>, alerts: list<string>, alertRules: list<string>, aliasGlobal: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, apiKey: list<string>, apiKeyAiGateway: list<string>, apiKeyOwnedBySelf: list<string>, oauth2Application: list<string>, vercelAppInstallation: list<string>, vercelAppInstallationRequest: list<string>, auditLog: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingRefund: list<string>, billingTaxId: list<string>, blob: list<string>, blobStoreTokenSet: list<string>, budget: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, codeChecks: list<string>, ciInvocations: list<string>, ciLogs: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connexClient: list<string>, connexClientProject: list<string>, connexToken: list<string>, buildMachineDefault: list<string>, dataCacheBillingSettings: list<string>, defaultDeploymentProtection: list<string>, deploymentPolicy: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, drain: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigSchema: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, flagsExplorerSubscription: list<string>, gitRepository: list<string>, imageOptimizationNewPrice: list<string>, integration: list<string>, integrationAccount: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationRole: list<string>, integrationConfigurationTransfer: list<string>, integrationDeploymentAction: list<string>, integrationEvent: list<string>, integrationLog: list<string>, integrationResource: list<string>, integrationResourceData: list<string>, integrationResourceReplCommand: list<string>, integrationResourceSecrets: list<string>, integrationSSOSession: list<string>, integrationStrict: list<string>, integrationStoreTokenSet: list<string>, integrationVercelConfigurationOverride: list<string>, integrationPullRequest: list<string>, ipBlocking: list<string>, jobGlobal: list<string>, kmsIssuer: list<string>, kmsProjectGrant: list<string>, logDrain: list<string>, marketplaceBillingData: list<string>, marketplaceExperimentationEdgeConfigData: list<string>, marketplaceExperimentationItem: list<string>, marketplaceInstallationMember: list<string>, marketplaceInvoice: list<string>, marketplaceSettings: list<string>, Monitoring: list<string>, monitoringAlert: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, monitoringSettings: list<string>, notificationCustomerBudget: list<string>, notificationDeploymentFailed: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, NotificationMonitoringAlert: list<string>, notificationPaymentFailed: list<string>, notificationPreferences: list<string>, notificationStatementOfReasons: list<string>, notificationUsageAlert: list<string>, oidcFederationPolicy: list<string>, observabilityConfiguration: list<string>, observabilityFunnel: list<string>, observabilityNotebook: list<string>, openTelemetryEndpoint: list<string>, ownEvent: list<string>, organization: list<string>, organizationDomain: list<string>, organizationTeam: list<string>, passwordProtectionInvoiceItem: list<string>, paymentMethod: list<string>, permissions: list<string>, postgres: list<string>, postgresStoreTokenSet: list<string>, previewDeploymentSuffix: list<string>, privateCloudAccount: list<string>, projectTransferIn: list<string>, proTrialOnboarding: list<string>, rateLimit: list<string>, redis: list<string>, redisStoreTokenSet: list<string>, remoteCaching: list<string>, repository: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, space: list<string>, spaceRun: list<string>, storeIsLocked: list<string>, storeTokenSetSensitive: list<string>, storeTransfer: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamGitExclusivity: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamInviteLink: list<string>, teamJoin: list<string>, teamMemberMfaStatus: list<string>, teamMicrofrontends: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, teamSudo: list<string>, teamTokenInvalidation: list<string>, token: list<string>, toolbarComment: list<string>, usage: list<string>, usageCycle: list<string>, vcrRepository: list<string>, vercelRun: list<string>, vpcPeeringConnection: list<string>, webAnalyticsPlan: list<string>, webhook: list<string>, webhook_event: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, bulkRedirects: list<string>, buildMachine: list<string>, connectConfigurationLink: list<string>, dataCacheNamespace: list<string>, deployment: list<string>, deploymentBuildLogs: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentCheckReRunFromProductionBranch: list<string>, deploymentProductionGit: list<string>, deploymentV0: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentPromote: list<string>, deploymentRollback: list<string>, edgeCacheNamespace: list<string>, environments: list<string>, job: list<string>, logs: list<string>, logsPreset: list<string>, observabilityData: list<string>, onDemandBuild: list<string>, onDemandConcurrency: list<string>, optionsAllowlist: list<string>, passwordProtection: list<string>, privateLinkEndpoint: list<string>, productionAliasProtectionBypass: list<string>, project: list<string>, projectAccessGroup: list<string>, projectAnalyticsSampling: list<string>, projectAnalyticsUsage: list<string>, projectCheck: list<string>, projectCheckRun: list<string>, projectDeploymentExpiration: list<string>, projectDeploymentHook: list<string>, projectDeploymentProtectionStrict: list<string>, projectDomain: list<string>, projectDomainCheckConfig: list<string>, projectDomainMove: list<string>, projectEvent: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectFlags: list<string>, projectFlagsProduction: list<string>, projectFlagsSdkKey: list<string>, projectFromV0: list<string>, projectId: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectMonitoring: list<string>, projectOIDCToken: list<string>, projectPermissions: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectRollingRelease: list<string>, projectRoutes: list<string>, projectSupportCase: list<string>, projectSupportCaseComment: list<string>, projectTier: list<string>, projectTransfer: list<string>, projectTransferOut: list<string>, projectUsage: list<string>, pageIntegrity: list<string>, seawallConfig: list<string>, securityPlusConfiguration: list<string>, shareableLinkStrict: list<string>, sharedEnvVarConnection: list<string>, skewProtection: list<string>, analytics: list<string>, trustedIps: list<string>, trustedSources: list<string>, v0Chat: list<string>, webAnalytics: list<string>>, lastRollbackTarget: record, lastAliasRequest: record<fromDeploymentId: string, toDeploymentId: string, fromRollingReleaseId: string, jobStatus: string, requestedAt: float, type: string>, protectionBypass: record, hasActiveBranches: bool, trustedIps: any, trustedSources: record<projects: record, oidcProviders: record>, gitComments: record<onPullRequest: bool, onCommit: bool>, gitProviderOptions: record<createDeployments: string, disableRepositoryDispatchEvents: bool, requireVerifiedCommits: bool, gitCommitStatus: bool, consolidatedGitCommitStatus: record<enabled: bool, propagateFailures: bool>>, paused: bool, concurrencyBucketName: string, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>, security: record<attackModeEnabled: bool, attackModeUpdatedAt: float, firewallEnabled: bool, firewallUpdatedAt: float, attackModeActiveUntil: float, firewallConfigVersion: float, firewallSeawallEnabled: bool, ja3Enabled: bool, ja4Enabled: bool, firewallBypassIps: list<string>, managedRules: record<vercel_ruleset: record, bot_filter: record, ai_bots: record, owasp: record>, botIdEnabled: bool, log_headers: any, securityPlus: bool, securityPlusMetadata: record<updatedAt: float, firstEnabledAt: float>, pageIntegrityEnabled: bool>, oidcTokenConfig: record<enabled: bool, issuerMode: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, tier: string, flatRateTier: string, usageStatus: record<kind: string, exceededAllowanceUntil: float, bypassThrottleUntil: float, throttled: bool>, features: record<webAnalytics: bool>, v0: bool, v0Created: bool, abuse: record<scanner: string, history: list<record>, updatedAt: float, block: record<action: string, reason: string, statusCode: float, createdAt: float, caseId: string, actor: string, comment: string, ineligibleForAppeal: bool, isCascading: bool>, blockHistory: list<any>, interstitial: bool, interstitialHistory: list<record>>, internalRoutes: list<any>, hasDeployments: bool, dismissedToasts: table<key: string, dismissedAt: float, action: string, value: any>, protectedSourcemaps: bool, tracing: record<domains: string, ignorePaths: list<string>, samplingRules: list<record>>, avatar: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v11/projects" $qp)
  let body = {enablePreviewFeedback: $enablePreviewFeedback, enableProductionFeedback: $enableProductionFeedback, previewDeploymentsDisabled: $previewDeploymentsDisabled, previewDeploymentSuffix: $previewDeploymentSuffix, buildCommand: $buildCommand, commandForIgnoringBuildStep: $commandForIgnoringBuildStep, devCommand: $devCommand, environmentVariables: $environmentVariables, framework: $framework, gitRepository: $gitRepository, installCommand: $installCommand, name: $name, skipGitConnectDuringLink: $skipGitConnectDuringLink, ssoProtection: $ssoProtection, outputDirectory: $outputDirectory, publicSource: $publicSource, rootDirectory: $rootDirectory, serverlessFunctionRegion: $serverlessFunctionRegion, serverlessFunctionZeroConfigFailover: $serverlessFunctionZeroConfigFailover, oidcTokenConfig: $oidcTokenConfig, enableAffectedProjectsDeployments: $enableAffectedProjectsDeployments, resourceConfig: $resourceConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find a project by id or name
#
# GET /v9/projects/{idOrName}
# operationId: getProject
export def "projects get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<integrations: table<installationId: string, resources: list>, accountId: string, analytics: record<id: string, canceledAt: float, disabledAt: float, enabledAt: float, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, appliedCve55182Migration: bool, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, autoExposeSystemEnvs: bool, autoAssignCustomDomains: bool, autoAssignCustomDomainsUpdatedBy: string, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurations: table<envId: any, connectConfigurationId: string, dc: string, passive: bool, buildsEnabled: bool, aws: record, createdAt: float, updatedAt: float>, connectConfigurationId: string, connectBuildsEnabled: bool, passiveConnectConfigurationId: string, createdAt: float, customerSupportCodeVisibility: bool, crons: record<enabledAt: float, disabledAt: float, updatedAt: float, deploymentId: string, definitions: list<record>>, dataCache: record<userDisabled: bool, storageSizeBytes: float, unlimited: bool>, deploymentExpiration: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, expiration: any, devCommand: string, directoryListing: bool, installCommand: string, env: table<target: any, type: string, sunsetSecretId: string, legacyValue: string, decrypted: bool, value: string, vsmValue: string, id: string, key: string, configurationId: string, createdAt: float, updatedAt: float, createdBy: string, updatedBy: string, gitBranch: string, edgeConfigId: string, edgeConfigTokenId: string, contentHint: any, internalContentHint: record, comment: string, customEnvironmentIds: list>, customEnvironments: table<id: string, slug: string, type: string, description: string, branchMatcher: record, domains: list, currentDeploymentAliases: list, createdAt: float, updatedAt: float>, framework: string, services: table<serviceName: string, serviceType: string, framework: string, runtime: string>, gitForkProtection: bool, gitLFS: bool, id: string, ipBuckets: table<bucket: string, default: bool, supportUntil: float>, jobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, latestDeployments: table<alias: list, aliasAssigned: any, builds: list, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, name: string, forced: bool, id: string, meta: record, plan: string, private: bool, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, microfrontends: any, name: string, nodeVersion: string, optionsAllowlist: record<paths: list<record>>, outputDirectory: string, passwordProtection: record, passport: record<deploymentType: string, connectorId: string>, protectionConfig: record<sandboxUrls: record<inheritDeploymentProtection: bool>>, productionDeploymentsFastLane: bool, publicSource: bool, resourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rollbackDescription: record<userId: string, username: string, description: string, createdAt: float>, rollingRelease: record<target: string, stages: list<record>, canaryResponseHeader: bool>, defaultResourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rootDirectory: string, serverlessFunctionZeroConfigFailover: bool, skewProtectionBoundaryAt: float, skewProtectionMaxAge: float, skewProtectionAllowedDomains: list<string>, skipGitConnectDuringLink: bool, staticIps: record<builds: bool, enabled: bool, regions: list<string>>, sourceFilesOutsideRootDirectory: bool, enableAffectedProjectsDeployments: bool, enableExternalRewriteCaching: bool, ssoProtection: record<deploymentType: string, cve55182MigrationAppliedFrom: string, april2026SecurityIncidentMigrationAppliedFrom: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float, live: bool, enablePreviewFeedback: bool, enableProductionFeedback: bool, permissions: record<oauth2Connection: list<string>, user: list<string>, userConnection: list<string>, userMfaConfiguration: list<string>, userPreference: list<string>, userSudo: list<string>, webAuthn: list<string>, accessGroup: list<string>, agent: list<string>, aiGatewayUsage: list<string>, alerts: list<string>, alertRules: list<string>, aliasGlobal: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, apiKey: list<string>, apiKeyAiGateway: list<string>, apiKeyOwnedBySelf: list<string>, oauth2Application: list<string>, vercelAppInstallation: list<string>, vercelAppInstallationRequest: list<string>, auditLog: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingRefund: list<string>, billingTaxId: list<string>, blob: list<string>, blobStoreTokenSet: list<string>, budget: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, codeChecks: list<string>, ciInvocations: list<string>, ciLogs: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connexClient: list<string>, connexClientProject: list<string>, connexToken: list<string>, buildMachineDefault: list<string>, dataCacheBillingSettings: list<string>, defaultDeploymentProtection: list<string>, deploymentPolicy: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, drain: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigSchema: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, flagsExplorerSubscription: list<string>, gitRepository: list<string>, imageOptimizationNewPrice: list<string>, integration: list<string>, integrationAccount: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationRole: list<string>, integrationConfigurationTransfer: list<string>, integrationDeploymentAction: list<string>, integrationEvent: list<string>, integrationLog: list<string>, integrationResource: list<string>, integrationResourceData: list<string>, integrationResourceReplCommand: list<string>, integrationResourceSecrets: list<string>, integrationSSOSession: list<string>, integrationStrict: list<string>, integrationStoreTokenSet: list<string>, integrationVercelConfigurationOverride: list<string>, integrationPullRequest: list<string>, ipBlocking: list<string>, jobGlobal: list<string>, kmsIssuer: list<string>, kmsProjectGrant: list<string>, logDrain: list<string>, marketplaceBillingData: list<string>, marketplaceExperimentationEdgeConfigData: list<string>, marketplaceExperimentationItem: list<string>, marketplaceInstallationMember: list<string>, marketplaceInvoice: list<string>, marketplaceSettings: list<string>, Monitoring: list<string>, monitoringAlert: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, monitoringSettings: list<string>, notificationCustomerBudget: list<string>, notificationDeploymentFailed: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, NotificationMonitoringAlert: list<string>, notificationPaymentFailed: list<string>, notificationPreferences: list<string>, notificationStatementOfReasons: list<string>, notificationUsageAlert: list<string>, oidcFederationPolicy: list<string>, observabilityConfiguration: list<string>, observabilityFunnel: list<string>, observabilityNotebook: list<string>, openTelemetryEndpoint: list<string>, ownEvent: list<string>, organization: list<string>, organizationDomain: list<string>, organizationTeam: list<string>, passwordProtectionInvoiceItem: list<string>, paymentMethod: list<string>, permissions: list<string>, postgres: list<string>, postgresStoreTokenSet: list<string>, previewDeploymentSuffix: list<string>, privateCloudAccount: list<string>, projectTransferIn: list<string>, proTrialOnboarding: list<string>, rateLimit: list<string>, redis: list<string>, redisStoreTokenSet: list<string>, remoteCaching: list<string>, repository: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, space: list<string>, spaceRun: list<string>, storeIsLocked: list<string>, storeTokenSetSensitive: list<string>, storeTransfer: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamGitExclusivity: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamInviteLink: list<string>, teamJoin: list<string>, teamMemberMfaStatus: list<string>, teamMicrofrontends: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, teamSudo: list<string>, teamTokenInvalidation: list<string>, token: list<string>, toolbarComment: list<string>, usage: list<string>, usageCycle: list<string>, vcrRepository: list<string>, vercelRun: list<string>, vpcPeeringConnection: list<string>, webAnalyticsPlan: list<string>, webhook: list<string>, webhook_event: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, bulkRedirects: list<string>, buildMachine: list<string>, connectConfigurationLink: list<string>, dataCacheNamespace: list<string>, deployment: list<string>, deploymentBuildLogs: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentCheckReRunFromProductionBranch: list<string>, deploymentProductionGit: list<string>, deploymentV0: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentPromote: list<string>, deploymentRollback: list<string>, edgeCacheNamespace: list<string>, environments: list<string>, job: list<string>, logs: list<string>, logsPreset: list<string>, observabilityData: list<string>, onDemandBuild: list<string>, onDemandConcurrency: list<string>, optionsAllowlist: list<string>, passwordProtection: list<string>, privateLinkEndpoint: list<string>, productionAliasProtectionBypass: list<string>, project: list<string>, projectAccessGroup: list<string>, projectAnalyticsSampling: list<string>, projectAnalyticsUsage: list<string>, projectCheck: list<string>, projectCheckRun: list<string>, projectDeploymentExpiration: list<string>, projectDeploymentHook: list<string>, projectDeploymentProtectionStrict: list<string>, projectDomain: list<string>, projectDomainCheckConfig: list<string>, projectDomainMove: list<string>, projectEvent: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectFlags: list<string>, projectFlagsProduction: list<string>, projectFlagsSdkKey: list<string>, projectFromV0: list<string>, projectId: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectMonitoring: list<string>, projectOIDCToken: list<string>, projectPermissions: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectRollingRelease: list<string>, projectRoutes: list<string>, projectSupportCase: list<string>, projectSupportCaseComment: list<string>, projectTier: list<string>, projectTransfer: list<string>, projectTransferOut: list<string>, projectUsage: list<string>, pageIntegrity: list<string>, seawallConfig: list<string>, securityPlusConfiguration: list<string>, shareableLinkStrict: list<string>, sharedEnvVarConnection: list<string>, skewProtection: list<string>, analytics: list<string>, trustedIps: list<string>, trustedSources: list<string>, v0Chat: list<string>, webAnalytics: list<string>>, lastRollbackTarget: record, lastAliasRequest: record<fromDeploymentId: string, toDeploymentId: string, fromRollingReleaseId: string, jobStatus: string, requestedAt: float, type: string>, protectionBypass: record, hasActiveBranches: bool, trustedIps: any, trustedSources: record<projects: record, oidcProviders: record>, gitComments: record<onPullRequest: bool, onCommit: bool>, gitProviderOptions: record<createDeployments: string, disableRepositoryDispatchEvents: bool, requireVerifiedCommits: bool, gitCommitStatus: bool, consolidatedGitCommitStatus: record<enabled: bool, propagateFailures: bool>>, paused: bool, concurrencyBucketName: string, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>, security: record<attackModeEnabled: bool, attackModeUpdatedAt: float, firewallEnabled: bool, firewallUpdatedAt: float, attackModeActiveUntil: float, firewallConfigVersion: float, firewallSeawallEnabled: bool, ja3Enabled: bool, ja4Enabled: bool, firewallBypassIps: list<string>, managedRules: record<vercel_ruleset: record, bot_filter: record, ai_bots: record, owasp: record>, botIdEnabled: bool, log_headers: any, securityPlus: bool, securityPlusMetadata: record<updatedAt: float, firstEnabledAt: float>, pageIntegrityEnabled: bool>, oidcTokenConfig: record<enabled: bool, issuerMode: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, tier: string, flatRateTier: string, usageStatus: record<kind: string, exceededAllowanceUntil: float, bypassThrottleUntil: float, throttled: bool>, features: record<webAnalytics: bool>, v0: bool, v0Created: bool, abuse: record<scanner: string, history: list<record>, updatedAt: float, block: record<action: string, reason: string, statusCode: float, createdAt: float, caseId: string, actor: string, comment: string, ineligibleForAppeal: bool, isCascading: bool>, blockHistory: list<any>, interstitial: bool, interstitialHistory: list<record>>, internalRoutes: list<any>, hasDeployments: bool, dismissedToasts: table<key: string, dismissedAt: float, action: string, value: any>, protectedSourcemaps: bool, tracing: record<domains: string, ignorePaths: list<string>, samplingRules: list<record>>, avatar: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing project
#
# PATCH /v9/projects/{idOrName}
# operationId: updateProject
# --resourceConfig shape: {buildMachineType?: ""|"enhanced"|"turbo"|"standard"|"elastic", buildQueue?: record, fluid?: bool, functionDefaultRegions?: list, functionDefaultTimeout?: float, functionDefaultMemoryType?: "standard_legacy"|"standard"|"performance", functionZeroConfigFailover?: any, elasticConcurrencyEnabled?: bool, buildMachineSelection?: "elastic"|"fixed", buildMachineElasticLastUpdated?: float, isNSNBDisabled?: bool, enableFunctionsBeta?: bool}
# --staticIps shape: {enabled: bool}
# --tracing shape: {domains?: string, ignorePaths?: list, samplingRules?: list}
# --oidcTokenConfig shape: {enabled?: bool, issuerMode?: "team"|"global"}
# --passwordProtection shape: {deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains", password?: string}
# --passport shape: {connectorId: string, deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
# --ssoProtection shape: {deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
# --trustedIps shape: {deploymentType: "all"|"preview"|"production"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains", addresses: list, protectionMode: "exclusive"|"additional"}
# --trustedSources shape: {projects?: record, oidcProviders?: record}
# --optionsAllowlist shape: {paths: list}
# --connectConfigurations item shape: {envId: string, connectConfigurationId: string, passive: bool, buildsEnabled: bool}
# --dismissedToasts item shape: {key: string, dismissedAt: float, action: "cancel"|"accept"|"delete", value: any}
@deprecated --flag skipGitConnectDuringLink
export def "projects updateProject" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --autoExposeSystemEnvs: string@bool-completer
  --autoAssignCustomDomains: string@bool-completer
  --autoAssignCustomDomainsUpdatedBy: string
  --buildCommand: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --commandForIgnoringBuildStep: string # nullable
  --customerSupportCodeVisibility: string@bool-completer # Specifies whether customer support can see git source for a deployment
  --devCommand: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --directoryListing: string@bool-completer
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --gitForkProtection: string@bool-completer # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --gitLFS: string@bool-completer # Specifies whether Git LFS is enabled for this project.
  --protectedSourcemaps: string@bool-completer # Specifies whether sourcemaps are protected and require authentication to access.
  --installCommand: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --name: string # The desired name for the project (e.g. a-project-name)
  --nodeVersion: string@nodeVersion-completer
  --outputDirectory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --previewDeploymentsDisabled: string@bool-completer # Specifies whether preview deployments are disabled for this project. (nullable)
  --previewDeploymentSuffix: string # Custom domain suffix for preview deployments. Takes precedence over team-level suffix. Must be a domain owned by the team. (nullable)
  --publicSource: string@bool-completer # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --resourceConfig: record # Specifies resource override configuration for the project — shape: {buildMachineType?: ""|"enhanced"|"turbo"|"standard"|"elastic", buildQueue?: record, fluid?: bool, functionDefaultRegions?: list, functionDefaultTimeout?: float, functionDefaultMemoryType?: "standard_legacy"|"standard"|"performance", functionZeroConfigFailover?: any, elasticConcurrencyEnabled?: bool, buildMachineSelection?: "elastic"|"fixed", buildMachineElasticLastUpdated?: float, isNSNBDisabled?: bool, enableFunctionsBeta?: bool}
  --rootDirectory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverlessFunctionRegion: string # The region to deploy Serverless Functions in this project (nullable)
  --serverlessFunctionZeroConfigFailover: any # Specifies whether Zero Config Failover is enabled for this project.
  --skewProtectionBoundaryAt: int # Deployments created before this absolute datetime have Skew Protection disabled. Value is in milliseconds since epoch to match \"createdAt\" fields.
  --skewProtectionMaxAge: int # Deployments created before this rolling window have Skew Protection disabled. Value is in seconds to match \"revalidate\" fields.
  --skewProtectionAllowedDomains: list # Cross-site domains allowed to fetch skew-protected assets (hostnames, optionally with leading wildcard like *.example.com).
  --skipGitConnectDuringLink: string@bool-completer # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
  --sourceFilesOutsideRootDirectory: string@bool-completer # Indicates if there are source files outside of the root directory
  --enablePreviewFeedback: string@bool-completer # Opt-in to preview toolbar on the project level (nullable)
  --enableProductionFeedback: string@bool-completer # Opt-in to production toolbar on the project level (nullable)
  --enableAffectedProjectsDeployments: string@bool-completer # Opt-in to skip deployments when there are no changes to the root directory and its dependencies
  --enableExternalRewriteCaching: string@bool-completer # Specifies whether external rewrite caching is enabled for this project.
  --staticIps: record # Manage Static IPs for this project — shape: {enabled: bool}
  --tracing: record # Tracing configuration for this project (nullable) — shape: {domains?: string, ignorePaths?: list, samplingRules?: list}
  --oidcTokenConfig: record # OpenID Connect JSON Web Token generation configuration. — shape: {enabled?: bool, issuerMode?: "team"|"global"}
  --passwordProtection: record # Allows to protect project deployments with a password (nullable) — shape: {deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains", password?: string}
  --passport: record # Passport configuration for the project. (nullable) — shape: {connectorId: string, deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
  --ssoProtection: record # Ensures visitors to your Preview Deployments are logged into Vercel and have a minimum of Viewer access on your team (nullable) — shape: {deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
  --trustedIps: record # Restricts access to deployments based on the incoming request IP address (nullable) — shape: {deploymentType: "all"|"preview"|"production"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains", addresses: list, protectionMode: "exclusive"|"additional"}
  --trustedSources: record # Deployment Protection Trusted Sources (nullable) — shape: {projects?: record, oidcProviders?: record}
  --deploymentPolicy: any
  --optionsAllowlist: record # Specify a list of paths that should not be protected by Deployment Protection to enable Cors preflight requests (nullable) — shape: {paths: list}
  --connectConfigurations: list # The list of connections from project environment to Secure Compute network (nullable) — item shape: {envId: string, connectConfigurationId: string, passive: bool, buildsEnabled: bool}
  --dismissedToasts: list # An array of objects representing a Dismissed Toast in regards to a Project. Objects are either merged with existing toasts (on key match), or added to the `dimissedToasts` array.` — item shape: {key: string, dismissedAt: float, action: "cancel"|"accept"|"delete", value: any}
]: any -> record<accountId: string, analytics: record<id: string, canceledAt: float, disabledAt: float, enabledAt: float, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, appliedCve55182Migration: bool, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, autoExposeSystemEnvs: bool, autoAssignCustomDomains: bool, autoAssignCustomDomainsUpdatedBy: string, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurations: table<envId: any, connectConfigurationId: string, dc: string, passive: bool, buildsEnabled: bool, aws: record, createdAt: float, updatedAt: float>, connectConfigurationId: string, connectBuildsEnabled: bool, passiveConnectConfigurationId: string, createdAt: float, customerSupportCodeVisibility: bool, crons: record<enabledAt: float, disabledAt: float, updatedAt: float, deploymentId: string, definitions: list<record>>, dataCache: record<userDisabled: bool, storageSizeBytes: float, unlimited: bool>, deploymentExpiration: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, expiration: any, devCommand: string, directoryListing: bool, installCommand: string, env: table<target: any, type: string, sunsetSecretId: string, legacyValue: string, decrypted: bool, value: string, vsmValue: string, id: string, key: string, configurationId: string, createdAt: float, updatedAt: float, createdBy: string, updatedBy: string, gitBranch: string, edgeConfigId: string, edgeConfigTokenId: string, contentHint: any, internalContentHint: record, comment: string, customEnvironmentIds: list>, customEnvironments: table<id: string, slug: string, type: string, description: string, branchMatcher: record, domains: list, currentDeploymentAliases: list, createdAt: float, updatedAt: float>, framework: string, services: table<serviceName: string, serviceType: string, framework: string, runtime: string>, gitForkProtection: bool, gitLFS: bool, id: string, ipBuckets: table<bucket: string, default: bool, supportUntil: float>, jobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, latestDeployments: table<alias: list, aliasAssigned: any, builds: list, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, name: string, forced: bool, id: string, meta: record, plan: string, private: bool, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, microfrontends: any, name: string, nodeVersion: string, optionsAllowlist: record<paths: list<record>>, outputDirectory: string, passwordProtection: record, passport: record<deploymentType: string, connectorId: string>, protectionConfig: record<sandboxUrls: record<inheritDeploymentProtection: bool>>, productionDeploymentsFastLane: bool, publicSource: bool, resourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rollbackDescription: record<userId: string, username: string, description: string, createdAt: float>, rollingRelease: record<target: string, stages: list<record>, canaryResponseHeader: bool>, defaultResourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rootDirectory: string, serverlessFunctionZeroConfigFailover: bool, skewProtectionBoundaryAt: float, skewProtectionMaxAge: float, skewProtectionAllowedDomains: list<string>, skipGitConnectDuringLink: bool, staticIps: record<builds: bool, enabled: bool, regions: list<string>>, sourceFilesOutsideRootDirectory: bool, enableAffectedProjectsDeployments: bool, enableExternalRewriteCaching: bool, ssoProtection: record<deploymentType: string, cve55182MigrationAppliedFrom: string, april2026SecurityIncidentMigrationAppliedFrom: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float, live: bool, enablePreviewFeedback: bool, enableProductionFeedback: bool, permissions: record<oauth2Connection: list<string>, user: list<string>, userConnection: list<string>, userMfaConfiguration: list<string>, userPreference: list<string>, userSudo: list<string>, webAuthn: list<string>, accessGroup: list<string>, agent: list<string>, aiGatewayUsage: list<string>, alerts: list<string>, alertRules: list<string>, aliasGlobal: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, apiKey: list<string>, apiKeyAiGateway: list<string>, apiKeyOwnedBySelf: list<string>, oauth2Application: list<string>, vercelAppInstallation: list<string>, vercelAppInstallationRequest: list<string>, auditLog: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingRefund: list<string>, billingTaxId: list<string>, blob: list<string>, blobStoreTokenSet: list<string>, budget: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, codeChecks: list<string>, ciInvocations: list<string>, ciLogs: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connexClient: list<string>, connexClientProject: list<string>, connexToken: list<string>, buildMachineDefault: list<string>, dataCacheBillingSettings: list<string>, defaultDeploymentProtection: list<string>, deploymentPolicy: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, drain: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigSchema: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, flagsExplorerSubscription: list<string>, gitRepository: list<string>, imageOptimizationNewPrice: list<string>, integration: list<string>, integrationAccount: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationRole: list<string>, integrationConfigurationTransfer: list<string>, integrationDeploymentAction: list<string>, integrationEvent: list<string>, integrationLog: list<string>, integrationResource: list<string>, integrationResourceData: list<string>, integrationResourceReplCommand: list<string>, integrationResourceSecrets: list<string>, integrationSSOSession: list<string>, integrationStrict: list<string>, integrationStoreTokenSet: list<string>, integrationVercelConfigurationOverride: list<string>, integrationPullRequest: list<string>, ipBlocking: list<string>, jobGlobal: list<string>, kmsIssuer: list<string>, kmsProjectGrant: list<string>, logDrain: list<string>, marketplaceBillingData: list<string>, marketplaceExperimentationEdgeConfigData: list<string>, marketplaceExperimentationItem: list<string>, marketplaceInstallationMember: list<string>, marketplaceInvoice: list<string>, marketplaceSettings: list<string>, Monitoring: list<string>, monitoringAlert: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, monitoringSettings: list<string>, notificationCustomerBudget: list<string>, notificationDeploymentFailed: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, NotificationMonitoringAlert: list<string>, notificationPaymentFailed: list<string>, notificationPreferences: list<string>, notificationStatementOfReasons: list<string>, notificationUsageAlert: list<string>, oidcFederationPolicy: list<string>, observabilityConfiguration: list<string>, observabilityFunnel: list<string>, observabilityNotebook: list<string>, openTelemetryEndpoint: list<string>, ownEvent: list<string>, organization: list<string>, organizationDomain: list<string>, organizationTeam: list<string>, passwordProtectionInvoiceItem: list<string>, paymentMethod: list<string>, permissions: list<string>, postgres: list<string>, postgresStoreTokenSet: list<string>, previewDeploymentSuffix: list<string>, privateCloudAccount: list<string>, projectTransferIn: list<string>, proTrialOnboarding: list<string>, rateLimit: list<string>, redis: list<string>, redisStoreTokenSet: list<string>, remoteCaching: list<string>, repository: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, space: list<string>, spaceRun: list<string>, storeIsLocked: list<string>, storeTokenSetSensitive: list<string>, storeTransfer: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamGitExclusivity: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamInviteLink: list<string>, teamJoin: list<string>, teamMemberMfaStatus: list<string>, teamMicrofrontends: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, teamSudo: list<string>, teamTokenInvalidation: list<string>, token: list<string>, toolbarComment: list<string>, usage: list<string>, usageCycle: list<string>, vcrRepository: list<string>, vercelRun: list<string>, vpcPeeringConnection: list<string>, webAnalyticsPlan: list<string>, webhook: list<string>, webhook_event: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, bulkRedirects: list<string>, buildMachine: list<string>, connectConfigurationLink: list<string>, dataCacheNamespace: list<string>, deployment: list<string>, deploymentBuildLogs: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentCheckReRunFromProductionBranch: list<string>, deploymentProductionGit: list<string>, deploymentV0: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentPromote: list<string>, deploymentRollback: list<string>, edgeCacheNamespace: list<string>, environments: list<string>, job: list<string>, logs: list<string>, logsPreset: list<string>, observabilityData: list<string>, onDemandBuild: list<string>, onDemandConcurrency: list<string>, optionsAllowlist: list<string>, passwordProtection: list<string>, privateLinkEndpoint: list<string>, productionAliasProtectionBypass: list<string>, project: list<string>, projectAccessGroup: list<string>, projectAnalyticsSampling: list<string>, projectAnalyticsUsage: list<string>, projectCheck: list<string>, projectCheckRun: list<string>, projectDeploymentExpiration: list<string>, projectDeploymentHook: list<string>, projectDeploymentProtectionStrict: list<string>, projectDomain: list<string>, projectDomainCheckConfig: list<string>, projectDomainMove: list<string>, projectEvent: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectFlags: list<string>, projectFlagsProduction: list<string>, projectFlagsSdkKey: list<string>, projectFromV0: list<string>, projectId: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectMonitoring: list<string>, projectOIDCToken: list<string>, projectPermissions: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectRollingRelease: list<string>, projectRoutes: list<string>, projectSupportCase: list<string>, projectSupportCaseComment: list<string>, projectTier: list<string>, projectTransfer: list<string>, projectTransferOut: list<string>, projectUsage: list<string>, pageIntegrity: list<string>, seawallConfig: list<string>, securityPlusConfiguration: list<string>, shareableLinkStrict: list<string>, sharedEnvVarConnection: list<string>, skewProtection: list<string>, analytics: list<string>, trustedIps: list<string>, trustedSources: list<string>, v0Chat: list<string>, webAnalytics: list<string>>, lastRollbackTarget: record, lastAliasRequest: record<fromDeploymentId: string, toDeploymentId: string, fromRollingReleaseId: string, jobStatus: string, requestedAt: float, type: string>, protectionBypass: record, hasActiveBranches: bool, trustedIps: any, trustedSources: record<projects: record, oidcProviders: record>, gitComments: record<onPullRequest: bool, onCommit: bool>, gitProviderOptions: record<createDeployments: string, disableRepositoryDispatchEvents: bool, requireVerifiedCommits: bool, gitCommitStatus: bool, consolidatedGitCommitStatus: record<enabled: bool, propagateFailures: bool>>, paused: bool, concurrencyBucketName: string, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>, security: record<attackModeEnabled: bool, attackModeUpdatedAt: float, firewallEnabled: bool, firewallUpdatedAt: float, attackModeActiveUntil: float, firewallConfigVersion: float, firewallSeawallEnabled: bool, ja3Enabled: bool, ja4Enabled: bool, firewallBypassIps: list<string>, managedRules: record<vercel_ruleset: record, bot_filter: record, ai_bots: record, owasp: record>, botIdEnabled: bool, log_headers: any, securityPlus: bool, securityPlusMetadata: record<updatedAt: float, firstEnabledAt: float>, pageIntegrityEnabled: bool>, oidcTokenConfig: record<enabled: bool, issuerMode: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, tier: string, flatRateTier: string, usageStatus: record<kind: string, exceededAllowanceUntil: float, bypassThrottleUntil: float, throttled: bool>, features: record<webAnalytics: bool>, v0: bool, v0Created: bool, abuse: record<scanner: string, history: list<record>, updatedAt: float, block: record<action: string, reason: string, statusCode: float, createdAt: float, caseId: string, actor: string, comment: string, ineligibleForAppeal: bool, isCascading: bool>, blockHistory: list<any>, interstitial: bool, interstitialHistory: list<record>>, internalRoutes: list<any>, hasDeployments: bool, dismissedToasts: table<key: string, dismissedAt: float, action: string, value: any>, protectedSourcemaps: bool, tracing: record<domains: string, ignorePaths: list<string>, samplingRules: list<record>>, avatar: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)" $qp)
  let body = {autoExposeSystemEnvs: $autoExposeSystemEnvs, autoAssignCustomDomains: $autoAssignCustomDomains, autoAssignCustomDomainsUpdatedBy: $autoAssignCustomDomainsUpdatedBy, buildCommand: $buildCommand, commandForIgnoringBuildStep: $commandForIgnoringBuildStep, customerSupportCodeVisibility: $customerSupportCodeVisibility, devCommand: $devCommand, directoryListing: $directoryListing, framework: $framework, gitForkProtection: $gitForkProtection, gitLFS: $gitLFS, protectedSourcemaps: $protectedSourcemaps, installCommand: $installCommand, name: $name, nodeVersion: $nodeVersion, outputDirectory: $outputDirectory, previewDeploymentsDisabled: $previewDeploymentsDisabled, previewDeploymentSuffix: $previewDeploymentSuffix, publicSource: $publicSource, resourceConfig: $resourceConfig, rootDirectory: $rootDirectory, serverlessFunctionRegion: $serverlessFunctionRegion, serverlessFunctionZeroConfigFailover: $serverlessFunctionZeroConfigFailover, skewProtectionBoundaryAt: $skewProtectionBoundaryAt, skewProtectionMaxAge: $skewProtectionMaxAge, skewProtectionAllowedDomains: $skewProtectionAllowedDomains, skipGitConnectDuringLink: $skipGitConnectDuringLink, sourceFilesOutsideRootDirectory: $sourceFilesOutsideRootDirectory, enablePreviewFeedback: $enablePreviewFeedback, enableProductionFeedback: $enableProductionFeedback, enableAffectedProjectsDeployments: $enableAffectedProjectsDeployments, enableExternalRewriteCaching: $enableExternalRewriteCaching, staticIps: $staticIps, tracing: $tracing, oidcTokenConfig: $oidcTokenConfig, passwordProtection: $passwordProtection, passport: $passport, ssoProtection: $ssoProtection, trustedIps: $trustedIps, trustedSources: $trustedSources, deploymentPolicy: $deploymentPolicy, optionsAllowlist: $optionsAllowlist, connectConfigurations: $connectConfigurations, dismissedToasts: $dismissedToasts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Project
#
# DELETE /v9/projects/{idOrName}
# operationId: deleteProject
export def "projects delete" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a project avatar
#
# POST /v1/projects/{idOrName}/avatar
# operationId: uploadProjectAvatar
export def "projects-avatar uploadProjectAvatar" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --body: record
]: any -> record<accountId: string, analytics: record<id: string, canceledAt: float, disabledAt: float, enabledAt: float, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, appliedCve55182Migration: bool, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, autoExposeSystemEnvs: bool, autoAssignCustomDomains: bool, autoAssignCustomDomainsUpdatedBy: string, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurations: table<envId: any, connectConfigurationId: string, dc: string, passive: bool, buildsEnabled: bool, aws: record, createdAt: float, updatedAt: float>, connectConfigurationId: string, connectBuildsEnabled: bool, passiveConnectConfigurationId: string, createdAt: float, customerSupportCodeVisibility: bool, crons: record<enabledAt: float, disabledAt: float, updatedAt: float, deploymentId: string, definitions: list<record>>, dataCache: record<userDisabled: bool, storageSizeBytes: float, unlimited: bool>, deploymentExpiration: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, expiration: any, devCommand: string, directoryListing: bool, installCommand: string, env: table<target: any, type: string, sunsetSecretId: string, legacyValue: string, decrypted: bool, value: string, vsmValue: string, id: string, key: string, configurationId: string, createdAt: float, updatedAt: float, createdBy: string, updatedBy: string, gitBranch: string, edgeConfigId: string, edgeConfigTokenId: string, contentHint: any, internalContentHint: record, comment: string, customEnvironmentIds: list>, customEnvironments: table<id: string, slug: string, type: string, description: string, branchMatcher: record, domains: list, currentDeploymentAliases: list, createdAt: float, updatedAt: float>, framework: string, services: table<serviceName: string, serviceType: string, framework: string, runtime: string>, gitForkProtection: bool, gitLFS: bool, id: string, ipBuckets: table<bucket: string, default: bool, supportUntil: float>, jobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, latestDeployments: table<alias: list, aliasAssigned: any, builds: list, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, name: string, forced: bool, id: string, meta: record, plan: string, private: bool, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, microfrontends: any, name: string, nodeVersion: string, optionsAllowlist: record<paths: list<record>>, outputDirectory: string, passwordProtection: record, passport: record<deploymentType: string, connectorId: string>, protectionConfig: record<sandboxUrls: record<inheritDeploymentProtection: bool>>, productionDeploymentsFastLane: bool, publicSource: bool, resourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rollbackDescription: record<userId: string, username: string, description: string, createdAt: float>, rollingRelease: record<target: string, stages: list<record>, canaryResponseHeader: bool>, defaultResourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rootDirectory: string, serverlessFunctionZeroConfigFailover: bool, skewProtectionBoundaryAt: float, skewProtectionMaxAge: float, skewProtectionAllowedDomains: list<string>, skipGitConnectDuringLink: bool, staticIps: record<builds: bool, enabled: bool, regions: list<string>>, sourceFilesOutsideRootDirectory: bool, enableAffectedProjectsDeployments: bool, enableExternalRewriteCaching: bool, ssoProtection: record<deploymentType: string, cve55182MigrationAppliedFrom: string, april2026SecurityIncidentMigrationAppliedFrom: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float, live: bool, enablePreviewFeedback: bool, enableProductionFeedback: bool, permissions: record<oauth2Connection: list<string>, user: list<string>, userConnection: list<string>, userMfaConfiguration: list<string>, userPreference: list<string>, userSudo: list<string>, webAuthn: list<string>, accessGroup: list<string>, agent: list<string>, aiGatewayUsage: list<string>, alerts: list<string>, alertRules: list<string>, aliasGlobal: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, apiKey: list<string>, apiKeyAiGateway: list<string>, apiKeyOwnedBySelf: list<string>, oauth2Application: list<string>, vercelAppInstallation: list<string>, vercelAppInstallationRequest: list<string>, auditLog: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingRefund: list<string>, billingTaxId: list<string>, blob: list<string>, blobStoreTokenSet: list<string>, budget: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, codeChecks: list<string>, ciInvocations: list<string>, ciLogs: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connexClient: list<string>, connexClientProject: list<string>, connexToken: list<string>, buildMachineDefault: list<string>, dataCacheBillingSettings: list<string>, defaultDeploymentProtection: list<string>, deploymentPolicy: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, drain: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigSchema: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, flagsExplorerSubscription: list<string>, gitRepository: list<string>, imageOptimizationNewPrice: list<string>, integration: list<string>, integrationAccount: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationRole: list<string>, integrationConfigurationTransfer: list<string>, integrationDeploymentAction: list<string>, integrationEvent: list<string>, integrationLog: list<string>, integrationResource: list<string>, integrationResourceData: list<string>, integrationResourceReplCommand: list<string>, integrationResourceSecrets: list<string>, integrationSSOSession: list<string>, integrationStrict: list<string>, integrationStoreTokenSet: list<string>, integrationVercelConfigurationOverride: list<string>, integrationPullRequest: list<string>, ipBlocking: list<string>, jobGlobal: list<string>, kmsIssuer: list<string>, kmsProjectGrant: list<string>, logDrain: list<string>, marketplaceBillingData: list<string>, marketplaceExperimentationEdgeConfigData: list<string>, marketplaceExperimentationItem: list<string>, marketplaceInstallationMember: list<string>, marketplaceInvoice: list<string>, marketplaceSettings: list<string>, Monitoring: list<string>, monitoringAlert: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, monitoringSettings: list<string>, notificationCustomerBudget: list<string>, notificationDeploymentFailed: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, NotificationMonitoringAlert: list<string>, notificationPaymentFailed: list<string>, notificationPreferences: list<string>, notificationStatementOfReasons: list<string>, notificationUsageAlert: list<string>, oidcFederationPolicy: list<string>, observabilityConfiguration: list<string>, observabilityFunnel: list<string>, observabilityNotebook: list<string>, openTelemetryEndpoint: list<string>, ownEvent: list<string>, organization: list<string>, organizationDomain: list<string>, organizationTeam: list<string>, passwordProtectionInvoiceItem: list<string>, paymentMethod: list<string>, permissions: list<string>, postgres: list<string>, postgresStoreTokenSet: list<string>, previewDeploymentSuffix: list<string>, privateCloudAccount: list<string>, projectTransferIn: list<string>, proTrialOnboarding: list<string>, rateLimit: list<string>, redis: list<string>, redisStoreTokenSet: list<string>, remoteCaching: list<string>, repository: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, space: list<string>, spaceRun: list<string>, storeIsLocked: list<string>, storeTokenSetSensitive: list<string>, storeTransfer: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamGitExclusivity: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamInviteLink: list<string>, teamJoin: list<string>, teamMemberMfaStatus: list<string>, teamMicrofrontends: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, teamSudo: list<string>, teamTokenInvalidation: list<string>, token: list<string>, toolbarComment: list<string>, usage: list<string>, usageCycle: list<string>, vcrRepository: list<string>, vercelRun: list<string>, vpcPeeringConnection: list<string>, webAnalyticsPlan: list<string>, webhook: list<string>, webhook_event: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, bulkRedirects: list<string>, buildMachine: list<string>, connectConfigurationLink: list<string>, dataCacheNamespace: list<string>, deployment: list<string>, deploymentBuildLogs: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentCheckReRunFromProductionBranch: list<string>, deploymentProductionGit: list<string>, deploymentV0: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentPromote: list<string>, deploymentRollback: list<string>, edgeCacheNamespace: list<string>, environments: list<string>, job: list<string>, logs: list<string>, logsPreset: list<string>, observabilityData: list<string>, onDemandBuild: list<string>, onDemandConcurrency: list<string>, optionsAllowlist: list<string>, passwordProtection: list<string>, privateLinkEndpoint: list<string>, productionAliasProtectionBypass: list<string>, project: list<string>, projectAccessGroup: list<string>, projectAnalyticsSampling: list<string>, projectAnalyticsUsage: list<string>, projectCheck: list<string>, projectCheckRun: list<string>, projectDeploymentExpiration: list<string>, projectDeploymentHook: list<string>, projectDeploymentProtectionStrict: list<string>, projectDomain: list<string>, projectDomainCheckConfig: list<string>, projectDomainMove: list<string>, projectEvent: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectFlags: list<string>, projectFlagsProduction: list<string>, projectFlagsSdkKey: list<string>, projectFromV0: list<string>, projectId: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectMonitoring: list<string>, projectOIDCToken: list<string>, projectPermissions: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectRollingRelease: list<string>, projectRoutes: list<string>, projectSupportCase: list<string>, projectSupportCaseComment: list<string>, projectTier: list<string>, projectTransfer: list<string>, projectTransferOut: list<string>, projectUsage: list<string>, pageIntegrity: list<string>, seawallConfig: list<string>, securityPlusConfiguration: list<string>, shareableLinkStrict: list<string>, sharedEnvVarConnection: list<string>, skewProtection: list<string>, analytics: list<string>, trustedIps: list<string>, trustedSources: list<string>, v0Chat: list<string>, webAnalytics: list<string>>, lastRollbackTarget: record, lastAliasRequest: record<fromDeploymentId: string, toDeploymentId: string, fromRollingReleaseId: string, jobStatus: string, requestedAt: float, type: string>, protectionBypass: record, hasActiveBranches: bool, trustedIps: any, trustedSources: record<projects: record, oidcProviders: record>, gitComments: record<onPullRequest: bool, onCommit: bool>, gitProviderOptions: record<createDeployments: string, disableRepositoryDispatchEvents: bool, requireVerifiedCommits: bool, gitCommitStatus: bool, consolidatedGitCommitStatus: record<enabled: bool, propagateFailures: bool>>, paused: bool, concurrencyBucketName: string, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>, security: record<attackModeEnabled: bool, attackModeUpdatedAt: float, firewallEnabled: bool, firewallUpdatedAt: float, attackModeActiveUntil: float, firewallConfigVersion: float, firewallSeawallEnabled: bool, ja3Enabled: bool, ja4Enabled: bool, firewallBypassIps: list<string>, managedRules: record<vercel_ruleset: record, bot_filter: record, ai_bots: record, owasp: record>, botIdEnabled: bool, log_headers: any, securityPlus: bool, securityPlusMetadata: record<updatedAt: float, firstEnabledAt: float>, pageIntegrityEnabled: bool>, oidcTokenConfig: record<enabled: bool, issuerMode: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, tier: string, flatRateTier: string, usageStatus: record<kind: string, exceededAllowanceUntil: float, bypassThrottleUntil: float, throttled: bool>, features: record<webAnalytics: bool>, v0: bool, v0Created: bool, abuse: record<scanner: string, history: list<record>, updatedAt: float, block: record<action: string, reason: string, statusCode: float, createdAt: float, caseId: string, actor: string, comment: string, ineligibleForAppeal: bool, isCascading: bool>, blockHistory: list<any>, interstitial: bool, interstitialHistory: list<record>>, internalRoutes: list<any>, hasDeployments: bool, dismissedToasts: table<key: string, dismissedAt: float, action: string, value: any>, protectedSourcemaps: bool, tracing: record<domains: string, ignorePaths: list<string>, samplingRules: list<record>>, avatar: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/avatar" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Configures Static IPs for a project
#
# PATCH /v1/projects/{idOrName}/shared-connect-links
# operationId: updateStaticIps
export def "projects-shared-connect-links updateStaticIps" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --builds: string@bool-completer # Whether to use Static IPs for builds.
  --regions: list
]: any -> table<envId: any, connectConfigurationId: string, dc: string, passive: bool, buildsEnabled: bool, aws: record<subnetIds: list, securityGroupId: string>, createdAt: float, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/shared-connect-links" $qp)
  let body = {builds: $builds, regions: $regions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a custom environment for the current project.
#
# POST /v9/projects/{idOrName}/custom-environments
# operationId: createCustomEnvironment
# --branchMatcher shape: {type: "equals"|"startsWith"|"endsWith", pattern: string}
export def "projects-custom-environments createCustomEnvironment" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --slug: string # The slug of the custom environment to create.
  --description: string # Description of the custom environment. This is optional.
  --branchMatcher: record # How we want to determine a matching branch. This is optional. — shape: {type: "equals"|"startsWith"|"endsWith", pattern: string}
  --copyEnvVarsFrom: string # Where to copy environment variables from. This is optional.
]: any -> record<id: string, slug: string, type: string, description: string, branchMatcher: record<type: string, pattern: string>, domains: table<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: list>, currentDeploymentAliases: list<string>, createdAt: float, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/custom-environments" $qp)
  let body = {slug: $slug, description: $description, branchMatcher: $branchMatcher, copyEnvVarsFrom: $copyEnvVarsFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve custom environments
#
# GET /v9/projects/{idOrName}/custom-environments
# operationId: getProjectsByIdOrNameCustomEnvironments
export def "projects-custom-environments list" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gitBranch: string # Fetch custom environments for a specific git branch
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<accountLimit: record<total: float>, environments: table<type: string, description: string, createdAt: float, updatedAt: float, slug: string, id: string, domains: list, branchMatcher: record, currentDeploymentAliases: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gitBranch" $gitBranch "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/custom-environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a custom environment
#
# GET /v9/projects/{idOrName}/custom-environments/{environmentSlugOrId}
# operationId: getCustomEnvironment
export def "projects-custom-environments get" [
  idOrName: string
  environmentSlugOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string, slug: string, type: string, description: string, branchMatcher: record<type: string, pattern: string>, domains: table<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: list>, currentDeploymentAliases: list<string>, createdAt: float, updatedAt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/custom-environments/($environmentSlugOrId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom environment
#
# PATCH /v9/projects/{idOrName}/custom-environments/{environmentSlugOrId}
# operationId: updateCustomEnvironment
# --branchMatcher shape: {type: "equals"|"startsWith"|"endsWith", pattern: string}
export def "projects-custom-environments updateCustomEnvironment" [
  idOrName: string
  environmentSlugOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --slug: string # The slug of the custom environment.
  --description: string # Description of the custom environment. This is optional.
  --branchMatcher: record # How we want to determine a matching branch. This is optional. (nullable) — shape: {type: "equals"|"startsWith"|"endsWith", pattern: string}
]: any -> record<id: string, slug: string, type: string, description: string, branchMatcher: record<type: string, pattern: string>, domains: table<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: list>, currentDeploymentAliases: list<string>, createdAt: float, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/custom-environments/($environmentSlugOrId)" $qp)
  let body = {slug: $slug, description: $description, branchMatcher: $branchMatcher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a custom environment
#
# DELETE /v9/projects/{idOrName}/custom-environments/{environmentSlugOrId}
# operationId: removeCustomEnvironment
export def "projects-custom-environments removeCustomEnvironment" [
  idOrName: string
  environmentSlugOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --deleteUnassignedEnvironmentVariables: string@bool-completer # Delete Environment Variables that are not assigned to any environments.
]: any -> record<id: string, slug: string, type: string, description: string, branchMatcher: record<type: string, pattern: string>, domains: table<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: list>, currentDeploymentAliases: list<string>, createdAt: float, updatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/custom-environments/($environmentSlugOrId)" $qp)
  let body = {deleteUnassignedEnvironmentVariables: $deleteUnassignedEnvironmentVariables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve project domains by project by id or name
#
# GET /v9/projects/{idOrName}/domains
# operationId: getProjectDomains
export def "projects-domains list" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --production: string@production-completer # Filters only production domains when set to `true`. (default: false)
  --target: string@target-completer # Filters on the target of the domain. Can be either "production", "preview"
  --customEnvironmentId: string # The unique custom environment identifier within the project (e.g. env_123abc4567)
  --gitBranch: string # Filters domains based on specific branch.
  --redirects: string@redirects-completer # Excludes redirect project domains when "false". Includes redirect project domains when "true" (default). (default: true)
  --redirect: string # Filters domains based on their redirect target. (e.g. example.com)
  --verified: string@verified-completer # Filters domains based on their verification status.
  --limit: float # Maximum number of domains to list from a request (max 100). (e.g. 20)
  --since: float # Get domains created after this JavaScript timestamp. (e.g. 1609499532000)
  --until: float # Get domains created before this JavaScript timestamp. (e.g. 1612264332000)
  --order: string@order-completer # Domains sort order by createdAt (default: DESC)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "production" $production "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "customEnvironmentId" $customEnvironmentId "scalar") (serialize-qp "gitBranch" $gitBranch "scalar") (serialize-qp "redirects" $redirects "scalar") (serialize-qp "redirect" $redirect "scalar") (serialize-qp "verified" $verified "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a project domain
#
# GET /v9/projects/{idOrName}/domains/{domain}
# operationId: getProjectDomain
export def "projects-domains get" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: table<type: string, domain: string, value: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project domain
#
# PATCH /v9/projects/{idOrName}/domains/{domain}
# operationId: updateProjectDomain
export def "projects-domains updateProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --gitBranch: string # Git branch to link the project domain (nullable)
  --redirect: string # Target destination domain for redirect (nullable, e.g. foobar.com)
  --redirectStatusCode: int@redirectStatusCode-completer # Status code for domain redirect (nullable, e.g. 307)
]: any -> record<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: table<type: string, domain: string, value: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)" $qp)
  let body = {gitBranch: $gitBranch, redirect: $redirect, redirectStatusCode: $redirectStatusCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a domain from a project
#
# DELETE /v9/projects/{idOrName}/domains/{domain}
# operationId: removeProjectDomain
export def "projects-domains removeProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --removeRedirects: string@bool-completer # Whether to remove all domains from this project that redirect to the domain being removed.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)" $qp)
  let body = {removeRedirects: $removeRedirects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a domain to a project
#
# POST /v10/projects/{idOrName}/domains
# operationId: addProjectDomain
export def "projects-domains addProjectDomain" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string # The project domain name (e.g. www.example.com)
  --gitBranch: string # Git branch to link the project domain (nullable)
  --customEnvironmentId: string # The unique custom environment identifier within the project
  --redirect: string # Target destination domain for redirect (nullable, e.g. foobar.com)
  --redirectStatusCode: int@redirectStatusCode-completer # Status code for domain redirect (nullable, e.g. 307)
]: any -> record<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: table<type: string, domain: string, value: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v10/projects/($idOrName)/domains" $qp)
  let body = {name: $name, gitBranch: $gitBranch, customEnvironmentId: $customEnvironmentId, redirect: $redirect, redirectStatusCode: $redirectStatusCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move a project domain
#
# POST /v1/projects/{idOrName}/domains/{domain}/move
# operationId: moveProjectDomain
export def "projects-domains-move moveProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  projectId: any # The unique target project identifier (e.g. prj_XLKmu1DyR1eY7zq8UgeRKbA7yVLA)
  --gitBranch: string # Git branch to link the project domain (nullable)
  --redirect: string # Target destination domain for redirect (nullable, e.g. foobar.com)
  --redirectStatusCode: int@redirectStatusCode-completer # Status code for domain redirect (nullable, e.g. 307)
]: any -> record<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool, verification: table<type: string, domain: string, value: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/domains/($domain)/move" $qp)
  let body = {projectId: $projectId, gitBranch: $gitBranch, redirect: $redirect, redirectStatusCode: $redirectStatusCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify project domain
#
# POST /v9/projects/{idOrName}/domains/{domain}/verify
# operationId: verifyProjectDomain
export def "projects-domains-verify verifyProjectDomain" [
  idOrName: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<name: string, apexName: string, projectId: string, redirect: string, redirectStatusCode: float, gitBranch: string, customEnvironmentId: string, updatedAt: float, createdAt: float, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/domains/($domain)/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the environment variables of a project by id or name
#
# GET /v10/projects/{idOrName}/env
# operationId: filterProjectEnvs
export def "projects-env filterProjectEnvs" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gitBranch: string # If defined, the git branch of the environment variable to filter the results (must have target=preview) (e.g. feature-1)
  --decrypt: string@decrypt-completer # If true, the environment variable value will be decrypted (e.g. true)
  --qp-source: string # The source that is calling the endpoint. (e.g. vercel-cli:pull)
  --customEnvironmentId: string # The unique custom environment identifier within the project (e.g. env_123abc4567)
  --customEnvironmentSlug: string # The custom environment slug (name) within the project (e.g. my-custom-env)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gitBranch" $gitBranch "scalar") (serialize-qp "decrypt" $decrypt "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "customEnvironmentId" $customEnvironmentId "scalar") (serialize-qp "customEnvironmentSlug" $customEnvironmentSlug "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v10/projects/($idOrName)/env" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create one or more environment variables
#
# POST /v10/projects/{idOrName}/env
# operationId: createProjectEnv
export def "projects-env createProjectEnv" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --upsert: string # Allow override of environment variable if it already exists (e.g. true)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --key: string # The name of the environment variable (e.g. API_URL)
  --value: string # The value of the environment variable (e.g. https://api.vercel.com)
  --type: string@type-completer-3 # The type of environment variable (e.g. plain)
  --target: list # The target environment of the environment variable (e.g. [preview])
  --gitBranch: string # If defined, the git branch of the environment variable (must have target=preview) (nullable, e.g. feature-1)
  --comment: string # A comment to add context on what this environment variable is for (e.g. database connection string for production)
  --customEnvironmentIds: list # The custom environment IDs associated with the environment variable
]: any -> record<created: any, failed: table<error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upsert" $upsert "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v10/projects/($idOrName)/env" $qp)
  let body = {key: $key, value: $value, type: $type, target: $target, gitBranch: $gitBranch, comment: $comment, customEnvironmentIds: $customEnvironmentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the decrypted value of an environment variable of a project by id
#
# GET /v1/projects/{idOrName}/env/{id}
# operationId: getProjectEnv
export def "projects-env get" [
  idOrName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/env/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an environment variable
#
# DELETE /v9/projects/{idOrName}/env/{id}
# operationId: removeProjectEnv
export def "projects-env removeProjectEnv" [
  idOrName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customEnvironmentId: string # The unique custom environment identifier within the project (e.g. env_123abc4567)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customEnvironmentId" $customEnvironmentId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/env/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an environment variable
#
# PATCH /v9/projects/{idOrName}/env/{id}
# operationId: editProjectEnv
export def "projects-env editProjectEnv" [
  idOrName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --key: string # The name of the environment variable (e.g. GITHUB_APP_ID)
  --target: list # The target environment of the environment variable (e.g. [preview])
  --gitBranch: string # If defined, the git branch of the environment variable (must have target=preview) (nullable, e.g. feature-1)
  --type: string@type-completer-3 # The type of environment variable (e.g. plain)
  --value: string # The value of the environment variable (e.g. bkWIjbnxcvo78)
  --customEnvironmentIds: list # The custom environments that the environment variable should be synced to
  --comment: string # A comment to add context on what this env var is for (e.g. database connection string for production)
]: any -> record<type: string, value: string, edgeConfigId: string, edgeConfigTokenId: string, createdAt: float, updatedAt: float, id: string, key: string, target: any, gitBranch: string, createdBy: string, updatedBy: string, sunsetSecretId: string, legacyValue: string, decrypted: bool, configurationId: string, contentHint: any, internalContentHint: record<type: string, encryptedValue: string>, comment: string, customEnvironmentIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v9/projects/($idOrName)/env/($id)" $qp)
  let body = {key: $key, target: $target, gitBranch: $gitBranch, type: $type, value: $value, customEnvironmentIds: $customEnvironmentIds, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch remove environment variables
#
# DELETE /v1/projects/{idOrName}/env
# operationId: batchRemoveProjectEnv
export def "projects-env batchRemoveProjectEnv" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  ids: list # Array of environment variable IDs to delete
]: any -> record<deleted: float, ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/env" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rolling release billing status
#
# GET /v1/projects/{idOrName}/rolling-release/billing
# operationId: getRollingReleaseBillingStatus
export def "projects-rolling-release-billing get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release/billing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rolling release configuration
#
# GET /v1/projects/{idOrName}/rolling-release/config
# operationId: getRollingReleaseConfig
export def "projects-rolling-release-config get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<rollingRelease: record<target: string, stages: list<record>, canaryResponseHeader: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete rolling release configuration
#
# DELETE /v1/projects/{idOrName}/rolling-release/config
# operationId: deleteRollingReleaseConfig
export def "projects-rolling-release-config delete" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<rollingRelease: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the rolling release settings for the project
#
# PATCH /v1/projects/{idOrName}/rolling-release/config
# operationId: updateRollingReleaseConfig
export def "projects-rolling-release-config updateRollingReleaseConfig" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the active rolling release information for a project
#
# GET /v1/projects/{idOrName}/rolling-release
# operationId: getRollingRelease
export def "projects-rolling-release get" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer-1 # Filter by rolling release state
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<rollingRelease: record<state: string, substate: string, currentDeployment: record<name: string, createdAt: float, id: string, target: string, readyState: string, readyStateAt: float, source: string, url: string>, canaryDeployment: record<name: string, createdAt: float, id: string, target: string, readyState: string, readyStateAt: float, source: string, url: string>, queuedDeploymentId: string, advancementType: string, stages: list<record>, activeStage: record<index: float, isFinalStage: bool, targetPercentage: float, requireApproval: bool, duration: float, linearShift: bool>, nextStage: record<index: float, isFinalStage: bool, targetPercentage: float, requireApproval: bool, duration: float, linearShift: bool>, startedAt: float, updatedAt: float, currentCanaryPercentage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the active rolling release to the next stage for a project
#
# POST /v1/projects/{idOrName}/rolling-release/approve-stage
# operationId: approveRollingReleaseStage
export def "projects-rolling-release-approve-stage approveRollingReleaseStage" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  nextStageIndex: float # The index of the stage to transition to
  canaryDeploymentId: string # The id of the canary deployment to approve for the next stage
]: any -> record<rollingRelease: record<state: string, substate: string, currentDeployment: record<name: string, createdAt: float, id: string, target: string, readyState: string, readyStateAt: float, source: string, url: string>, canaryDeployment: record<name: string, createdAt: float, id: string, target: string, readyState: string, readyStateAt: float, source: string, url: string>, queuedDeploymentId: string, advancementType: string, stages: list<record>, activeStage: record<index: float, isFinalStage: bool, targetPercentage: float, requireApproval: bool, duration: float, linearShift: bool>, nextStage: record<index: float, isFinalStage: bool, targetPercentage: float, requireApproval: bool, duration: float, linearShift: bool>, startedAt: float, updatedAt: float, currentCanaryPercentage: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release/approve-stage" $qp)
  let body = {nextStageIndex: $nextStageIndex, canaryDeploymentId: $canaryDeploymentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete the rolling release for the project
#
# POST /v1/projects/{idOrName}/rolling-release/complete
# operationId: completeRollingRelease
export def "projects-rolling-release-complete completeRollingRelease" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  canaryDeploymentId: string # The ID of the canary deployment to complete
]: any -> record<rollingRelease: record<state: string, substate: string, currentDeployment: record<name: string, createdAt: float, id: string, target: string, readyState: string, readyStateAt: float, source: string, url: string>, canaryDeployment: record<name: string, createdAt: float, id: string, target: string, readyState: string, readyStateAt: float, source: string, url: string>, queuedDeploymentId: string, advancementType: string, stages: list<record>, activeStage: record<index: float, isFinalStage: bool, targetPercentage: float, requireApproval: bool, duration: float, linearShift: bool>, nextStage: record<index: float, isFinalStage: bool, targetPercentage: float, requireApproval: bool, duration: float, linearShift: bool>, startedAt: float, updatedAt: float, currentCanaryPercentage: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/rolling-release/complete" $qp)
  let body = {canaryDeploymentId: $canaryDeploymentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create project transfer request
#
# POST /projects/{idOrName}/transfer-request
# operationId: createProjectTransferRequest
export def "projects-transfer-request createProjectTransferRequest" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --callbackUrl: string # The URL to send a webhook to when the transfer is accepted.
  --callbackSecret: string # The secret to use to sign the webhook payload with HMAC-SHA256.
]: any -> record<code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($idOrName)/transfer-request" $qp)
  let body = {callbackUrl: $callbackUrl, callbackSecret: $callbackSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accept project transfer request
#
# PUT /projects/transfer-request/{code}
# operationId: acceptProjectTransferRequest
# --paidFeatures shape: {concurrentBuilds?: int, passwordProtection?: bool, previewDeploymentSuffix?: bool}
export def "projects-transfer-request acceptProjectTransferRequest" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --newProjectName: string # The desired name for the project (e.g. a-project-name)
  --paidFeatures: record # shape: {concurrentBuilds?: int, passwordProtection?: bool, previewDeploymentSuffix?: bool}
  --acceptedPolicies: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/transfer-request/($code)" $qp)
  let body = {newProjectName: $newProjectName, paidFeatures: $paidFeatures, acceptedPolicies: $acceptedPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Protection Bypass for Automation
#
# PATCH /v1/projects/{idOrName}/protection-bypass
# operationId: updateProjectProtectionBypass
# --revoke shape: {secret: string, regenerate: bool}
# --generate shape: {secret?: string, note?: string}
# --update shape: {secret: string, isEnvVar?: bool, note?: string}
export def "projects-protection-bypass updateProjectProtectionBypass" [
  idOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --revoke: record # Optional instructions for revoking and regenerating a automation bypass — shape: {secret: string, regenerate: bool}
  --generate: record # Generate a new secret. If neither generate or revoke are provided, a new random secret will be generated. — shape: {secret?: string, note?: string}
  --update: record # Update an existing bypass — shape: {secret: string, isEnvVar?: bool, note?: string}
]: any -> record<protectionBypass: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($idOrName)/protection-bypass" $qp)
  let body = {revoke: $revoke, generate: $generate, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Points all production domains for a project to the given deploy
#
# POST /v1/projects/{projectId}/rollback/{deploymentId}
# operationId: requestRollback
export def "projects-rollback requestRollback" [
  projectId: string
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The reason for the rollback
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/rollback/($deploymentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the description for a rollback
#
# PATCH /v1/projects/{projectId}/rollback/{deploymentId}/update-description
# operationId: updateProjectsByProjectIdRollbackByDeploymentIdUpdateDescription
export def "projects-rollback-update-description updateProjectsByProjectIdRollbackByDeploymentIdUpdateDescription" [
  projectId: string
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The reason for the rollback
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($projectId)/rollback/($deploymentId)/update-description")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the microfrontends settings
#
# PATCH /v1/projects/{projectId}/microfrontends
# operationId: updateMicrofrontends
export def "projects-microfrontends updateMicrofrontends" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --microfrontendsGroupId: string # The unique group identifier to add this microfrontend to (e.g. mfe_12HKQaOmR5t5Uy6vdcQsNIiZgHGB)
  --enabled: string@bool-completer # Enable or disable microfrontends for the project (e.g. true)
  --isDefaultApp: string@bool-completer # Whether the application is the default application for the microfrontends group (e.g. true)
  --defaultRoute: string # The default route used for screenshots and preview links for the project (e.g. /home)
  --routeObservabilityToThisProject: string@bool-completer # Whether observability data should be routed to this project or a root project. Can only be set for child applications.
  --doNotRouteWithMicrofrontendsRouting: string@bool-completer # Whether domains in this project should route as a microfrontend. Can only be set for child applications.
]: any -> record<accountId: string, analytics: record<id: string, canceledAt: float, disabledAt: float, enabledAt: float, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, appliedCve55182Migration: bool, speedInsights: record<id: string, enabledAt: float, disabledAt: float, canceledAt: float, hasData: bool, paidAt: float>, autoExposeSystemEnvs: bool, autoAssignCustomDomains: bool, autoAssignCustomDomainsUpdatedBy: string, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurations: table<envId: any, connectConfigurationId: string, dc: string, passive: bool, buildsEnabled: bool, aws: record, createdAt: float, updatedAt: float>, connectConfigurationId: string, connectBuildsEnabled: bool, passiveConnectConfigurationId: string, createdAt: float, customerSupportCodeVisibility: bool, crons: record<enabledAt: float, disabledAt: float, updatedAt: float, deploymentId: string, definitions: list<record>>, dataCache: record<userDisabled: bool, storageSizeBytes: float, unlimited: bool>, deploymentExpiration: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, expiration: any, devCommand: string, directoryListing: bool, installCommand: string, env: table<target: any, type: string, sunsetSecretId: string, legacyValue: string, decrypted: bool, value: string, vsmValue: string, id: string, key: string, configurationId: string, createdAt: float, updatedAt: float, createdBy: string, updatedBy: string, gitBranch: string, edgeConfigId: string, edgeConfigTokenId: string, contentHint: any, internalContentHint: record, comment: string, customEnvironmentIds: list>, customEnvironments: table<id: string, slug: string, type: string, description: string, branchMatcher: record, domains: list, currentDeploymentAliases: list, createdAt: float, updatedAt: float>, framework: string, services: table<serviceName: string, serviceType: string, framework: string, runtime: string>, gitForkProtection: bool, gitLFS: bool, id: string, ipBuckets: table<bucket: string, default: bool, supportUntil: float>, jobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, latestDeployments: table<alias: list, aliasAssigned: any, builds: list, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, name: string, forced: bool, id: string, meta: record, plan: string, private: bool, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, microfrontends: any, name: string, nodeVersion: string, optionsAllowlist: record<paths: list<record>>, outputDirectory: string, passwordProtection: record, passport: record<deploymentType: string, connectorId: string>, protectionConfig: record<sandboxUrls: record<inheritDeploymentProtection: bool>>, productionDeploymentsFastLane: bool, publicSource: bool, resourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rollbackDescription: record<userId: string, username: string, description: string, createdAt: float>, rollingRelease: record<target: string, stages: list<record>, canaryResponseHeader: bool>, defaultResourceConfig: record<elasticConcurrencyEnabled: bool, fluid: bool, functionDefaultRegions: list<string>, functionDefaultTimeout: float, functionDefaultMemoryType: string, functionZeroConfigFailover: bool, buildMachineType: string, buildMachineSelection: string, buildMachineElasticLastUpdated: float, isNSNBDisabled: bool, buildQueue: record<configuration: string>, enableFunctionsBeta: bool>, rootDirectory: string, serverlessFunctionZeroConfigFailover: bool, skewProtectionBoundaryAt: float, skewProtectionMaxAge: float, skewProtectionAllowedDomains: list<string>, skipGitConnectDuringLink: bool, staticIps: record<builds: bool, enabled: bool, regions: list<string>>, sourceFilesOutsideRootDirectory: bool, enableAffectedProjectsDeployments: bool, enableExternalRewriteCaching: bool, ssoProtection: record<deploymentType: string, cve55182MigrationAppliedFrom: string, april2026SecurityIncidentMigrationAppliedFrom: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float, live: bool, enablePreviewFeedback: bool, enableProductionFeedback: bool, permissions: record<oauth2Connection: list<string>, user: list<string>, userConnection: list<string>, userMfaConfiguration: list<string>, userPreference: list<string>, userSudo: list<string>, webAuthn: list<string>, accessGroup: list<string>, agent: list<string>, aiGatewayUsage: list<string>, alerts: list<string>, alertRules: list<string>, aliasGlobal: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, apiKey: list<string>, apiKeyAiGateway: list<string>, apiKeyOwnedBySelf: list<string>, oauth2Application: list<string>, vercelAppInstallation: list<string>, vercelAppInstallationRequest: list<string>, auditLog: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingRefund: list<string>, billingTaxId: list<string>, blob: list<string>, blobStoreTokenSet: list<string>, budget: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, codeChecks: list<string>, ciInvocations: list<string>, ciLogs: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connexClient: list<string>, connexClientProject: list<string>, connexToken: list<string>, buildMachineDefault: list<string>, dataCacheBillingSettings: list<string>, defaultDeploymentProtection: list<string>, deploymentPolicy: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, drain: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigSchema: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, flagsExplorerSubscription: list<string>, gitRepository: list<string>, imageOptimizationNewPrice: list<string>, integration: list<string>, integrationAccount: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationRole: list<string>, integrationConfigurationTransfer: list<string>, integrationDeploymentAction: list<string>, integrationEvent: list<string>, integrationLog: list<string>, integrationResource: list<string>, integrationResourceData: list<string>, integrationResourceReplCommand: list<string>, integrationResourceSecrets: list<string>, integrationSSOSession: list<string>, integrationStrict: list<string>, integrationStoreTokenSet: list<string>, integrationVercelConfigurationOverride: list<string>, integrationPullRequest: list<string>, ipBlocking: list<string>, jobGlobal: list<string>, kmsIssuer: list<string>, kmsProjectGrant: list<string>, logDrain: list<string>, marketplaceBillingData: list<string>, marketplaceExperimentationEdgeConfigData: list<string>, marketplaceExperimentationItem: list<string>, marketplaceInstallationMember: list<string>, marketplaceInvoice: list<string>, marketplaceSettings: list<string>, Monitoring: list<string>, monitoringAlert: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, monitoringSettings: list<string>, notificationCustomerBudget: list<string>, notificationDeploymentFailed: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, NotificationMonitoringAlert: list<string>, notificationPaymentFailed: list<string>, notificationPreferences: list<string>, notificationStatementOfReasons: list<string>, notificationUsageAlert: list<string>, oidcFederationPolicy: list<string>, observabilityConfiguration: list<string>, observabilityFunnel: list<string>, observabilityNotebook: list<string>, openTelemetryEndpoint: list<string>, ownEvent: list<string>, organization: list<string>, organizationDomain: list<string>, organizationTeam: list<string>, passwordProtectionInvoiceItem: list<string>, paymentMethod: list<string>, permissions: list<string>, postgres: list<string>, postgresStoreTokenSet: list<string>, previewDeploymentSuffix: list<string>, privateCloudAccount: list<string>, projectTransferIn: list<string>, proTrialOnboarding: list<string>, rateLimit: list<string>, redis: list<string>, redisStoreTokenSet: list<string>, remoteCaching: list<string>, repository: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, space: list<string>, spaceRun: list<string>, storeIsLocked: list<string>, storeTokenSetSensitive: list<string>, storeTransfer: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamGitExclusivity: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamInviteLink: list<string>, teamJoin: list<string>, teamMemberMfaStatus: list<string>, teamMicrofrontends: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, teamSudo: list<string>, teamTokenInvalidation: list<string>, token: list<string>, toolbarComment: list<string>, usage: list<string>, usageCycle: list<string>, vcrRepository: list<string>, vercelRun: list<string>, vpcPeeringConnection: list<string>, webAnalyticsPlan: list<string>, webhook: list<string>, webhook_event: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, bulkRedirects: list<string>, buildMachine: list<string>, connectConfigurationLink: list<string>, dataCacheNamespace: list<string>, deployment: list<string>, deploymentBuildLogs: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentCheckReRunFromProductionBranch: list<string>, deploymentProductionGit: list<string>, deploymentV0: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentPromote: list<string>, deploymentRollback: list<string>, edgeCacheNamespace: list<string>, environments: list<string>, job: list<string>, logs: list<string>, logsPreset: list<string>, observabilityData: list<string>, onDemandBuild: list<string>, onDemandConcurrency: list<string>, optionsAllowlist: list<string>, passwordProtection: list<string>, privateLinkEndpoint: list<string>, productionAliasProtectionBypass: list<string>, project: list<string>, projectAccessGroup: list<string>, projectAnalyticsSampling: list<string>, projectAnalyticsUsage: list<string>, projectCheck: list<string>, projectCheckRun: list<string>, projectDeploymentExpiration: list<string>, projectDeploymentHook: list<string>, projectDeploymentProtectionStrict: list<string>, projectDomain: list<string>, projectDomainCheckConfig: list<string>, projectDomainMove: list<string>, projectEvent: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectFlags: list<string>, projectFlagsProduction: list<string>, projectFlagsSdkKey: list<string>, projectFromV0: list<string>, projectId: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectMonitoring: list<string>, projectOIDCToken: list<string>, projectPermissions: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectRollingRelease: list<string>, projectRoutes: list<string>, projectSupportCase: list<string>, projectSupportCaseComment: list<string>, projectTier: list<string>, projectTransfer: list<string>, projectTransferOut: list<string>, projectUsage: list<string>, pageIntegrity: list<string>, seawallConfig: list<string>, securityPlusConfiguration: list<string>, shareableLinkStrict: list<string>, sharedEnvVarConnection: list<string>, skewProtection: list<string>, analytics: list<string>, trustedIps: list<string>, trustedSources: list<string>, v0Chat: list<string>, webAnalytics: list<string>>, lastRollbackTarget: record, lastAliasRequest: record<fromDeploymentId: string, toDeploymentId: string, fromRollingReleaseId: string, jobStatus: string, requestedAt: float, type: string>, protectionBypass: record, hasActiveBranches: bool, trustedIps: any, trustedSources: record<projects: record, oidcProviders: record>, gitComments: record<onPullRequest: bool, onCommit: bool>, gitProviderOptions: record<createDeployments: string, disableRepositoryDispatchEvents: bool, requireVerifiedCommits: bool, gitCommitStatus: bool, consolidatedGitCommitStatus: record<enabled: bool, propagateFailures: bool>>, paused: bool, concurrencyBucketName: string, webAnalytics: record<id: string, disabledAt: float, canceledAt: float, enabledAt: float, hasData: bool>, security: record<attackModeEnabled: bool, attackModeUpdatedAt: float, firewallEnabled: bool, firewallUpdatedAt: float, attackModeActiveUntil: float, firewallConfigVersion: float, firewallSeawallEnabled: bool, ja3Enabled: bool, ja4Enabled: bool, firewallBypassIps: list<string>, managedRules: record<vercel_ruleset: record, bot_filter: record, ai_bots: record, owasp: record>, botIdEnabled: bool, log_headers: any, securityPlus: bool, securityPlusMetadata: record<updatedAt: float, firstEnabledAt: float>, pageIntegrityEnabled: bool>, oidcTokenConfig: record<enabled: bool, issuerMode: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, tier: string, flatRateTier: string, usageStatus: record<kind: string, exceededAllowanceUntil: float, bypassThrottleUntil: float, throttled: bool>, features: record<webAnalytics: bool>, v0: bool, v0Created: bool, abuse: record<scanner: string, history: list<record>, updatedAt: float, block: record<action: string, reason: string, statusCode: float, createdAt: float, caseId: string, actor: string, comment: string, ineligibleForAppeal: bool, isCascading: bool>, blockHistory: list<any>, interstitial: bool, interstitialHistory: list<record>>, internalRoutes: list<any>, hasDeployments: bool, dismissedToasts: table<key: string, dismissedAt: float, action: string, value: any>, protectedSourcemaps: bool, tracing: record<domains: string, ignorePaths: list<string>, samplingRules: list<record>>, avatar: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/microfrontends" $qp)
  let body = {microfrontendsGroupId: $microfrontendsGroupId, enabled: $enabled, isDefaultApp: $isDefaultApp, defaultRoute: $defaultRoute, routeObservabilityToThisProject: $routeObservabilityToThisProject, doNotRouteWithMicrofrontendsRouting: $doNotRouteWithMicrofrontendsRouting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Points all production domains for a project to the given deploy
#
# POST /v10/projects/{projectId}/promote/{deploymentId}
# operationId: requestPromote
export def "projects-promote requestPromote" [
  projectId: string
  deploymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v10/projects/($projectId)/promote/($deploymentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of aliases with status for the current promote
#
# GET /v1/projects/{projectId}/promote/aliases
# operationId: listPromoteAliases
export def "projects-promote-aliases listPromoteAliases" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of aliases to list from a request (max 100). (e.g. 20)
  --since: float # Get aliases created after this epoch timestamp. (e.g. 1609499532000)
  --until: float # Get aliases created before this epoch timestamp. (e.g. 1612264332000)
  --failedOnly: string@bool-completer # Filter results down to aliases that failed to map to the requested deployment
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "failedOnly" $failedOnly "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/promote/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a project
#
# POST /v1/projects/{projectId}/pause
# operationId: pauseProject
export def "projects-pause pauseProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/pause" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause a project
#
# POST /v1/projects/{projectId}/unpause
# operationId: unpauseProject
export def "projects-unpause unpauseProject" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/unpause" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sandboxes
#
# GET /v2/sandboxes
# operationId: listSandboxes
export def "sandboxes listSandboxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: string # The unique identifier or name of the project to list named sandboxes for. (e.g. prj_abc123)
  --limit: float # Maximum number of named sandboxes to return in the response. Used for pagination. (default: 20, e.g. 20)
  --sortBy: string@sortBy-completer # Field to sort by. (default: createdAt)
  --namePrefix: string # Filter named sandboxes whose name starts with this prefix. Only valid when sortBy=name.
  --cursor: string # Opaque pagination cursor from a previous response.
  --sortOrder: string@sortOrder-completer # Sort direction. Defaults to desc. (default: desc)
  --tags: string # Filter sandboxes by tag. Format: \"key:value\". Only one tag filter is supported at a time.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<sandboxes: table<name: string, currentSnapshotId: string, currentSessionId: string, status: string, statusUpdatedAt: float, persistent: bool, region: string, vcpus: float, memory: float, runtime: string, timeout: float, snapshotExpiration: float, keepLastSnapshots: record, networkPolicy: record, totalEgressBytes: float, totalIngressBytes: float, totalActiveCpuDurationMs: float, totalDurationMs: float, cwd: string, tags: record, mounts: record, createdAt: float, updatedAt: float>, pagination: record<count: float, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sandboxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a named sandbox
#
# POST /v2/sandboxes
# operationId: createSandboxes
# --resources shape: {vcpus?: int, memory?: int}
# --keepLastSnapshots shape: {count: int, expiration?: any, deleteEvicted?: bool}
export def "sandboxes createSandboxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --networkPolicy: any
  --resources: record # Resources to define the VM — shape: {vcpus?: int, memory?: int}
  --runtime: string@runtime-completer # The runtime environment for the sandbox. Determines the pre-installed language runtimes and tools available. (default: node24, e.g. node24)
  --body-source: any # The source from which to initialize the sandbox filesystem. Can be a Git repository, a tarball URL, or an existing snapshot.
  --projectId: string # The target project slug or ID in which the sandbox will be assigned to. (e.g. prj_abc123)
  --ports: list # List of ports to expose from the sandbox. Each port will be accessible via a unique URL. Maximum of 15 ports can be exposed. (e.g. [3000, 4000])
  --timeout: int # Maximum duration in milliseconds that the sandbox can run before being automatically stopped. (e.g. 300000)
  --env: record # Default environment variables for the sandbox. These are inherited by all commands unless overridden. (default: {}, e.g. {NODE_ENV: production, HELLO: world})
  --mounts: record # List of drives to mount to the sandbox at the provided path.
  --name: string # Name for the sandbox. Must be unique per project and URL-safe (alphanumeric, hyphens, underscores). (e.g. my-sandbox)
  --persistent: string@bool-completer # Whether the sandbox persists its state across restarts via automatic snapshots. Defaults to true. (default: true)
  --snapshotExpiration: any # Default snapshot expiration time in milliseconds. Set to 0 to disable expiration. When set, this value is used as the default expiration for all snapshots created for this sandbox. (e.g. 604800000)
  --keepLastSnapshots: record # Protect the N most recent snapshots with different expiration/deletion behavior. — shape: {count: int, expiration?: any, deleteEvicted?: bool}
  --tags: record # Key-value tags to associate with the sandbox. Maximum 5 tags. (e.g. {env: staging, team: platform})
]: any -> record<sandbox: record<name: string, currentSnapshotId: string, currentSessionId: string, status: string, statusUpdatedAt: float, persistent: bool, region: string, vcpus: float, memory: float, runtime: string, timeout: float, snapshotExpiration: float, keepLastSnapshots: record<count: float, expiration: float, deleteEvicted: bool>, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list>, totalEgressBytes: float, totalIngressBytes: float, totalActiveCpuDurationMs: float, totalDurationMs: float, cwd: string, tags: record, mounts: record, createdAt: float, updatedAt: float>, session: record<sourceSandboxName: string, projectId: string, id: string, memory: float, vcpus: float, region: string, runtime: string, timeout: float, status: string, requestedAt: float, startedAt: float, cwd: string, requestedStopAt: float, stoppedAt: float, abortedAt: float, duration: float, sourceSnapshotId: string, snapshottedAt: float, createdAt: float, updatedAt: float, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list, injectionRules: list>, activeCpuDurationMs: float, networkTransfer: record<ingress: float, egress: float>>, routes: table<url: string, port: float, subdomain: string, system: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sandboxes" $qp)
  let body = {networkPolicy: $networkPolicy, resources: $resources, runtime: $runtime, source: $body_source, projectId: $projectId, ports: $ports, timeout: $timeout, env: $env, mounts: $mounts, name: $name, persistent: $persistent, snapshotExpiration: $snapshotExpiration, keepLastSnapshots: $keepLastSnapshots, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List drives
#
# GET /v2/sandboxes/drives
# operationId: listDrives
export def "sandboxes-drives listDrives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The project ID or name associated with the drives. Required unless using a Vercel OIDC token scoped to a project. (e.g. prj_abc123)
  --limit: float # Maximum number of drives to return in the response. Used for pagination. (default: 20, e.g. 20)
  --cursor: string # Opaque pagination cursor from a previous response.
  --sortBy: string@sortBy-completer-1 # Field to sort drives by. (default: createdAt)
  --namePrefix: string # Filter drives whose name starts with this prefix. Only valid when sortBy=name.
  --sortOrder: string@sortOrder-completer # Sort direction for results. (default: desc)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<drives: table<name: string, projectId: string, maxSizeBytes: float, currentSessionId: string, currentSandboxName: string, createdAt: float, updatedAt: float>, pagination: record<count: float, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sandboxes/drives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get or create a drive
#
# POST /v2/sandboxes/drives/{name}
# operationId: getOrCreateDrive
export def "sandboxes-drives post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --projectId: string # The project ID or name to associate the drive with. Required unless using a Vercel OIDC token scoped to a project. (e.g. prj_abc123)
  --maxSizeBytes: int # Maximum drive size in bytes. Defaults to 100 GiB when omitted.
]: any -> record<drive: record<name: string, projectId: string, maxSizeBytes: float, currentSessionId: string, currentSandboxName: string, createdAt: float, updatedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/drives/($name)" $qp)
  let body = {projectId: $projectId, maxSizeBytes: $maxSizeBytes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a drive
#
# DELETE /v2/sandboxes/drives/{name}
# operationId: deleteDrive
export def "sandboxes-drives delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The project ID or name associated with the drive. Required unless using a Vercel OIDC token scoped to a project. (e.g. prj_abc123)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<drive: record<name: string, projectId: string, maxSizeBytes: float, currentSessionId: string, currentSandboxName: string, createdAt: float, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/drives/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List snapshots
#
# GET /v2/sandboxes/snapshots
# operationId: listSessionSnapshots
export def "sandboxes-snapshots listSessionSnapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: string # The unique identifier or name of the project to list snapshots for. (e.g. prj_abc123)
  --name: string # Name for the sandbox. Must be unique per project and URL-safe (alphanumeric, hyphens, underscores). (e.g. my-sandbox)
  --limit: float # Maximum number of snapshots to return in the response. Used for pagination. (default: 20, e.g. 20)
  --cursor: string # Opaque pagination cursor from a previous response.
  --sortOrder: string@sortOrder-completer # Sort direction for results by creation time. (default: desc)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sandboxes/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a snapshot
#
# GET /v2/sandboxes/snapshots/{snapshotId}
# operationId: getSessionSnapshot
export def "sandboxes-snapshots get" [
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<snapshot: record<id: string, sourceSessionId: string, region: string, status: string, sizeBytes: float, expiresAt: float, createdAt: float, updatedAt: float, lastUsedAt: float, creationMethod: string, parentId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a snapshot
#
# DELETE /v2/sandboxes/snapshots/{snapshotId}
# operationId: deleteSessionSnapshot
export def "sandboxes-snapshots delete" [
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<snapshot: record<id: string, sourceSessionId: string, region: string, status: string, sizeBytes: float, expiresAt: float, createdAt: float, updatedAt: float, lastUsedAt: float, creationMethod: string, parentId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sessions
#
# GET /v2/sandboxes/sessions
# operationId: listSessions
export def "sandboxes-sessions listSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: string # The unique identifier or name of the project to list sessions for. (e.g. prj_abc123)
  --name: string # Filter sessions by sandbox name. Only sessions belonging to the specified sandbox are returned. (e.g. my-sandbox)
  --limit: float # Maximum number of sessions to return in the response. Used for pagination. (default: 20, e.g. 20)
  --cursor: string # Opaque pagination cursor from a previous response.
  --sortOrder: string@sortOrder-completer # Sort direction for results by creation time. (default: desc)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sandboxes/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a session
#
# GET /v2/sandboxes/sessions/{sessionId}
# operationId: getSession
export def "sandboxes-sessions get" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<session: record<sourceSandboxName: string, projectId: string, id: string, memory: float, vcpus: float, region: string, runtime: string, timeout: float, status: string, requestedAt: float, startedAt: float, cwd: string, requestedStopAt: float, stoppedAt: float, abortedAt: float, duration: float, sourceSnapshotId: string, snapshottedAt: float, createdAt: float, updatedAt: float, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list, injectionRules: list>, activeCpuDurationMs: float, networkTransfer: record<ingress: float, egress: float>>, routes: table<url: string, port: float, subdomain: string, system: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a named sandbox
#
# GET /v2/sandboxes/{name}
# operationId: getNamedSandbox
export def "sandboxes get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The project ID or name (required when not using OIDC token). (e.g. prj_abc123)
  --resume: string@bool-completer # Whether to automatically resume a stopped named sandbox by creating a new instance from its snapshot. Defaults to false. (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<sandbox: record<name: string, currentSnapshotId: string, currentSessionId: string, status: string, statusUpdatedAt: float, persistent: bool, region: string, vcpus: float, memory: float, runtime: string, timeout: float, snapshotExpiration: float, keepLastSnapshots: record<count: float, expiration: float, deleteEvicted: bool>, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list>, totalEgressBytes: float, totalIngressBytes: float, totalActiveCpuDurationMs: float, totalDurationMs: float, cwd: string, tags: record, mounts: record, createdAt: float, updatedAt: float>, session: record<sourceSandboxName: string, projectId: string, id: string, memory: float, vcpus: float, region: string, runtime: string, timeout: float, status: string, requestedAt: float, startedAt: float, cwd: string, requestedStopAt: float, stoppedAt: float, abortedAt: float, duration: float, sourceSnapshotId: string, snapshottedAt: float, createdAt: float, updatedAt: float, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list, injectionRules: list>, activeCpuDurationMs: float, networkTransfer: record<ingress: float, egress: float>>, routes: table<url: string, port: float, subdomain: string, system: bool>, resumed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "resume" $resume "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a sandbox
#
# PATCH /v2/sandboxes/{name}
# operationId: updateSandbox
# --resources shape: {vcpus?: int, memory?: int}
export def "sandboxes updateSandbox" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The project ID that owns the named sandbox. When provided, takes precedence over OIDC project context.
  --resume: string@bool-completer # Whether to automatically resume a stopped named sandbox by creating a new instance from its snapshot. Defaults to false. (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --resources: record # Resources to define the VM — shape: {vcpus?: int, memory?: int}
  --runtime: string@runtime-completer # The runtime environment for the sandbox. Determines the pre-installed language runtimes and tools available. (e.g. node24)
  --timeout: int # Maximum duration in milliseconds that the sandbox can run before being automatically stopped. (e.g. 300000)
  --persistent: string@bool-completer # Whether the sandbox persists its state across restarts via automatic snapshots.
  --snapshotExpiration: any # Default snapshot expiration time in milliseconds. Set to 0 to disable expiration. When set, this value is used as the default expiration for all snapshots created for this sandbox. (e.g. 604800000)
  --keepLastSnapshots: any # Protect the N most recent snapshots with different expiration/deletion behavior. Set to null to clear.
  --networkPolicy: any
  --env: record # Default environment variables for the sandbox. Set to empty object to clear. (e.g. {NODE_ENV: production, HELLO: world})
  --ports: list # List of ports to expose from the sandbox. Each port will be accessible via a unique URL. Maximum of 15 ports can be exposed. (e.g. [3000, 4000])
  --currentSnapshotId: string # The snapshot ID to set as the current snapshot. Must be active and belong to the same project.
  --tags: record # Key-value tags to associate with the sandbox. Replaces existing tags. Set to empty object to clear. Maximum 5 tags. (e.g. {env: staging, team: platform})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "resume" $resume "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/($name)" $qp)
  let body = {resources: $resources, runtime: $runtime, timeout: $timeout, persistent: $persistent, snapshotExpiration: $snapshotExpiration, keepLastSnapshots: $keepLastSnapshots, networkPolicy: $networkPolicy, env: $env, ports: $ports, currentSnapshotId: $currentSnapshotId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a sandbox
#
# DELETE /v2/sandboxes/{name}
# operationId: deleteSandbox
export def "sandboxes delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The project ID that owns the named sandbox. When provided, takes precedence over OIDC project context.
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<sandbox: record<name: string, currentSnapshotId: string, currentSessionId: string, status: string, statusUpdatedAt: float, persistent: bool, region: string, vcpus: float, memory: float, runtime: string, timeout: float, snapshotExpiration: float, keepLastSnapshots: record<count: float, expiration: float, deleteEvicted: bool>, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list>, totalEgressBytes: float, totalIngressBytes: float, totalActiveCpuDurationMs: float, totalDurationMs: float, cwd: string, tags: record, mounts: record, createdAt: float, updatedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commands
#
# GET /v2/sandboxes/sessions/{sessionId}/cmd
# operationId: listSessionCommands
export def "sandboxes-sessions-cmd listSessionCommands" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<commands: table<id: string, name: string, args: list, cwd: string, sessionId: string, exitCode: float, startedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/cmd" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute a command
#
# POST /v2/sandboxes/sessions/{sessionId}/cmd
# operationId: runSessionCommand
export def "sandboxes-sessions-cmd runSessionCommand" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --cmdId: string # The unique identifier of the command to stream logs for. (e.g. cmd_abc123)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  command: string # The executable or shell command to run. This is the program name without arguments. (e.g. npm)
  --args: list # Arguments to pass to the command. Each argument should be a separate array element. (e.g. [install, --save, lodash])
  --cwd: string # The working directory in which to execute the command. Defaults to the sandbox home directory if not specified. (e.g. /home/vercel-sandbox)
  --env: record # Additional environment variables to set for this command. These are merged with the sandbox environment. (default: {}, e.g. {NODE_ENV: production, DEBUG: true})
  --sudo: string@bool-completer # Execute the command with root (superuser) privileges. (default: false)
  --wait: string@bool-completer # If true, returns an ND-JSON stream that emits the command status when started and again when finished. Useful for synchronously waiting for command completion. (default: false)
  --logs: string@bool-completer # If true, stream the logs of the command execution in real-time via ND-JSON. This is only applicable if `wait` is also true. (default: false)
  --timeout: int # Maximum duration in milliseconds the command may run before it is killed with SIGKILL. Enforced at exec time, independently of `wait`. (e.g. 30000)
]: any -> record<command: record<id: string, name: string, args: list<string>, cwd: string, sessionId: string, exitCode: float, startedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmdId" $cmdId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/cmd" $qp)
  let body = {command: $command, args: $args, cwd: $cwd, env: $env, sudo: $sudo, wait: $wait, logs: $logs, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a command
#
# GET /v2/sandboxes/sessions/{sessionId}/cmd/{cmdId}
# operationId: getSessionCommand
export def "sandboxes-sessions-cmd get" [
  sessionId: string
  cmdId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: string@wait-completer # If set to "true", the request will block until the command finishes execution. Useful for synchronously waiting for command completion. (default: false)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<command: record<id: string, name: string, args: list<string>, cwd: string, sessionId: string, exitCode: float, startedAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/cmd/($cmdId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kill a command
#
# POST /v2/sandboxes/sessions/{sessionId}/cmd/{cmdId}/kill
# operationId: killSessionCommand
export def "sandboxes-sessions-cmd-kill killSessionCommand" [
  cmdId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  signal: float # The POSIX signal number to send to the process. Common values: 15 (SIGTERM) for graceful termination, 9 (SIGKILL) for forced termination. (e.g. 15)
]: any -> record<command: record<id: string, name: string, args: list<string>, cwd: string, sessionId: string, exitCode: float, startedAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/cmd/($cmdId)/kill" $qp)
  let body = {signal: $signal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream command logs
#
# GET /v2/sandboxes/sessions/{sessionId}/cmd/{cmdId}/logs
# operationId: getSessionCommandLogs
export def "sandboxes-sessions-cmd-logs get" [
  sessionId: string
  cmdId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/cmd/($cmdId)/logs" $qp)
  let accept_val = "application/x-ndjson"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a session
#
# POST /v2/sandboxes/sessions/{sessionId}/stop
# operationId: stopSession
export def "sandboxes-sessions-stop stopSession" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extend session timeout
#
# POST /v2/sandboxes/sessions/{sessionId}/extend-timeout
# operationId: extendSessionTimeout
export def "sandboxes-sessions-extend-timeout extendSessionTimeout" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  duration: float # The amount of time in milliseconds to add to the current timeout. Must be at least 1000ms (1 second). (e.g. 300000)
]: any -> record<session: record<sourceSandboxName: string, projectId: string, id: string, memory: float, vcpus: float, region: string, runtime: string, timeout: float, status: string, requestedAt: float, startedAt: float, cwd: string, requestedStopAt: float, stoppedAt: float, abortedAt: float, duration: float, sourceSnapshotId: string, snapshottedAt: float, createdAt: float, updatedAt: float, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list, injectionRules: list>, activeCpuDurationMs: float, networkTransfer: record<ingress: float, egress: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/extend-timeout" $qp)
  let body = {duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update network policy
#
# POST /v2/sandboxes/sessions/{sessionId}/network-policy
# operationId: updateSessionNetworkPolicy
# --injectionRules item shape: {domain: string, headers: record, match?: record}
# --subnets shape: {allow?: list, deny?: list}
export def "sandboxes-sessions-network-policy updateSessionNetworkPolicy" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --mode: string@mode-completer # The network access policy mode. Use \"allow-all\" to permit all outbound traffic. Use \"deny-all\" to block all outbound traffic. Use \"custom\" to specify explicit allow/deny rules. (e.g. custom)
  --allowedDomains: list # List of domain names the sandbox is allowed to connect to. Only applies when mode is \"custom\". Supports wildcard patterns (e.g., \"*.example.com\" matches all subdomains). (e.g. [api.github.com, *.npmjs.org])
  --allowedCIDRs: list # List of IP address ranges (in CIDR notation) the sandbox is allowed to connect to. Traffic to these addresses bypasses domain-based restrictions. (e.g. [35.192.0.0/12, 104.16.0.0/12])
  --deniedCIDRs: list # List of IP address ranges (in CIDR notation) the sandbox is blocked from connecting to. These rules take precedence over all allowed rules. (e.g. [35.192.0.0/12])
  --injectionRules: list # HTTP header injection rules for outgoing requests matching specific domains. Traffic to matching domains will be intercepted instead of proxied through encrypted connections. — item shape: {domain: string, headers: record, match?: record}
  --allow: any
  --subnets: record # shape: {allow?: list, deny?: list}
]: any -> record<session: record<sourceSandboxName: string, projectId: string, id: string, memory: float, vcpus: float, region: string, runtime: string, timeout: float, status: string, requestedAt: float, startedAt: float, cwd: string, requestedStopAt: float, stoppedAt: float, abortedAt: float, duration: float, sourceSnapshotId: string, snapshottedAt: float, createdAt: float, updatedAt: float, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list, injectionRules: list>, activeCpuDurationMs: float, networkTransfer: record<ingress: float, egress: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/network-policy" $qp)
  let body = {mode: $mode, allowedDomains: $allowedDomains, allowedCIDRs: $allowedCIDRs, deniedCIDRs: $deniedCIDRs, injectionRules: $injectionRules, allow: $allow, subnets: $subnets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read a file
#
# POST /v2/sandboxes/sessions/{sessionId}/fs/read
# operationId: readSessionFile
export def "sandboxes-sessions-fs-read readSessionFile" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --cwd: string # The base directory for resolving relative paths. If not specified, paths are resolved from the sandbox home directory. (e.g. /home/vercel-sandbox)
  path: string # The path of the file to read. Can be absolute or relative to the working directory. (e.g. dist/agent-output.md)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/fs/read" $qp)
  let body = {cwd: $cwd, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a directory
#
# POST /v2/sandboxes/sessions/{sessionId}/fs/mkdir
# operationId: createSessionDirectory
export def "sandboxes-sessions-fs-mkdir createSessionDirectory" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --cwd: string # The base directory for resolving relative paths. If not specified, paths are resolved from the sandbox home directory. (e.g. /home/vercel-sandbox)
  path: string # The path of the directory to create. Can be absolute or relative to the working directory. (e.g. src/components)
  --recursive: string@bool-completer # If true, creates parent directories as needed (like `mkdir -p`). If false, fails if parent directories do not exist. (default: true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/fs/mkdir" $qp)
  let body = {cwd: $cwd, path: $path, recursive: $recursive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Write files
#
# POST /v2/sandboxes/sessions/{sessionId}/fs/write
# operationId: writeSessionFiles
export def "sandboxes-sessions-fs-write writeSessionFiles" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --x-Cwd: string # The target directory where the tarball contents will be extracted. If not specified, files are extracted to the sandbox home directory. (e.g. /home/vercel-sandbox)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/fs/write" $qp)
  let extra_headers = {"'x-Cwd'": $x_Cwd} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a snapshot
#
# POST /v2/sandboxes/sessions/{sessionId}/snapshot
# operationId: createSessionSnapshot
export def "sandboxes-sessions-snapshot createSessionSnapshot" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --expiration: any # The number of milliseconds after which the snapshot will expire and be deleted. Use 0 for no expiration.
]: any -> record<snapshot: record<id: string, sourceSessionId: string, region: string, status: string, sizeBytes: float, expiresAt: float, createdAt: float, updatedAt: float, lastUsedAt: float, creationMethod: string, parentId: string>, session: record<sourceSandboxName: string, projectId: string, id: string, memory: float, vcpus: float, region: string, runtime: string, timeout: float, status: string, requestedAt: float, startedAt: float, cwd: string, requestedStopAt: float, stoppedAt: float, abortedAt: float, duration: float, sourceSnapshotId: string, snapshottedAt: float, createdAt: float, updatedAt: float, networkPolicy: record<mode: string, allowedDomains: list, allowedCIDRs: list, deniedCIDRs: list, injectionRules: list>, activeCpuDurationMs: float, networkTransfer: record<ingress: float, egress: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/sandboxes/sessions/($sessionId)/snapshot" $qp)
  let body = {expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Attack Challenge mode
#
# POST /v1/security/attack-mode
# operationId: updateAttackChallengeMode
export def "security-attack-mode updateAttackChallengeMode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --projectId: string
  --attackModeEnabled: string@bool-completer
  --attackModeActiveUntil: float
]: any -> record<attackModeEnabled: bool, attackModeUpdatedAt: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/attack-mode" $qp)
  let body = {projectId: $projectId, attackModeEnabled: $attackModeEnabled, attackModeActiveUntil: $attackModeActiveUntil} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Put Firewall Configuration
#
# PUT /v1/security/firewall/config
# operationId: putFirewallConfig
# --crs shape: {sd?: record, ma?: record, lfi?: record, rfi?: record, rce?: record, php?: record, gen?: record, xss?: record, sqli?: record, sf?: record, java?: record}
# --rules item shape: {id?: string, name: string, description?: string, active: bool, conditionGroup: list, action: record, valid?: bool, validationErrors?: any}
# --ips item shape: {id?: string, hostname: string, ip: string, notes?: string, action: "deny"|"challenge"|"log"|"bypass"}
export def "security-firewall-config put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --firewallEnabled: string@bool-completer
  --managedRules: record
  --crs: record # Custom Ruleset — shape: {sd?: record, ma?: record, lfi?: record, rfi?: record, rce?: record, php?: record, gen?: record, xss?: record, sqli?: record, sf?: record, java?: record}
  --rules: list # item shape: {id?: string, name: string, description?: string, active: bool, conditionGroup: list, action: record, valid?: bool, validationErrors?: any}
  --ips: list # item shape: {id?: string, hostname: string, ip: string, notes?: string, action: "deny"|"challenge"|"log"|"bypass"}
  --botIdEnabled: string@bool-completer
  --logHeaders: any
]: any -> record<active: record<ownerId: string, projectKey: string, id: string, version: float, updatedAt: string, firewallEnabled: bool, crs: record<sd: record, ma: record, lfi: record, rfi: record, rce: record, php: record, gen: record, xss: record, sqli: record, sf: record, java: record>, rules: list<any>, ips: list<record>, changes: list<record>, managedRules: record<bot_protection: record, ai_bots: record, owasp: record, vercel_ruleset: record>, botIdEnabled: bool, logHeaders: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/config" $qp)
  let body = {firewallEnabled: $firewallEnabled, managedRules: $managedRules, crs: $crs, rules: $rules, ips: $ips, botIdEnabled: $botIdEnabled, logHeaders: $logHeaders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Firewall Configuration
#
# PATCH /v1/security/firewall/config
# operationId: updateFirewallConfig
export def "security-firewall-config updateFirewallConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --action: string@action-completer-2
  --id: any # nullable
  --value: string@bool-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/config" $qp)
  let body = {action: $action, id: $id, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Firewall Configuration
#
# GET /v1/security/firewall/config/{configVersion}
# operationId: getFirewallConfig
export def "security-firewall-config get" [
  configVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<ownerId: string, projectKey: string, id: string, version: float, updatedAt: string, firewallEnabled: bool, crs: record<sd: record<active: bool, action: string>, ma: record<active: bool, action: string>, lfi: record<active: bool, action: string>, rfi: record<active: bool, action: string>, rce: record<active: bool, action: string>, php: record<active: bool, action: string>, gen: record<active: bool, action: string>, xss: record<active: bool, action: string>, sqli: record<active: bool, action: string>, sf: record<active: bool, action: string>, java: record<active: bool, action: string>>, rules: list<any>, ips: table<id: string, hostname: string, ip: string, notes: string, action: string>, changes: list<record>, managedRules: record<bot_protection: record<active: bool, action: string, updatedAt: string, userId: string, username: string>, ai_bots: record<active: bool, action: string, updatedAt: string, userId: string, username: string>, owasp: record<active: bool, action: string, updatedAt: string, userId: string, username: string>, vercel_ruleset: record<active: bool, action: string, updatedAt: string, userId: string, username: string>>, botIdEnabled: bool, logHeaders: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/security/firewall/config/($configVersion)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read active attack data
#
# GET /v1/security/firewall/attack-status
# operationId: getActiveAttackStatus
export def "security-firewall-attack-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --since: float
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/attack-status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read System Bypass
#
# GET /v1/security/firewall/bypass
# operationId: getBypassIp
export def "security-firewall-bypass get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --limit: float # e.g. 10
  --sourceIp: string # Filter by source IP
  --domain: string # Filter by domain
  --projectScope: string@bool-completer # Filter by project scoped rules
  --offset: string # Used for pagination. Retrieves results after the provided id
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<result: table<OwnerId: string, Id: string, Domain: string, Ip: string, Action: string, ProjectId: string, IsProjectRule: bool, Note: string, CreatedAt: string, ActorId: string, UpdatedAt: string, UpdatedAtHour: string, DeletedAt: string, ExpiresAt: float>, pagination: record<OwnerId: string, Id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sourceIp" $sourceIp "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "projectScope" $projectScope "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/bypass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create System Bypass Rule
#
# POST /v1/security/firewall/bypass
# operationId: addBypassIp
export def "security-firewall-bypass addBypassIp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --domain: string
  --projectScope: string@bool-completer # If the specified bypass will apply to all domains for a project.
  --sourceIp: string
  --allSources: string@bool-completer
  --ttl: float # Time to live in milliseconds
  --note: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/bypass" $qp)
  let body = {domain: $domain, projectScope: $projectScope, sourceIp: $sourceIp, allSources: $allSources, ttl: $ttl, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove System Bypass Rule
#
# DELETE /v1/security/firewall/bypass
# operationId: removeBypassIp
export def "security-firewall-bypass removeBypassIp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --domain: string
  --projectScope: string@bool-completer
  --sourceIp: string
  --allSources: string@bool-completer
  --note: string
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/bypass" $qp)
  let body = {domain: $domain, projectScope: $projectScope, sourceIp: $sourceIp, allSources: $allSources, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Firewall Actions by Project
#
# GET /v1/security/firewall/events
# operationId: getSecurityFirewallEvents
export def "security-firewall-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --startTimestamp: float
  --endTimestamp: float
  --hosts: string
]: nothing -> record<actions: table<startTime: string, endTime: string, isActive: bool, action_type: string, host: string, public_ip: string, count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "startTimestamp" $startTimestamp "scalar") (serialize-qp "endTimestamp" $endTimestamp "scalar") (serialize-qp "hosts" $hosts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/security/firewall/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create integration store (free and paid plans)
#
# POST /v1/storage/stores/integration/direct
# operationId: createIntegrationStoreDirect
export def "storage-stores-integration-direct createIntegrationStoreDirect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string # Human-readable name for the storage resource (e.g. my-dev-database)
  integrationConfigurationId: string # ID of your integration configuration. Get this from GET /v1/integrations/configurations (e.g. icfg_cuwj0AdCdH3BwWT4LPijCC7t)
  integrationProductIdOrSlug: string # ID or slug of the integration product. Get available products from GET /v1/integrations/configuration/{id}/products (e.g. iap_postgres_db)
  --metadata: record # Optional key-value pairs for resource metadata (e.g. {environment: development, project: my-app, tags: [database, postgres]})
  --externalId: string # Optional external identifier for tracking purposes (e.g. dev-db-001)
  --protocolSettings: record # Protocol-specific configuration settings (e.g. {experimentation: {edgeConfigSyncingEnabled: true}})
  --body-source: string@source-completer # Source of the store creation request (default: marketplace, e.g. marketplace)
  --billingPlanId: string # ID of the billing plan for paid resources. Get available plans from GET /integrations/integration/{id}/products/{productId}/plans. If not provided, automatically discovers free billing plans. (e.g. bp_abc123def456)
  --paymentMethodId: string # Payment method ID for paid resources. Optional - uses default payment method if not provided. (e.g. pm_1AbcDefGhiJklMno)
  --prepaymentAmountCents: float # Amount in cents for prepayment billing plans. Required only for prepayment plans with variable amounts. (e.g. 5000)
]: any -> record<store: record<projectsMetadata: list<record>, projectFilter: record<git: record>, totalConnectedProjects: float, usageQuotaExceeded: bool, status: string, ownership: string, capabilities: record<mcp: bool, mcpReadonly: bool, sso: bool, billable: bool, transferable: bool, secretsSync: bool, secretRotation: any, projects: bool, v0: bool, autoSensitive: bool, agentTools: bool>, metadata: record, externalResourceId: string, externalResourceStatus: string, directPartnerConsoleUrl: string, product: record<id: string, name: string, slug: string, iconUrl: string, capabilities: record, shortDescription: string, metadataSchema: record, resourceLinks: list, tags: list, projectConnectionScopes: list, showSSOLinkOnProjectConnection: bool, disableResourceRenaming: bool, resourceTitle: string, agentSkillUrl: string, repl: record, guides: list, integration: record, integrationConfigurationId: string, supportedProtocols: list, primaryProtocol: string, logDrainStatus: string>, protocolSettings: record<experimentation: record>, notification: record<title: string, level: string, message: string, href: string>, secrets: list<record>, billingPlan: record<type: string, description: string, id: string, name: string, scope: string, paymentMethodRequired: bool, preauthorizationAmount: float, initialCharge: string, minimumAmount: string, maximumAmount: string, maximumAmountAutoPurchasePerPeriod: string, cost: string, details: list, highlightedDetails: list, quote: list, effectiveDate: string, disabled: bool>, secretRotationRequestedAt: float, secretRotationRequestedReason: string, secretRotationRequestedBy: string, secretRotationCompletedAt: float, parentId: string, targets: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/storage/stores/integration/direct" $qp)
  let body = {name: $name, integrationConfigurationId: $integrationConfigurationId, integrationProductIdOrSlug: $integrationProductIdOrSlug, metadata: $metadata, externalId: $externalId, protocolSettings: $protocolSettings, source: $body_source, billingPlanId: $billingPlanId, paymentMethodId: $paymentMethodId, prepaymentAmountCents: $prepaymentAmountCents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List team members
#
# GET /v3/teams/{teamId}/members
# operationId: getTeamMembers
export def "teams-members get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Limit how many teams should be returned (e.g. 20)
  --since: float # Timestamp in milliseconds to only include members added since then. (e.g. 1540095775951)
  --until: float # Timestamp in milliseconds to only include members added until then. (e.g. 1540095775951)
  --search: string # Search team members by their name, username, and email.
  --role: string@role-completer-2 # Only return members with the specified team role. (e.g. OWNER)
  --excludeProject: string # Exclude members who belong to the specified project.
  --eligibleMembersForProjectId: string # Include team members who are eligible to be members of the specified project.
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<members: table<avatar: string, confirmed: bool, email: string, github: record, gitlab: record, bitbucket: record, role: string, uid: string, username: string, name: string, createdAt: float, accessRequestedAt: float, joinedFrom: record, projects: list, isEnterpriseManaged: bool>, emailInviteCodes: table<accessGroups: list, id: string, email: string, role: string, teamRoles: list, teamPermissions: list, isDSyncUser: bool, createdAt: float, expired: bool, projects: record, entitlements: list>, pagination: record<hasNext: bool, count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "excludeProject" $excludeProject "scalar") (serialize-qp "eligibleMembersForProjectId" $eligibleMembersForProjectId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/teams/($teamId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite a user
#
# POST /v2/teams/{teamId}/members
# operationId: inviteUserToTeam
export def "teams-members inviteUserToTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --body: record
]: any -> record<uid: string, username: string, email: string, role: string, teamRoles: list<string>, teamPermissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($teamId)/members" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request access to a team
#
# POST /v1/teams/{teamId}/request
# operationId: requestAccessToTeam
# --joinedFrom shape: {origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback"|"organization-teams", commitId?: string, repoId?: string, repoPath?: string, gitUserId?: any, gitUserLogin?: string}
export def "teams-request requestAccessToTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  joinedFrom: record # shape: {origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback"|"organization-teams", commitId?: string, repoId?: string, repoPath?: string, gitUserId?: any, gitUserLogin?: string}
]: any -> record<teamSlug: string, teamName: string, confirmed: bool, joinedFrom: record<origin: string, commitId: string, repoId: string, repoPath: string, gitUserId: any, gitUserLogin: string, ssoUserId: string, ssoConnectedAt: float, idpUserId: string, dsyncUserId: string, dsyncConnectedAt: float>, accessRequestedAt: float, github: record<login: string>, gitlab: record<login: string>, bitbucket: record<login: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/request")
  let body = {joinedFrom: $joinedFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get access request status
#
# GET /v1/teams/{teamId}/request/{userId}
# operationId: getTeamAccessRequest
export def "teams-request get" [
  userId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<teamSlug: string, teamName: string, confirmed: bool, joinedFrom: record<origin: string, commitId: string, repoId: string, repoPath: string, gitUserId: any, gitUserLogin: string, ssoUserId: string, ssoConnectedAt: float, idpUserId: string, dsyncUserId: string, dsyncConnectedAt: float>, accessRequestedAt: float, github: record<login: string>, gitlab: record<login: string>, bitbucket: record<login: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/request/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Join a team
#
# POST /v1/teams/{teamId}/members/teams/join
# operationId: joinTeam
export def "teams-members-teams-join joinTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inviteCode: string # The invite code to join the team. (e.g. fisdh38aejkeivn34nslfore9vjtn4ls)
]: any -> record<teamId: string, slug: string, name: string, from: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/members/teams/join")
  let body = {inviteCode: $inviteCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Team Member
#
# PATCH /v1/teams/{teamId}/members/{uid}
# operationId: updateTeamMember
# --projects item shape: {projectId: string, role: "ADMIN"|"PROJECT_VIEWER"|"PROJECT_DEVELOPER"|""}
# --joinedFrom shape: {ssoUserId?: any}
export def "teams-members updateTeamMember" [
  uid: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmed: string@bool-completer # Accept a user who requested access to the team. (e.g. true)
  --role: string # The role in the team of the member. (default: MEMBER, e.g. VIEWER)
  --teamPermissions: list # The team permissions to set for the member. Permissions must be compatible with the team roles assigned to the member. (e.g. [CreateProject, FullProductionDeployment])
  --projects: list # item shape: {projectId: string, role: "ADMIN"|"PROJECT_VIEWER"|"PROJECT_DEVELOPER"|""}
  --joinedFrom: record # shape: {ssoUserId?: any}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/members/($uid)")
  let body = {confirmed: $confirmed, role: $role, teamPermissions: $teamPermissions, projects: $projects, joinedFrom: $joinedFrom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a Team Member
#
# DELETE /v1/teams/{teamId}/members/{uid}
# operationId: removeTeamMember
export def "teams-members removeTeamMember" [
  uid: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newDefaultTeamId: string # The ID of the team to set as the new default team for the Northstar user. (e.g. team_nllPyCtREAqxxdyFKbbMDlxd)
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newDefaultTeamId" $newDefaultTeamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)/members/($uid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Team
#
# GET /v2/teams/{teamId}
# operationId: getTeam
export def "teams get" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # e.g. my-team-url-slug
]: nothing -> record<connect: record<enabled: bool>, creatorId: string, updatedAt: float, emailDomain: string, saml: record<connection: record<status: string, type: string, state: string, connectedAt: float, lastReceivedWebhookEvent: float, lastSyncedAt: float, syncState: string>, directory: record<type: string, state: string, connectedAt: float, lastReceivedWebhookEvent: float, lastSyncedAt: float, syncState: string>, enforced: bool, defaultRedirectUri: string, roles: record>, inviteCode: string, description: string, defaultRoles: record<teamRoles: list<string>, teamPermissions: list<string>>, stagingPrefix: string, resourceConfig: record<concurrentBuilds: float, elasticConcurrencyEnabled: bool, edgeConfigSize: float, edgeConfigs: float, kvDatabases: float, blobStores: float, postgresDatabases: float, customEnvironmentsPerProject: float, buildEntitlements: record<enhancedBuilds: bool>, buildMachine: record<default: string>>, previewDeploymentSuffix: string, platform: bool, disableHardAutoBlocks: any, remoteCaching: record<enabled: bool>, defaultDeploymentProtection: record<passwordProtection: record<deploymentType: string>, ssoProtection: record<deploymentType: string>>, defaultPassport: record<connectorId: string, deploymentType: string>, defaultExpirationSettings: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, defaultProjectJobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, enablePreviewFeedback: string, enableProductionFeedback: string, sensitiveEnvironmentVariablePolicy: string, hideIpAddresses: bool, hideIpAddressesInLogDrains: bool, dpAccessRequestsMode: string, ipBuckets: table<bucket: string, supportUntil: float, default: bool>, requireVerifiedCommits: bool, disableRepositoryDispatchEvents: bool, strictDeploymentProtectionSettings: record<enabled: bool, updatedAt: float>, strictShareableLinks: record<enabled: bool, updatedAt: float>, nsnbConfig: record<preference: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, personalAccessTokensInvalidatedAt: float, appTokensInvalidatedAt: float, apiKeysInvalidatedAt: float, integrationTokensInvalidatedAt: float, id: string, slug: string, name: string, avatar: string, membership: record<uid: string, entitlements: list<record>, teamId: string, confirmed: bool, accessRequestedAt: float, role: string, teamRoles: list<string>, teamPermissions: list<string>, createdAt: float, created: float, joinedFrom: record<origin: string, commitId: string, repoId: string, repoPath: string, gitUserId: any, gitUserLogin: string, ssoUserId: string, ssoConnectedAt: float, idpUserId: string, dsyncUserId: string, dsyncConnectedAt: float>>, createdAt: float, parentId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($teamId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Team
#
# PATCH /v2/teams/{teamId}
# operationId: patchTeam
# --saml shape: {enforced?: bool, roles?: record}
# --remoteCaching shape: {enabled?: bool}
# --defaultDeploymentProtection shape: {passwordProtection?: record, ssoProtection?: record}
# --defaultPassport shape: {connectorId: string, deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
# --defaultExpirationSettings shape: {expiration?: "3y"|"2y"|"1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited", expirationProduction?: "3y"|"2y"|"1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited", expirationCanceled?: "1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited", expirationErrored?: "1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited"}
# --strictDeploymentProtectionSettings shape: {enabled: bool}
# --strictShareableLinks shape: {enabled: bool}
# --resourceConfig shape: {buildMachine?: record}
export def "teams patch" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --avatar: string # The hash value of an uploaded image. (format: regex)
  --description: string # A short text that describes the team. (e.g. Our mission is to make cloud computing accessible to everyone)
  --emailDomain: string # nullable, format: regex, e.g. example.com
  --name: string # The name of the team. (e.g. My Team)
  --previewDeploymentSuffix: string # Suffix that will be used for all preview deployments. (nullable, format: hostname, e.g. example.dev)
  --regenerateInviteCode: string@bool-completer # Create a new invite code and replace the current one. (e.g. true)
  --saml: record # shape: {enforced?: bool, roles?: record}
  --slug: string # A new slug for the team. (e.g. my-team)
  --enablePreviewFeedback: string # Enable preview toolbar: one of on, off or default. (e.g. on)
  --enableProductionFeedback: string # Enable production toolbar: one of on, off or default. (e.g. on)
  --sensitiveEnvironmentVariablePolicy: string # Sensitive environment variable policy: one of on, off or default. (e.g. on)
  --remoteCaching: record # Whether or not remote caching is enabled for the team — shape: {enabled?: bool}
  --hideIpAddresses: string@bool-completer # Display or hide IP addresses in Monitoring queries. (e.g. false)
  --hideIpAddressesInLogDrains: string@bool-completer # Display or hide IP addresses in Log Drains. (e.g. false)
  --dpAccessRequestsMode: string@dpAccessRequestsMode-completer # Controls who can request access to protected deployments. (e.g. none)
  --requireVerifiedCommits: string@bool-completer # When enabled, all projects in the team require commits to be signed and verified by the git provider before deployments will be created. (e.g. true)
  --disableRepositoryDispatchEvents: string@bool-completer # Default for projects in the team. When `true`, projects in this team will not emit GitHub repository-dispatch events on deployment events unless the project explicitly overrides this setting. (e.g. false)
  --defaultDeploymentProtection: record # Default deployment protection settings for new projects. — shape: {passwordProtection?: record, ssoProtection?: record}
  --defaultPassport: record # Default Passport configuration for new projects. (nullable) — shape: {connectorId: string, deploymentType: "all"|"preview"|"prod_deployment_urls_and_all_previews"|"all_except_custom_domains"}
  --defaultExpirationSettings: record # shape: {expiration?: "3y"|"2y"|"1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited", expirationProduction?: "3y"|"2y"|"1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited", expirationCanceled?: "1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited", expirationErrored?: "1y"|"6m"|"3m"|"2m"|"1m"|"2w"|"1w"|"1d"|"unlimited"}
  --deploymentPolicy: any
  --strictDeploymentProtectionSettings: record # When enabled, deployment protection settings require stricter permissions (owner-only). — shape: {enabled: bool}
  --strictShareableLinks: record # When enabled, creating shareable links requires Owner role. — shape: {enabled: bool}
  --nsnbConfig: any
  --defaultProjectJobs: any
  --resourceConfig: record # Resource configuration for the team. — shape: {buildMachine?: record}
]: any -> record<connect: record<enabled: bool>, creatorId: string, updatedAt: float, emailDomain: string, saml: record<connection: record<status: string, type: string, state: string, connectedAt: float, lastReceivedWebhookEvent: float, lastSyncedAt: float, syncState: string>, directory: record<type: string, state: string, connectedAt: float, lastReceivedWebhookEvent: float, lastSyncedAt: float, syncState: string>, enforced: bool, defaultRedirectUri: string, roles: record>, inviteCode: string, description: string, defaultRoles: record<teamRoles: list<string>, teamPermissions: list<string>>, stagingPrefix: string, resourceConfig: record<concurrentBuilds: float, elasticConcurrencyEnabled: bool, edgeConfigSize: float, edgeConfigs: float, kvDatabases: float, blobStores: float, postgresDatabases: float, customEnvironmentsPerProject: float, buildEntitlements: record<enhancedBuilds: bool>, buildMachine: record<default: string>>, previewDeploymentSuffix: string, platform: bool, disableHardAutoBlocks: any, remoteCaching: record<enabled: bool>, defaultDeploymentProtection: record<passwordProtection: record<deploymentType: string>, ssoProtection: record<deploymentType: string>>, defaultPassport: record<connectorId: string, deploymentType: string>, defaultExpirationSettings: record<expirationDays: float, expirationDaysProduction: float, expirationDaysCanceled: float, expirationDaysErrored: float, deploymentsToKeep: float>, defaultProjectJobs: record<lint: record<targets: list>, typecheck: record<targets: list>, mfe_config_present: record<targets: list>>, enablePreviewFeedback: string, enableProductionFeedback: string, sensitiveEnvironmentVariablePolicy: string, hideIpAddresses: bool, hideIpAddressesInLogDrains: bool, dpAccessRequestsMode: string, ipBuckets: table<bucket: string, supportUntil: float, default: bool>, requireVerifiedCommits: bool, disableRepositoryDispatchEvents: bool, strictDeploymentProtectionSettings: record<enabled: bool, updatedAt: float>, strictShareableLinks: record<enabled: bool, updatedAt: float>, nsnbConfig: record<preference: string>, deploymentPolicy: record<gitSources: list<record>, deploymentSources: list<record>>, personalAccessTokensInvalidatedAt: float, appTokensInvalidatedAt: float, apiKeysInvalidatedAt: float, integrationTokensInvalidatedAt: float, id: string, slug: string, name: string, avatar: string, membership: record<uid: string, entitlements: list<record>, teamId: string, confirmed: bool, accessRequestedAt: float, role: string, teamRoles: list<string>, teamPermissions: list<string>, createdAt: float, created: float, joinedFrom: record<origin: string, commitId: string, repoId: string, repoPath: string, gitUserId: any, gitUserLogin: string, ssoUserId: string, ssoConnectedAt: float, idpUserId: string, dsyncUserId: string, dsyncConnectedAt: float>>, createdAt: float, parentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/teams/($teamId)" $qp)
  let body = {avatar: $avatar, description: $description, emailDomain: $emailDomain, name: $name, previewDeploymentSuffix: $previewDeploymentSuffix, regenerateInviteCode: $regenerateInviteCode, saml: $saml, slug: $slug, enablePreviewFeedback: $enablePreviewFeedback, enableProductionFeedback: $enableProductionFeedback, sensitiveEnvironmentVariablePolicy: $sensitiveEnvironmentVariablePolicy, remoteCaching: $remoteCaching, hideIpAddresses: $hideIpAddresses, hideIpAddressesInLogDrains: $hideIpAddressesInLogDrains, dpAccessRequestsMode: $dpAccessRequestsMode, requireVerifiedCommits: $requireVerifiedCommits, disableRepositoryDispatchEvents: $disableRepositoryDispatchEvents, defaultDeploymentProtection: $defaultDeploymentProtection, defaultPassport: $defaultPassport, defaultExpirationSettings: $defaultExpirationSettings, deploymentPolicy: $deploymentPolicy, strictDeploymentProtectionSettings: $strictDeploymentProtectionSettings, strictShareableLinks: $strictShareableLinks, nsnbConfig: $nsnbConfig, defaultProjectJobs: $defaultProjectJobs, resourceConfig: $resourceConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all teams
#
# GET /v2/teams
# operationId: getTeams
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of Teams which may be returned. (e.g. 20)
  --since: float # Timestamp (in milliseconds) to only include Teams created since then. (e.g. 1540095775951)
  --until: float # Timestamp (in milliseconds) to only include Teams created until then. (e.g. 1540095775951)
]: nothing -> record<teams: list<any>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Team
#
# POST /v1/teams
# operationId: createTeam
# --attribution shape: {sessionReferrer?: string, landingPage?: string, pageBeforeConversionPage?: string, utm?: record}
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string # The desired slug for the Team (e.g. a-random-team)
  --name: string # The desired name for the Team. It will be generated from the provided slug if nothing is provided (e.g. A Random Team)
  --attribution: record # Attribution information for the session or current page — shape: {sessionReferrer?: string, landingPage?: string, pageBeforeConversionPage?: string, utm?: record}
]: any -> record<id: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let body = {slug: $slug, name: $name, attribution: $attribution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Team Directory Sync Role Mappings
#
# POST /v1/teams/{teamId}/dsync-roles
# operationId: postTeamDsyncRoles
export def "teams-dsync-roles post" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  roles: record # Directory groups to role or access group mappings.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)/dsync-roles" $qp)
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Team
#
# DELETE /v1/teams/{teamId}
# operationId: deleteTeam
# --reasons item shape: {slug: string, description: string}
export def "teams delete" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newDefaultTeamId: string # Id of the team to be set as the new default team (e.g. team_LLHUOMOoDlqOp8wPE4kFo9pE)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --reasons: list # Optional array of objects that describe the reason why the team is being deleted. — item shape: {slug: string, description: string}
]: any -> record<id: string, newDefaultTeamIdError: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newDefaultTeamId" $newDefaultTeamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)" $qp)
  let body = {reasons: $reasons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Team invite code
#
# DELETE /v1/teams/{teamId}/invites/{inviteId}
# operationId: deleteTeamInviteCode
export def "teams-invites delete" [
  inviteId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($teamId)/invites/($inviteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a microfrontends group
#
# PATCH /v1/teams/{teamId}/microfrontends/{groupId}
# operationId: updateMicrofrontendsGroup
export def "teams-microfrontends updateMicrofrontendsGroup" [
  groupId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --name: string # The new name for the existing microfrontends group. (e.g. MFE Group 1)
  --fallbackEnvironment: string # The new fallback environment for the microfrontends group. Must be "SAME_ENV", "PRODUCTION", or a valid custom environment slug from the default app.
]: any -> record<updatedMicrofrontendsGroup: record<name: string, slug: string, id: string, fallbackEnvironment: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)/microfrontends/($groupId)" $qp)
  let body = {name: $name, fallbackEnvironment: $fallbackEnvironment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a microfrontends group
#
# DELETE /v1/teams/{teamId}/microfrontends/{groupId}
# operationId: deleteMicrofrontendsGroup
export def "teams-microfrontends delete" [
  groupId: string
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($teamId)/microfrontends/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Deployment Files
#
# POST /v2/files
# operationId: uploadFile
export def "files uploadFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --content-Length: float # The file size in bytes
  --x-Vercel-Digest: string # The file SHA1 used to check the integrity
  --x-Now-Digest: string # The file SHA1 used to check the integrity
  --x-Now-Size: float # The file size as an alternative to `Content-Length`
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/files" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"'content-Length'": $content_Length, "'x-Vercel-Digest'": $x_Vercel_Digest, "'x-Now-Digest'": $x_Now_Digest, "'x-Now-Size'": $x_Now_Size} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# List Auth Tokens
#
# GET /v6/user/tokens
# operationId: listAuthTokens
export def "user-tokens listAuthTokens" [
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
  let full_url = (build-url $base "/v6/user/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Auth Token
#
# POST /v3/user/tokens
# operationId: createAuthToken
export def "user-tokens createAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  name: string
  --expiresAt: float
]: any -> record<token: record<id: string, name: string, type: string, prefix: string, suffix: string, origin: string, scopes: list<any>, createdAt: float, activeAt: float, expiresAt: float, revokedAt: float, leakedAt: float, leakedUrl: string>, bearerToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/user/tokens" $qp)
  let body = {name: $name, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Auth Token Metadata
#
# GET /v5/user/tokens/{tokenId}
# operationId: getAuthToken
export def "user-tokens get" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: record<id: string, name: string, type: string, prefix: string, suffix: string, origin: string, scopes: list<any>, createdAt: float, activeAt: float, expiresAt: float, revokedAt: float, leakedAt: float, leakedUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v5/user/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an authentication token
#
# DELETE /v3/user/tokens/{tokenId}
# operationId: deleteAuthToken
export def "user-tokens delete" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tokenId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/user/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the User
#
# GET /v2/user
# operationId: getAuthUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Account
#
# DELETE /v1/user
# operationId: requestDelete
# --reasons item shape: {slug: string, description: string}
export def "user requestDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reasons: list # Optional array of objects that describe the reason why the User account is being deleted. — item shape: {slug: string, description: string}
]: any -> record<id: string, email: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user")
  let body = {reasons: $reasons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a webhook
#
# POST /v1/webhooks
# operationId: createWebhook
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --body-url: string # format: uri
  events: list
  --projectIds: list
]: any -> record<secret: string, events: list<string>, id: string, url: string, ownerId: string, createdAt: float, updatedAt: float, projectIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let body = {url: $body_url, events: $events, projectIds: $projectIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of webhooks
#
# GET /v1/webhooks
# operationId: getWebhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /v1/webhooks/{id}
# operationId: getWebhook
export def "webhooks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<events: list<string>, id: string, url: string, ownerId: string, createdAt: float, updatedAt: float, projectIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/webhooks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a webhook
#
# DELETE /v1/webhooks/{id}
# operationId: deleteWebhook
export def "webhooks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/webhooks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Deployment Aliases
#
# GET /v2/deployments/{id}/aliases
# operationId: listDeploymentAliases
export def "deployments-aliases listDeploymentAliases" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<aliases: table<uid: string, alias: string, created: string, redirect: string, protectionBypass: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($id)/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign an Alias
#
# POST /v2/deployments/{id}/aliases
# operationId: assignAlias
export def "deployments-aliases assignAlias" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --alias: string # The alias we want to assign to the deployment defined in the URL (e.g. my-alias.vercel.app)
  --redirect: string # The redirect property will take precedence over the deployment id from the URL and consists of a hostname (like test.com) to which the alias should redirect using status code 307 (nullable)
]: any -> record<uid: string, alias: string, created: string, oldDeploymentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/deployments/($id)/aliases" $qp)
  let body = {alias: $alias, redirect: $redirect} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List aliases
#
# GET /v4/aliases
# operationId: listAliases
export def "aliases listAliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Get only aliases of the given domain name (e.g. my-test-domain.com)
  --qp-from: float # Get only aliases created after the provided timestamp (e.g. 1540095775951)
  --limit: float # Maximum number of aliases to list from a request (e.g. 10)
  --projectId: string # Filter aliases from the given `projectId` (e.g. prj_12HKQaOmR5t5Uy6vdcQsNIiZgHGB)
  --since: float # Get aliases created after this JavaScript timestamp (e.g. 1540095775941)
  --until: float # Get aliases created before this JavaScript timestamp (e.g. 1540095775951)
  --rollbackDeploymentId: string # Get aliases that would be rolled back for the given deployment (e.g. dpl_XXX)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<aliases: table<alias: string, created: string, createdAt: float, creator: record, deletedAt: float, deployment: record, deploymentId: string, projectId: string, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float, protectionBypass: record, microfrontends: record>, pagination: record<count: float, next: float, prev: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "rollbackDeploymentId" $rollbackDeploymentId "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Alias
#
# GET /v4/aliases/{idOrAlias}
# operationId: getAlias
export def "aliases get" [
  idOrAlias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: float # Get the alias only if it was created after the provided timestamp (e.g. 1540095775951)
  --projectId: string # Get the alias only if it is assigned to the provided project ID (e.g. prj_12HKQaOmR5t5Uy6vdcQsNIiZgHGB)
  --since: float # Get the alias only if it was created after this JavaScript timestamp (e.g. 1540095775941)
  --until: float # Get the alias only if it was created before this JavaScript timestamp (e.g. 1540095775951)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<alias: string, created: string, createdAt: float, creator: record<uid: string, email: string, username: string>, deletedAt: float, deployment: record<id: string, url: string, meta: string>, deploymentId: string, projectId: string, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float, protectionBypass: record, microfrontends: record<defaultApp: record<projectId: string>, applications: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/aliases/($idOrAlias)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Alias
#
# DELETE /v2/aliases/{aliasId}
# operationId: deleteAlias
export def "aliases delete" [
  aliasId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/aliases/($aliasId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the protection bypass for a URL
#
# PATCH /aliases/{id}/protection-bypass
# operationId: patchUrlProtectionBypass
# --revoke shape: {secret: string, regenerate: bool}
# --scope shape: {userId?: string, email?: string, access: "denied"|"granted"}
# --override shape: {scope: "alias-protection-override", action: "create"|"revoke"}
export def "aliases-protection-bypass patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --ttl: float # Optional time the shareable link is valid for in seconds. If not provided, the shareable link will never expire.
  --revoke: record # Optional instructions for revoking and regenerating a shareable link — shape: {secret: string, regenerate: bool}
  --scope: record # Instructions for creating a user scoped protection bypass — shape: {userId?: string, email?: string, access: "denied"|"granted"}
  --override: record # shape: {scope: "alias-protection-override", action: "create"|"revoke"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/aliases/($id)/protection-bypass" $qp)
  let body = {ttl: $ttl, revoke: $revoke, scope: $scope, override: $override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get cert by id
#
# GET /v8/certs/{id}
# operationId: getCertById
export def "certs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<id: string, createdAt: float, expiresAt: float, autoRenew: bool, cns: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/certs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove cert
#
# DELETE /v8/certs/{id}
# operationId: removeCert
export def "certs removeCert" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/certs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue a new cert
#
# POST /v8/certs
# operationId: issueCert
export def "certs issueCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  --cns: list # The common names the cert should be issued for
]: any -> record<id: string, createdAt: float, expiresAt: float, autoRenew: bool, cns: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/certs" $qp)
  let body = {cns: $cns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload a cert
#
# PUT /v8/certs
# operationId: uploadCert
export def "certs uploadCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
  ca: string # The certificate authority
  key: string # The certificate key
  cert: string # The certificate
  --skipValidation: string@bool-completer # Skip validation of the certificate
]: any -> record<id: string, createdAt: float, expiresAt: float, autoRenew: bool, cns: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v8/certs" $qp)
  let body = {ca: $ca, key: $key, cert: $cert, skipValidation: $skipValidation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Deployment Files
#
# GET /v6/deployments/{id}/files
# operationId: listDeploymentFiles
export def "deployments-files listDeploymentFiles" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> table<name: string, type: string, uid: string, children: list<any>, contentType: string, mode: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v6/deployments/($id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment File Contents
#
# GET /v8/deployments/{id}/files/{fileId}
# operationId: getDeploymentFileContents
export def "deployments-files get" [
  id: string
  fileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Path to the file to fetch (only for Git deployments)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v8/deployments/($id)/files/($fileId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List deployments
#
# GET /v7/deployments
# operationId: getDeployments
export def "deployments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app: string # Name of the deployment. (e.g. docs)
  --qp-from: float # Gets the deployment created after this Date timestamp. (default: current time) (e.g. 1612948664566)
  --limit: float # Maximum number of deployments to list from a request. (e.g. 10)
  --projectId: string # Filter deployments from the given ID or name. (e.g. QmXGTs7mvAMMC7WW5ebrM33qKG32QK3h4vmQMjmY)
  --projectIds: list # Filter deployments from the given project IDs. Cannot be used when projectId is specified. (e.g. [prj_123, prj_456])
  --target: string # Filter deployments based on the environment. (e.g. production)
  --qp-to: float # Gets the deployment created before this Date timestamp. (default: current time) (e.g. 1612948664566)
  --users: string # Filter out deployments based on users who have created the deployment. (e.g. kr1PsOIzqEL5Xg6M4VZcZosf,K4amb7K9dAt5R2vBJWF32bmY)
  --since: float # Get Deployments created after this JavaScript timestamp. (e.g. 1540095775941)
  --until: float # Get Deployments created before this JavaScript timestamp. (e.g. 1540095775951)
  --state: string # Filter deployments based on their state (`BUILDING`, `ERROR`, `INITIALIZING`, `QUEUED`, `READY`, `CANCELED`, `BLOCKED`) (e.g. BUILDING,READY)
  --rollbackCandidate: string@bool-completer # Filter deployments based on their rollback candidacy
  --branch: string # Filter deployments based on the branch name
  --sha: string # Filter deployments based on the SHA
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<pagination: record<count: float, next: float, prev: float>, deployments: table<uid: string, name: string, projectId: string, url: string, created: float, defaultRoute: string, deleted: float, undeleted: float, softDeletedByRetention: bool, source: string, state: string, readyState: string, type: string, creator: record, meta: record, target: string, aliasError: record, aliasAssigned: any, createdAt: float, buildingAt: float, ready: float, readySubstate: string, checksState: string, checksConclusion: string, checks: record, inspectorUrl: string, errorCode: string, errorMessage: string, oomReport: string, isRollbackCandidate: bool, prebuilt: bool, manualProvisioning: record, projectSettings: record, connectBuildsEnabled: bool, connectConfigurationId: string, passiveConnectConfigurationId: string, expiration: float, proposedExpiration: float, platform: record, customEnvironment: record, seatBlock: record, attribution: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app" $app "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "projectIds" $projectIds "multi") (serialize-qp "target" $target "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "rollbackCandidate" $rollbackCandidate "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "sha" $sha "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v7/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Deployment
#
# DELETE /v13/deployments/{id}
# operationId: deleteDeployment
export def "deployments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # A Deployment or Alias URL. In case it is passed, the ID will be ignored (e.g. https://files-orcin-xi.vercel.app/)
  --teamId: string # The Team identifier to perform the request on behalf of. (e.g. team_1a2b3c4d5e6f7g8h9i0j1k2l)
  --slug: string # The Team slug to perform the request on behalf of. (e.g. my-team-url-slug)
]: nothing -> record<uid: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v13/deployments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
