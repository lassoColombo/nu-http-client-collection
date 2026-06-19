# Auto-generated client for Orbit API vv1
# Source: https://api.apis.guru/v2/specs/orbit.love/v1/openapi.json
# Auth: --token flag or $env.ORBIT_API_TOKEN

const BASE_URL = "https://app.orbit.love/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORBIT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-orbit-level-counts: oneof<nothing, bool> # Include the number of members by Orbit Level in the attributes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let qp = [(serialize-qp "include_orbit_level_counts" $include_orbit_level_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/workspaces/{workspace_slug}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_orbit_level_counts": $include_orbit_level_counts} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --relative: string # Relative timeframes. Format: this__, with period in [days, weeks, months, years]. For example, this_30_days.
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer
  --type: string # Deprecated in favor of the activity_type parameter. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let qp = [(serialize-qp "affiliation" $affiliation "scalar") (serialize-qp "member_tags" $member_tags "scalar") (serialize-qp "orbit" $orbit "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "identity" $identity "scalar") (serialize-qp "company[]" $company "scalar") (serialize-qp "title[]" $title "scalar") (serialize-qp "regions[]" $regions "scalar") (serialize-qp "countries[]" $countries "scalar") (serialize-qp "cities[]" $cities "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "relative" $relative "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"affiliation": $affiliation, "member_tags": $member_tags, "orbit": $orbit, "activity_type": $activity_type, "identity": $identity, "company[]": $company, "title[]": $title, "regions[]": $regions, "countries[]": $countries, "cities[]": $cities, "start_date": $start_date, "end_date": $end_date, "relative": $relative, "page": $page, "direction": $direction, "items": $items, "sort": $qp_sort, "type": $type} | compact), body: null}
}

# Create a Custom or a Content activity for a new or existing member
#
# POST /{workspace_slug}/activities
# --identity shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
export def "activities create" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity: any
  --identity: record # Represents an email address, a profile on networks like github and twitter, or a record in another system. — shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/activities"))
  let req_body = {"activity": $activity, "identity": $identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/activities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/activity_types"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --relative: string # Relative timeframes. Format: this__, with period in [days, weeks, months, years]. For example, this_30_days.
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
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let qp = [(serialize-qp "affiliation" $affiliation "scalar") (serialize-qp "member_tags" $member_tags "scalar") (serialize-qp "orbit" $orbit "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "identity" $identity "scalar") (serialize-qp "company[]" $company "scalar") (serialize-qp "title[]" $title "scalar") (serialize-qp "regions[]" $regions "scalar") (serialize-qp "countries[]" $countries "scalar") (serialize-qp "cities[]" $cities "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "relative" $relative "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "activities_count_min" $activities_count_min "scalar") (serialize-qp "activities_count_max" $activities_count_max "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"affiliation": $affiliation, "member_tags": $member_tags, "orbit": $orbit, "activity_type": $activity_type, "identity": $identity, "company[]": $company, "title[]": $title, "regions[]": $regions, "countries[]": $countries, "cities[]": $cities, "start_date": $start_date, "end_date": $end_date, "relative": $relative, "query": $query, "page": $page, "direction": $direction, "items": $items, "activities_count_min": $activities_count_min, "activities_count_max": $activities_count_max, "sort": $qp_sort, "type": $type} | compact), body: null}
}

# Create or update a member
#
# POST /{workspace_slug}/members
# --identity shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
# --member shape: {bio?: string, birthday?: string, company?: string, devto?: string, email?: string, github?: string, linkedin?: string, location?: string, name?: string, pronouns?: string, shipping_address?: string, slug?: string, tag_list?: string, tags?: string, tags_to_add?: string, teammate?: bool, title?: string, tshirt?: string, twitter?: string, url?: string}
export def "members create" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # Represents an email address, a profile on networks like github and twitter, or a record in another system. — shape: {email?: string, name?: string, source: string, source_host?: string, uid?: string, url?: string, username?: string}
  --member: record # shape: {bio?: string, birthday?: string, company?: string, devto?: string, email?: string, github?: string, linkedin?: string, location?: string, name?: string, pronouns?: string, shipping_address?: string, slug?: string, tag_list?: string, tags?: string, tags_to_add?: string, teammate?: bool, title?: string, tshirt?: string, twitter?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/members"))
  let req_body = {"identity": $identity, "member": $member} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string
  --source-host: string
  --uid: string
  --username: string
  --email: string
  --github: string # Deprecated, please use source=github and username= instead
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "source_host" $source_host "scalar") (serialize-qp "uid" $uid "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "github" $github "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/members/find") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"source": $qp_source, "source_host": $source_host, "uid": $uid, "username": $username, "email": $email, "github": $github} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a member
#
# PUT /{workspace_slug}/members/{member_slug}
export def "members update" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}"))
  let req_body = {"bio": $bio, "birthday": $birthday, "company": $company, "devto": $devto, "email": $email, "github": $github, "linkedin": $linkedin, "location": $location, "name": $name, "pronouns": $pronouns, "shipping_address": $shipping_address, "slug": $slug, "tag_list": $tag_list, "tags": $tags, "tags_to_add": $tags_to_add, "teammate": $teammate, "title": $title, "tshirt": $tshirt, "twitter": $twitter, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "direction": $direction, "items": $items, "sort": $qp_sort, "activity_type": $activity_type, "type": $type} | compact), body: null}
}

