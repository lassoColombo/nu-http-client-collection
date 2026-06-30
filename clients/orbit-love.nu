# Auto-generated client for Orbit API vv1
# Source: https://api.apis.guru/v2/specs/orbit.love/v1/openapi.json
# Auth: --token flag or $env.ORBIT_API_TOKEN

const BASE_URL = "https://app.orbit.love/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ORBIT_API_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base "/user" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/workspaces" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/workspaces/{workspace_slug}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_orbit_level_counts": $include_orbit_level_counts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/activities") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"affiliation": $affiliation, "member_tags": $member_tags, "orbit": $orbit, "activity_type": $activity_type, "identity": $identity, "company[]": $company, "title[]": $title, "regions[]": $regions, "countries[]": $countries, "cities[]": $cities, "start_date": $start_date, "end_date": $end_date, "relative": $relative, "page": $page, "direction": $direction, "items": $items, "sort": $qp_sort, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/activities") $auth.query)
  let req_body = {"activity": $activity, "identity": $identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/activities/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/activity_types") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"affiliation": $affiliation, "member_tags": $member_tags, "orbit": $orbit, "activity_type": $activity_type, "identity": $identity, "company[]": $company, "title[]": $title, "regions[]": $regions, "countries[]": $countries, "cities[]": $cities, "start_date": $start_date, "end_date": $end_date, "relative": $relative, "query": $query, "page": $page, "direction": $direction, "items": $items, "activities_count_min": $activities_count_min, "activities_count_max": $activities_count_max, "sort": $qp_sort, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/members") $auth.query)
  let req_body = {"identity": $identity, "member": $member} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/members/find") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"source": $qp_source, "source_host": $source_host, "uid": $uid, "username": $username, "email": $email, "github": $github} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}") $auth.query)
  let req_body = {"bio": $bio, "birthday": $birthday, "company": $company, "devto": $devto, "email": $email, "github": $github, "linkedin": $linkedin, "location": $location, "name": $name, "pronouns": $pronouns, "shipping_address": $shipping_address, "slug": $slug, "tag_list": $tag_list, "tags": $tags, "tags_to_add": $tags_to_add, "teammate": $teammate, "title": $title, "tshirt": $tshirt, "twitter": $twitter, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/activities") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "direction": $direction, "items": $items, "sort": $qp_sort, "activity_type": $activity_type, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/activities") $auth.query)
  let req_body = {"activity_type": $activity_type, "activity_type_key": $activity_type_key, "description": $description, "key": $key, "link": $link, "link_text": $link_text, "occurred_at": $occurred_at, "properties": $properties, "title": $title, "weight": $weight, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/members/{member_slug}/activities/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/members/{member_slug}/activities/{id}") $auth.query)
  let req_body = {"activity_type": $activity_type, "activity_type_key": $activity_type_key, "description": $description, "key": $key, "link": $link, "link_text": $link_text, "occurred_at": $occurred_at, "properties": $properties, "title": $title, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/identities") $auth.query)
  let req_body = {"email": $email, "name": $name, "source": $body_source, "source_host": $source_host, "uid": $uid, "url": $url, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/identities") $auth.query)
  let req_body = {"email": $email, "name": $name, "source": $body_source, "source_host": $source_host, "uid": $uid, "url": $url, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/notes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug)} | format pattern "/{workspace_slug}/members/{member_slug}/notes") $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), member_slug: (encode-path-segment $member_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/members/{member_slug}/notes/{id}") $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/organizations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "page": $page, "direction": $direction, "items": $items, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}") $auth.query)
  let req_body = {"crm_uid": $crm_uid, "crm_url": $crm_url, "deal_closed_date": $deal_closed_date, "lifecycle_stage": $lifecycle_stage, "owner_email": $owner_email, "owner_name": $owner_name, "price_plan": $price_plan, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}/activities") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "direction": $direction, "items": $items, "sort": $qp_sort, "activity_type": $activity_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), organization_id: (encode-path-segment $organization_id)} | format pattern "/{workspace_slug}/organizations/{organization_id}/members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "items": $items} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/reports") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_date": $start_date, "end_date": $end_date, "relative": $relative, "properties": $properties, "activity_type": $activity_type, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/webhooks") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug)} | format pattern "/{workspace_slug}/webhooks") $auth.query)
  let req_body = {"activity_tags": $activity_tags, "activity_types": $activity_types, "event_type": $event_type, "member_tags": $member_tags, "name": $name, "secret": $secret, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/webhooks/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/webhooks/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({workspace_slug: (encode-path-segment $workspace_slug), id: (encode-path-segment $id)} | format pattern "/{workspace_slug}/webhooks/{id}") $auth.query)
  let req_body = {"activity_tags": $activity_tags, "activity_types": $activity_types, "event_type": $event_type, "member_tags": $member_tags, "name": $name, "secret": $secret, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}
