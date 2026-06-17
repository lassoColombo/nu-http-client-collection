# Auto-generated client for Orbit API vv1
# Source: https://api.apis.guru/v2/specs/orbit.love/v1/openapi.json
# Auth: --token flag or $env.ORBIT_API_TOKEN

const BASE_URL = "https://app.orbit.love/api/v1"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORBIT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["https://app.orbit.love/api/v1"] }
def auth-scheme-completer [] { ["query-api_key" "bearer"] }

# Completers for enum parameters
def affiliation-completer [] { ["member" "teammate"] }
def activity-type-completer [] { ["custom:happened" "dev:comment" "discord:message:replied" "discord:message:sent" "discord:server:joined" "discord:thread:replied" "discourse:post:created" "discourse:post:liked" "discourse:topic:created" "discourse:user:created" "discussions:comment" "discussions:discussion_created" "discussions:reply" "fork:created" "insided:article:created" "insided:article:replied" "insided:conversation:replied" "insided:conversation:started" "insided:idea:replied" "insided:idea:submitted" "insided:question:asked" "insided:question:replied" "issue_comment:created" "issues:opened" "linkedin:comment" "note:created" "post:created" "pull_requests:merged" "pull_requests:opened" "reddit:comment" "reddit:post" "slack:channel:joined" "slack:message:sent" "slack:thread:replied" "stackoverflow:answer" "stackoverflow:question" "star:created" "tweet:sent" "twitter:followed" "youtube:comment"] }
def identity-completer [] { ["devto" "discord" "discourse" "email" "github" "linkedin" "slack" "twitter"] }
def direction-completer [] { ["ASC" "DESC"] }
def items-completer [] { ["10" "100" "50"] }
def sort-completer [] { ["member" "occurred_at"] }
def sort-completer-1 [] { ["activities_count" "company" "created_at" "first_activity" "github_followers" "id" "last_activity" "location" "love" "name" "orbit" "reach" "title" "twitter_followers" "updated_at"] }
def sort-completer-2 [] { ["employees_count" "members_count" "name" "website"] }
def activity-type-completer-1 [] { ["content" "custom" "discord" "discourse" "github" "slack" "twitter"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "user get" } } | get name | first)
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