# Create a Custom or a Content activity for a member
#
# POST /{workspace_slug}/members/{member_slug}/activities
export def "members-activities create" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --url: string # The url representing the post
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/activities"))
  let req_body = {"activity_type": $activity_type, "activity_type_key": $activity_type_key, "description": $description, "key": $key, "link": $link, "link_text": $link_text, "occurred_at": $occurred_at, "properties": $properties, "title": $title, "weight": $weight, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/members/{member_slug}/activities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a custom activity for a member
#
# PUT /{workspace_slug}/members/{member_slug}/activities/{id}
export def "members-activities update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/members/{member_slug}/activities/{id}"))
  let req_body = {"activity_type": $activity_type, "activity_type_key": $activity_type_key, "description": $description, "key": $key, "link": $link, "link_text": $link_text, "occurred_at": $occurred_at, "properties": $properties, "title": $title, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the person in the source system
  --name: string # The name of the person in the source system
  --body-source: string # The type of source: known values include github, twitter, discourse, email, linkedin, devto. Custom values can also be used
  --source-host: string # Specifies the location of the source, such as the host of a Discourse instance
  --uid: string # The uid of the person in the source system
  --url: string # For custom identities, an optional link to the profile on the source system
  --username: string # The username of the person in the source system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/identities"))
  let req_body = {"email": $email, "name": $name, "source": $body_source, "source_host": $source_host, "uid": $uid, "url": $url, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add identity to a member
#
# POST /{workspace_slug}/members/{member_slug}/identities
export def "members-identities create" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the person in the source system
  --name: string # The name of the person in the source system
  --body-source: string # The type of source: known values include github, twitter, discourse, email, linkedin, devto. Custom values can also be used
  --source-host: string # Specifies the location of the source, such as the host of a Discourse instance
  --uid: string # The uid of the person in the source system
  --url: string # For custom identities, an optional link to the profile on the source system
  --username: string # The username of the person in the source system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/identities"))
  let req_body = {"email": $email, "name": $name, "source": $body_source, "source_host": $source_host, "uid": $uid, "url": $url, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/notes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page} | compact), body: null}
}

# Create a note
#
# POST /{workspace_slug}/members/{member_slug}/notes
export def "members-notes create" [
  workspace_slug: string
  member_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/notes"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a note
#
# PUT /{workspace_slug}/members/{member_slug}/notes/{id}
export def "members-notes update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($member_slug | is-empty) { error make --unspanned { msg: "path parameter 'member_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/members/{member_slug}/notes/{id}"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer-2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/organizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "page": $page, "direction": $direction, "items": $items, "sort": $qp_sort} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'organization_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an organization
#
# PUT /{workspace_slug}/organizations/{organization_id}
export def "organizations update" [
  workspace_slug: string
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'organization_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}"))
  let req_body = {"crm_uid": $crm_uid, "crm_url": $crm_url, "deal_closed_date": $deal_closed_date, "lifecycle_stage": $lifecycle_stage, "owner_email": $owner_email, "owner_name": $owner_name, "price_plan": $price_plan, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
  --direction: string@direction-completer
  --items: string@items-completer
  --qp-sort: string@sort-completer
  --activity-type: string@activity-type-completer-1
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'organization_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "items" $items "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "activity_type" $activity_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "direction": $direction, "items": $items, "sort": $qp_sort, "activity_type": $activity_type} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string
  --items: string@items-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'organization_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "items" $items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "items": $items} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Filter activities after this date. Format: YYYY-MM-DD.
  --end-date: string # Filter activities before this date. Format: YYYY-MM-DD.
  --relative: string # Relative timeframes. Format: this__, with period in [days, weeks, months, years]. For example, this_30_days.
  --properties: string
  --activity-type: string
  --type: string # Deprecated in favor of the activity_type parameter. (DEPRECATED)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "relative" $relative "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "activity_type" $activity_type "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "relative": $relative, "properties": $properties, "activity_type": $activity_type, "type": $type} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a webhook
#
# POST /{workspace_slug}/webhooks
export def "webhooks create" [
  workspace_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-tags: list<string>
  --activity-types: list<string>
  event_type: string
  --member-tags: list<string>
  name: string
  --secret: string
  url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/webhooks"))
  let req_body = {"activity_tags": $activity_tags, "activity_types": $activity_types, "event_type": $event_type, "member_tags": $member_tags, "name": $name, "secret": $secret, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a webhook
#
# PUT /{workspace_slug}/webhooks/{id}
export def "webhooks update" [
  workspace_slug: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-tags: list<string>
  --activity-types: list<string>
  event_type: string
  --member-tags: list<string>
  name: string
  --secret: string
  url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_slug | is-empty) { error make --unspanned { msg: "path parameter 'workspace_slug' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/webhooks/{id}"))
  let req_body = {"activity_tags": $activity_tags, "activity_types": $activity_types, "event_type": $event_type, "member_tags": $member_tags, "name": $name, "secret": $secret, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