# Get info about the current user
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all workspaces for the current user
#
# GET /workspaces
export def "workspaces list" [
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
  let full_url = (build-url $base "/workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a workspace
#
# GET /workspaces/{workspace_slug}
export def "workspaces get" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-orbit-level-counts: oneof<nothing, bool> # Include the number of members by Orbit Level in the attributes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_orbit_level_counts" $include_orbit_level_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/workspaces/{workspace_slug}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List activities for a workspace
#
# GET /{workspace_slug}/activities
@deprecated --flag type
export def "activities list" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --affiliation: string@affiliation-completer
  --member-tags: string # The list of tags to filter against. Separate tags with `,` to do an intersection (AND), or with `|` to do a union (OR)
  --orbit: string # The list of orbit levels to filter against. Accepted values are 1, 2, 3, 4, n. In the request, a format like `23` would include levels 2 and 3. `n` is for members with no orbit level.
  --activity-type: string@activity-type-completer # Comma separated list of activity types
  --identity: string@identity-completer
  --company: string # Comma separated list of companies. The union (OR) of companies is applied.
  --title: string # Comma separated list of job titles. The union (OR) of job titles is applied.
  --regions: string # Comma separated list of regions. The union (OR) of regions is applied.
  --countries: string # Comma separated list of countries. The union (OR) of countries is applied.
  --cities: string # Comma separated list of cities. The union (OR) of cities is applied.
  --start-date: string # Filter activities after this date. Format: YYYY-MM-DD.
  --end-date: string # Filter activities before this date. Format: YYYY-MM-DD.
  --relative: string # Relative timeframes. Format: this_<integer>_<period>, with period in [days, weeks, months, years]. For example, this_30_days.
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer
  --type: string # Deprecated in favor of the activity_type parameter. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "affiliation" $affiliation "scalar") (serialize-qp "member_tags" $member_tags "scalar") (serialize-qp "orbit" $orbit "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "identity" $identity "scalar") (serialize-qp "company[]" $company "scalar") (serialize-qp "title[]" $title "scalar") (serialize-qp "regions[]" $regions "scalar") (serialize-qp "countries[]" $countries "scalar") (serialize-qp "cities[]" $cities "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "relative" $relative "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Custom or a Content activity for a new or existing member
#
# POST /{workspace_slug}/activities
# --identity shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
export def "activities post" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity: any
  --identity: record # Represents an email address, a profile on networks like github and twitter, or a record in another system. — shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/activities"))
  let body = {"activity": $activity, "identity": $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an activity in the workspace
#
# GET /{workspace_slug}/activities/{id}
export def "activities get" [
  workspace_slug: string
  id: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, id: $id} | format pattern "/{workspace_slug}/activities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all activity types for a workspace
#
# GET /{workspace_slug}/activity_types
export def "activity-types get" [
  workspace_slug: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/activity_types"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List members in a workspace
#
# GET /{workspace_slug}/members
@deprecated --flag type
export def "members list" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --affiliation: string@affiliation-completer
  --member-tags: string # The list of tags to filter against. Separate tags with `,` to do an intersection (AND), or with `|` to do a union (OR)
  --orbit: string # The list of orbit levels to filter against. Accepted values are 1, 2, 3, 4, n. In the request, a format like `23` would include levels 2 and 3. `n` is for members with no orbit level.
  --activity-type: string@activity-type-completer # Comma separated list of activity types
  --identity: string@identity-completer
  --company: string # Comma separated list of companies. The union (OR) of companies is applied.
  --title: string # Comma separated list of job titles. The union (OR) of job titles is applied.
  --regions: string # Comma separated list of regions. The union (OR) of regions is applied.
  --countries: string # Comma separated list of countries. The union (OR) of countries is applied.
  --cities: string # Comma separated list of cities. The union (OR) of cities is applied.
  --start-date: string # Filter activities after this date. Format: YYYY-MM-DD.
  --end-date: string # Filter activities before this date. Format: YYYY-MM-DD.
  --relative: string # Relative timeframes. Format: this_<integer>_<period>, with period in [days, weeks, months, years]. For example, this_30_days.
  --query: string
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --activities-count-min: string
  --activities-count-max: string
  --qp-sort: string@sort-completer-1
  --type: string # Deprecated in favor of the activity_type parameter. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "affiliation" $affiliation "scalar") (serialize-qp "member_tags" $member_tags "scalar") (serialize-qp "orbit" $orbit "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "identity" $identity "scalar") (serialize-qp "company[]" $company "scalar") (serialize-qp "title[]" $title "scalar") (serialize-qp "regions[]" $regions "scalar") (serialize-qp "countries[]" $countries "scalar") (serialize-qp "cities[]" $cities "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "relative" $relative "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "activities_count_min" $activities_count_min "scalar") (serialize-qp "activities_count_max" $activities_count_max "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a member
#
# POST /{workspace_slug}/members
# --identity shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
# --member shape: {bio?: string, birthday?: string, company?: string, devto?: string, email?: string, github?: string, linkedin?: string, location?: string, name?: string, pronouns?: string, shipping_address?: string, slug?: string, tag_list?: string, tags?: string, tags_to_add?: string, teammate?: bool, title?: string, tshirt?: string, twitter?: string, url?: string}
export def "members post" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # Represents an email address, a profile on networks like github and twitter, or a record in another system. — shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
  --member: record # shape: {bio?: string, birthday?: string, company?: string, devto?: string, email?: string, github?: string, linkedin?: string, location?: string, name?: string, pronouns?: string, shipping_address?: string, slug?: string, tag_list?: string, tags?: string, tags_to_add?: string, teammate?: bool, title?: string, tshirt?: string, twitter?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/members"))
  let body = {"identity": $identity, "member": $member} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find a member by an identity
#
# GET /{workspace_slug}/members/find
export def "members-find get" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string
  --source-host: string
  --uid: string
  --username: string
  --email: string
  --github: string # Deprecated, please use source=github and username=<username> instead
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "source_host" $source_host "scalar") (serialize-qp "uid" $uid "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "github" $github "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/members/find") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a member
#
# DELETE /{workspace_slug}/members/{member_slug}
export def "members delete" [
  workspace_slug: string
  member_slug: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a member
#
# GET /{workspace_slug}/members/{member_slug}
export def "members get" [
  workspace_slug: string
  member_slug: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a member
#
# PUT /{workspace_slug}/members/{member_slug}
export def "members put" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bio: string
  --birthday: string
  --company: string
  --devto: string # The member's DEV username
  --email: string # The member's email
  --github: string # The member's GitHub username
  --linkedin: string # The member's LinkedIn username, without the in/ or pub/
  --location: string
  --name: string
  --pronouns: string
  --shipping-address: string
  --slug: string
  --tag-list: string # Deprecated: Please use the tags attribute instead
  --tags: string # Replaces all tags for the member; comma-separated string or array
  --tags-to-add: string # Adds tags to member; comma-separated string or array
  --teammate: oneof<nothing, bool>
  --title: string
  --tshirt: string
  --twitter: string # The member's Twitter username
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}"))
  let body = {"bio": $bio, "birthday": $birthday, "company": $company, "devto": $devto, "email": $email, "github": $github, "linkedin": $linkedin, "location": $location, "name": $name, "pronouns": $pronouns, "shipping_address": $shipping_address, "slug": $slug, "tag_list": $tag_list, "tags": $tags, "tags_to_add": $tags_to_add, "teammate": $teammate, "title": $title, "tshirt": $tshirt, "twitter": $twitter, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List activities for a member
#
# GET /{workspace_slug}/members/{member_slug}/activities
@deprecated --flag type
export def "members-activities get" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer
  --activity-type: string
  --type: string # Deprecated in favor of the activity_type parameter. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Custom or a Content activity for a member
#
# POST /{workspace_slug}/members/{member_slug}/activities
export def "members-activities post" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-type: string # The type of activity - what action was done by the member. This is a legacy field, use activity_type_key instead.
  --activity-type-key: string # The key for a custom activity type for the workspace. Will create a new activity type if it does not exist.
  --description: string # A description of the activity; displayed in the timeline
  --key: string # Supply a key that must be unique or leave blank to have one generated.
  --link: string # A URL for the activity; displayed in the timeline
  --link-text: string # The text for the timeline link
  --occurred-at: string # The date and time the activity occurred; defaults to now
  --properties: record # Key-value pairs to provide contextual metadata about an activity.
  --title: string # A title for the activity; displayed in the timeline
  --weight: string # A custom weight to be used in filters and reports; defaults to 1.
  --body-url: string # The url representing the post
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}/activities"))
  let body = {"activity_type": $activity_type, "activity_type_key": $activity_type_key, "description": $description, "key": $key, "link": $link, "link_text": $link_text, "occurred_at": $occurred_at, "properties": $properties, "title": $title, "weight": $weight, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a post activity
#
# DELETE /{workspace_slug}/members/{member_slug}/activities/{id}
export def "members-activities delete" [
  workspace_slug: string
  member_slug: string
  id: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug, id: $id} | format pattern "/{workspace_slug}/members/{member_slug}/activities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a custom activity for a member
#
# PUT /{workspace_slug}/members/{member_slug}/activities/{id}
export def "members-activities put" [
  workspace_slug: string
  member_slug: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-type: string # The type of activity - what action was done by the member. This is a legacy field, use activity_type_key instead.
  --activity-type-key: string # The key for a custom activity type for the workspace. Will create a new activity type if it does not exist.
  --description: string # A description of the activity; displayed in the timeline
  --key: string # Supply a key that must be unique or leave blank to have one generated.
  --link: string # A URL for the activity; displayed in the timeline
  --link-text: string # The text for the timeline link
  --occurred-at: string # The date and time the activity occurred; defaults to now
  --properties: record # Key-value pairs to provide contextual metadata about an activity.
  title: string # A title for the activity; displayed in the timeline
  --weight: string # A custom weight to be used in filters and reports; defaults to 1.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug, id: $id} | format pattern "/{workspace_slug}/members/{member_slug}/activities/{id}"))
  let body = {"activity_type": $activity_type, "activity_type_key": $activity_type_key, "description": $description, "key": $key, "link": $link, "link_text": $link_text, "occurred_at": $occurred_at, "properties": $properties, "title": $title, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove identity from a member
#
# DELETE /{workspace_slug}/members/{member_slug}/identities
export def "members-identities delete" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the person in the source system
  --name: string # The name of the person in the source system
  --body-source: string # The type of source: known values include github, twitter, discourse, email, linkedin, devto. Custom values can also be used
  --source-host: string # Specifies the location of the source, such as the host of a Discourse instance
  --uid: string # The uid of the person in the source system
  --body-url: string # For custom identities, an optional link to the profile on the source system
  --username: string # The username of the person in the source system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}/identities"))
  let body = {"email": $email, "name": $name, "source": $body_source, "source_host": $source_host, "uid": $uid, "url": $body_url, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add identity to a member
#
# POST /{workspace_slug}/members/{member_slug}/identities
export def "members-identities post" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the person in the source system
  --name: string # The name of the person in the source system
  --body-source: string # The type of source: known values include github, twitter, discourse, email, linkedin, devto. Custom values can also be used
  --source-host: string # Specifies the location of the source, such as the host of a Discourse instance
  --uid: string # The uid of the person in the source system
  --body-url: string # For custom identities, an optional link to the profile on the source system
  --username: string # The username of the person in the source system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}/identities"))
  let body = {"email": $email, "name": $name, "source": $body_source, "source_host": $source_host, "uid": $uid, "url": $body_url, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the member's notes
#
# GET /{workspace_slug}/members/{member_slug}/notes
export def "members-notes get" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}/notes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a note
#
# POST /{workspace_slug}/members/{member_slug}/notes
export def "members-notes post" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug} | format pattern "/{workspace_slug}/members/{member_slug}/notes"))
  let body = {"body": $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a note
#
# PUT /{workspace_slug}/members/{member_slug}/notes/{id}
export def "members-notes put" [
  workspace_slug: string
  member_slug: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, member_slug: $member_slug, id: $id} | format pattern "/{workspace_slug}/members/{member_slug}/notes/{id}"))
  let body = {"body": $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List organizations in a workspace
#
# GET /{workspace_slug}/organizations
export def "organizations list" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer-2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/organizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an organization
#
# GET /{workspace_slug}/organizations/{organization_id}
export def "organizations get" [
  workspace_slug: string
  organization_id: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, organization_id: $organization_id} | format pattern "/{workspace_slug}/organizations/{organization_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# PUT /{workspace_slug}/organizations/{organization_id}
export def "organizations put" [
  workspace_slug: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --crm-uid: string # The unique identifier of the organization in your CRM.
  crm_url: string # A link to the organization profile in your CRM.
  --deal-closed-date: string # The date the organization became a customer.
  lifecycle_stage: string # The current stage of the organization in the marketing or sales process.
  --owner-email: string # The email of the team member who is in charge of the organization.
  --owner-name: string # The name of the team member who is in charge of the organization.
  --price-plan: string # The pricing plan the organization is on.
  --body-source: string # The name of the CRM you use for tracking the organization.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, organization_id: $organization_id} | format pattern "/{workspace_slug}/organizations/{organization_id}"))
  let body = {"crm_uid": $crm_uid, "crm_url": $crm_url, "deal_closed_date": $deal_closed_date, "lifecycle_stage": $lifecycle_stage, "owner_email": $owner_email, "owner_name": $owner_name, "price_plan": $price_plan, "source": $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List member activities in an organization
#
# GET /{workspace_slug}/organizations/{organization_id}/activities
export def "organizations-activities get" [
  workspace_slug: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer
  --activity-type: string@activity-type-completer-1
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "activity_type" $activity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, organization_id: $organization_id} | format pattern "/{workspace_slug}/organizations/{organization_id}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List members in an organization
#
# GET /{workspace_slug}/organizations/{organization_id}/members
export def "organizations-members get" [
  workspace_slug: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
  --items: string@items-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "items" $items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, organization_id: $organization_id} | format pattern "/{workspace_slug}/organizations/{organization_id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a workspace stats
#
# GET /{workspace_slug}/reports
@deprecated --flag type
export def "reports get" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Filter activities after this date. Format: YYYY-MM-DD.
  --end-date: string # Filter activities before this date. Format: YYYY-MM-DD.
  --relative: string # Relative timeframes. Format: this_<integer>_<period>, with period in [days, weeks, months, years]. For example, this_30_days.
  --properties: string
  --activity-type: string
  --type: string # Deprecated in favor of the activity_type parameter. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "relative" $relative "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List webhooks in a workspace
#
# GET /{workspace_slug}/webhooks
export def "webhooks list" [
  workspace_slug: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /{workspace_slug}/webhooks
export def "webhooks post" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-tags: list
  --activity-types: list
  event_type: string
  --member-tags: list
  name: string
  --secret: string
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug} | format pattern "/{workspace_slug}/webhooks"))
  let body = {"activity_tags": $activity_tags, "activity_types": $activity_types, "event_type": $event_type, "member_tags": $member_tags, "name": $name, "secret": $secret, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /{workspace_slug}/webhooks/{id}
export def "webhooks delete" [
  workspace_slug: string
  id: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, id: $id} | format pattern "/{workspace_slug}/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /{workspace_slug}/webhooks/{id}
export def "webhooks get" [
  workspace_slug: string
  id: string
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
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, id: $id} | format pattern "/{workspace_slug}/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /{workspace_slug}/webhooks/{id}
export def "webhooks put" [
  workspace_slug: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-tags: list
  --activity-types: list
  event_type: string
  --member-tags: list
  name: string
  --secret: string
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workspace_slug: $workspace_slug, id: $id} | format pattern "/{workspace_slug}/webhooks/{id}"))
  let body = {"activity_tags": $activity_tags, "activity_types": $activity_types, "event_type": $event_type, "member_tags": $member_tags, "name": $name, "secret": $secret, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
