# Auto-generated client for OpenProject API V3 (Stable) v3
# Source: https://community.openproject.org/api/v3/spec.json
# Auth: --token flag or $env.OPENPROJECT_API_V3_STABLE_TOKEN

const BASE_URL = "https://community.openproject.org"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENPROJECT_API_V3_STABLE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://community.openproject.org"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def type-completer [] { ["NonWorkingDay"] }
def type-completer-1 [] { ["Collection"] }
def type-completer-2 [] { ["WeekDay"] }
def state-completer [] { ["cancelled" "closed" "draft" "in_progress" "open"] }
def sharing-completer [] { ["descendants" "none" "system"] }
def itemType-completer [] { ["simple" "work_package"] }
def type-completer-3 [] { ["Portfolio"] }
def type-completer-4 [] { ["Program"] }
def type-completer-5 [] { ["Project"] }
def workspace-type-completer [] { ["portfolio" "program" "project"] }
def frequency-completer [] { ["daily" "monthly_day_of_month" "monthly_nth_weekday" "weekly" "working_days"] }
def monthlyOrdinal-completer [] { ["-1" "1" "2" "3" "4"] }
def monthlyWeekday-completer [] { ["friday" "monday" "saturday" "sunday" "thursday" "tuesday" "wednesday"] }
def endAfter-completer [] { ["iterations" "never" "specific_date"] }
def type-completer-6 [] { ["blocked" "blocks" "duplicated" "duplicates" "follows" "includes" "partof" "precedes" "relates" "required" "requires"] }
def type-completer-7 [] { ["UserNonWorkingTime"] }
def type-completer-8 [] { ["UserWorkingHours"] }
def status-completer [] { ["closed" "locked" "open"] }
def sharing-completer-1 [] { ["descendants" "hierarchy" "none" "system" "tree"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "root root" } } | get name | first)
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

# View root
#
# GET /api/v3
# operationId: view_root
export def "root root" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List actions
#
# GET /api/v3/actions
# operationId: List_actions
export def "actions actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + id: Returns only the action having the id or all actions except those having the id(s). (e.g. [{ "id": { "operator": "=", "values": ["memberships/create"] }" }])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + *No sort supported yet* (default: [["id", "asc"]], e.g. [["id", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/actions" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View action
#
# GET /api/v3/actions/{id}
# operationId: View_action
export def "actions action" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/actions/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an activity
#
# GET /api/v3/activities/{id}
# operationId: get_activity
export def "activities activity-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/activities/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update activity
#
# PATCH /api/v3/activities/{id}
# operationId: update_activity
# --comment shape: {raw?: string}
export def "activities activity-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: record # shape: {raw?: string}
  --internal: oneof<nothing, bool> # Determines whether this comment is internal. This is only available to users with `add_internal_comments` permission. It defaults to `false`, if unset. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/activities/($id)")
  let body = {comment: $comment, internal: $internal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List attachments by activity
#
# GET /api/v3/activities/{id}/attachments
# operationId: list_activity_attachments
export def "activities-attachments attachments" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/activities/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add attachment to activity
#
# POST /api/v3/activities/{id}/attachments
# operationId: create_activity_attachment
# --metadata shape: {fileName?: string}
export def "activities-attachments attachment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # shape: {fileName?: string}
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/activities/($id)/attachments")
  let body = {metadata: $metadata, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List emoji reactions by activity
#
# GET /api/v3/activities/{id}/emoji_reactions
# operationId: list_activity_emoji_reactions
export def "activities-emoji-reactions reactions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/activities/($id)/emoji_reactions")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Toggle emoji reaction for an activity
#
# PATCH /api/v3/activities/{id}/emoji_reactions
# operationId: toggle_activity_emoji_reaction
export def "activities-emoji-reactions reaction" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/activities/($id)/emoji_reactions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/hal+json" $body
}

# Create Attachment
#
# POST /api/v3/attachments
# operationId: create_attachment
export def "attachments attachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete attachment
#
# DELETE /api/v3/attachments/{id}
# operationId: delete_attachment
export def "attachments attachment-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/attachments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View attachment
#
# GET /api/v3/attachments/{id}
# operationId: view_attachment
export def "attachments attachment-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/attachments/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# view Budget
#
# GET /api/v3/budgets/{id}
# operationId: view_Budget
export def "budgets Budget" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/budgets/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List capabilities
#
# GET /api/v3/capabilities
# operationId: List_capabilities
export def "capabilities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint.  + action: Get all capabilities of a certain action  + principal: Get all capabilities of a principal  + context: Get all capabilities within a context. Note that for a workspace context the client needs to   provide `w{id}`, e.g. `w5` and for the global context a `g`.    + **Deprecation**: The now deprecated context `p` for project still works, but must eventually be replaced     with the `w` for the workspace context. (e.g. [{ "principal": { "operator": "=", "values": ["1"] }" }])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by the capabilities id (default: [["id", "asc"]], e.g. [["id", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/capabilities" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View global context
#
# GET /api/v3/capabilities/context/global
# operationId: View_global_context
export def "capabilities-context-global context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/capabilities/context/global")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View capabilities
#
# GET /api/v3/capabilities/{id}
# operationId: View_capabilities
export def "capabilities capabilities" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/capabilities/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Category
#
# GET /api/v3/categories/{id}
# operationId: View_Category
export def "categories Category" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/categories/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View configuration
#
# GET /api/v3/configuration
# operationId: View_configuration
export def "configuration configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/configuration")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom action
#
# GET /api/v3/custom_actions/{id}
# operationId: get_custom_action
export def "custom-actions action" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/custom_actions/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute custom action
#
# POST /api/v3/custom_actions/{id}/execute
# operationId: Execute_custom_action
# --_links shape: {workPackage?: record}
export def "custom-actions-execute action" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {workPackage?: record}
  --lockVersion: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/custom_actions/($id)/execute")
  let body = {_links: $links, lockVersion: $lockVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the custom field hierarchy items
#
# GET /api/v3/custom_fields/{id}/items
# operationId: get_custom_field_items
export def "custom-fields-items items" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: int # The identifier of the parent hierarchy item (e.g. 1337)
  --depth: int # The level of hierarchy depth (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "depth" $depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/custom_fields/($id)/items" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom field hierarchy item
#
# GET /api/v3/custom_field_items/{id}
# operationId: get_custom_field_item
export def "custom-field-items item" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/custom_field_items/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom field hierarchy item's branch
#
# GET /api/v3/custom_field_items/{id}/branch
# operationId: get_custom_field_item_branch
export def "custom-field-items-branch branch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/custom_field_items/($id)/branch")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Custom Option
#
# GET /api/v3/custom_options/{id}
# operationId: View_Custom_Option
export def "custom-options Option" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/custom_options/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all non working days
#
# GET /api/v3/days/non_working
# operationId: list_non_working_days
export def "days-non-working days" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions.  Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + date: the inclusive date interval to scope days to look up. When   unspecified, default is from the beginning to the end of current year.    Example: `{ "date": { "operator": "<>d", "values": ["2022-05-02","2022-05-26"] } }`   would return days between May 5 and May 26 2022, inclusive. (e.g. [{ "date": { "operator": "<>d", "values": ["2022-05-02","2022-05-26"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/days/non_working" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a non-working day (NOT IMPLEMENTED)
#
# POST /api/v3/days/non_working
# operationId: create_non_working_day
# --_links shape: {self: any}
export def "days-non-working day" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer
  date: string # Date of the non-working day. (format: date)
  name: string # Descriptive name for the non-working day.
  --links: record # shape: {self: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/days/non_working")
  let body = {_type: $type, date: $date, name: $name, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a non-working day
#
# GET /api/v3/days/non_working/{date}
# operationId: view_non_working_day
export def "days-non-working day-by-date" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/days/non_working/($date)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a non-working day attributes (NOT IMPLEMENTED)
#
# PATCH /api/v3/days/non_working/{date}
# operationId: update_non_working_day
# --_links shape: {self: any}
export def "days-non-working day-by-date-1" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer
  --body-date: string # Date of the non-working day. (format: date)
  name: string # Descriptive name for the non-working day.
  --links: record # shape: {self: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/days/non_working/($date)")
  let body = {_type: $type, date: $body_date, name: $name, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a non-working day (NOT IMPLEMENTED)
#
# DELETE /api/v3/days/non_working/{date}
# operationId: delete_non_working_day
export def "days-non-working day-by-date-2" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/days/non_working/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists week days
#
# GET /api/v3/days/week
# operationId: list_week_days
export def "days-week days" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/days/week")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update week days (NOT IMPLEMENTED)
#
# PATCH /api/v3/days/week
# operationId: update_week_days
# --_embedded shape: {elements: list}
export def "days-week days-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1
  embedded: record # shape: {elements: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/days/week")
  let body = {_type: $type, _embedded: $embedded} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a week day
#
# GET /api/v3/days/week/{day}
# operationId: view_week_day
export def "days-week day-by-day" [
  day: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/days/week/($day)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a week day attributes (NOT IMPLEMENTED)
#
# PATCH /api/v3/days/week/{day}
# operationId: update_week_day
export def "days-week day-by-day-1" [
  day: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-2
  --working: oneof<nothing, bool> # `true` for a working day. `false` for a weekend day.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/days/week/($day)")
  let body = {_type: $type, working: $working} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists days
#
# GET /api/v3/days
# operationId: list_days
export def "days days" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions.  Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + date: the inclusive date interval to scope days to look up. When   unspecified, default is from the beginning of current month to the end   of following month.    Example: `{ "date": { "operator": "<>d", "values": ["2022-05-02","2022-05-26"] } }`   would return days between May 5 and May 26 2022, inclusive.  + working: when `true`, returns only the working days. When `false`,   returns only the non-working days (weekend days and non-working days).   When unspecified, returns both working and non-working days.    Example: `{ "working": { "operator": "=", "values": ["t"] } }`   would exclude non-working days from the response. (e.g. [{ "date": { "operator": "<>d", "values": ["2022-05-02","2022-05-26"] } }, { "working": { "operator": "=", "values": ["f"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/days" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View day
#
# GET /api/v3/days/{date}
# operationId: view_day
export def "days day" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/days/($date)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Documents
#
# GET /api/v3/documents
# operationId: List_Documents
export def "documents Documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by primary key  + created_at: Sort by document creation datetime (e.g. [["created_at", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/documents" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View document
#
# GET /api/v3/documents/{id}
# operationId: View_document
export def "documents document-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/documents/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update document
#
# PATCH /api/v3/documents/{id}
# operationId: Update_document
# --description shape: {raw?: string}
export def "documents document-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the document
  --description: record # shape: {raw?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/documents/($id)")
  let body = {title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# show or validate form
#
# POST /api/v3/example/form
# operationId: show_or_validate_form
export def "example-form form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string
  --lockVersion: float
  --subject: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/example/form")
  let body = {_type: $type, lockVersion: $lockVersion, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# view the schema
#
# GET /api/v3/example/schema
# operationId: view_the_schema
export def "example-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/example/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# view aggregated result
#
# GET /api/v3/examples
# operationId: view_aggregated_result
export def "examples result" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupBy: string # The column to group by. Note: Aggregation is as of now only supported by the work package collection. You can pass any column name as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. (e.g. status)
  --showSums: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a file link.
#
# GET /api/v3/file_links/{id}
# operationId: view_file_link
export def "file-links link-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/file_links/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a file link.
#
# DELETE /api/v3/file_links/{id}
# operationId: delete_file_link
export def "file-links link-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/file_links/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an opening uri of the linked file.
#
# GET /api/v3/file_links/{id}/open
# operationId: open_file_link
export def "file-links-open link" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: oneof<nothing, bool> # Boolean flag indicating, if the file should be opened directly or rather the directory location. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/file_links/($id)/open" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a download uri of the linked file.
#
# GET /api/v3/file_links/{id}/download
# operationId: download_file_link
export def "file-links-download link" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/file_links/($id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List grids
#
# GET /api/v3/grids
# operationId: list_grids
export def "grids grids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (default: 30, e.g. 25)
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  - page: Filter grid by work package (e.g. [{ "page": { "operator": "=", "values": ["/my/page"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/grids" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a grid
#
# POST /api/v3/grids
# operationId: create_grid
# --widgets item shape: {_type: "GridWidget", id: int, identifier: string, startRow: int, endRow: int, startColumn: int, endColumn: int, options?: record}
# --_links shape: {scope?: any}
export def "grids grid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rowCount: int # The number of rows the grid has
  --columnCount: int # The number of columns the grid has
  --widgets: list # The set of `GridWidget`s selected for the grid.  # Conditions  - The widgets must not overlap. — item shape: {_type: "GridWidget", id: int, identifier: string, startRow: int, endRow: int, startColumn: int, endColumn: int, options?: record}
  --links: record # shape: {scope?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/grids")
  let body = {rowCount: $rowCount, columnCount: $columnCount, widgets: $widgets, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Grid Create Form
#
# POST /api/v3/grids/form
# operationId: Grid_Create_Form
export def "grids-form Form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/grids/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a grid
#
# GET /api/v3/grids/{id}
# operationId: get_grid
export def "grids grid-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/grids/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a grid
#
# PATCH /api/v3/grids/{id}
# operationId: update_grid
# --widgets item shape: {_type: "GridWidget", id: int, identifier: string, startRow: int, endRow: int, startColumn: int, endColumn: int, options?: record}
# --_links shape: {scope?: any}
export def "grids grid-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rowCount: int # The number of rows the grid has
  --columnCount: int # The number of columns the grid has
  --widgets: list # The set of `GridWidget`s selected for the grid.  # Conditions  - The widgets must not overlap. — item shape: {_type: "GridWidget", id: int, identifier: string, startRow: int, endRow: int, startColumn: int, endColumn: int, options?: record}
  --links: record # shape: {scope?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/grids/($id)")
  let body = {rowCount: $rowCount, columnCount: $columnCount, widgets: $widgets, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Grid Update Form
#
# POST /api/v3/grids/{id}/form
# operationId: Grid_Update_Form
export def "grids-form Form-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/grids/($id)/form")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List groups
#
# GET /api/v3/groups
# operationId: list_groups
export def "groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by primary key  + created_at: Sort by group creation datetime  + updated_at: Sort by the time the group was updated last (default: [["id", "asc"]], e.g. [["id", "asc"]])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/name,elements/self,self)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/groups" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create group
#
# POST /api/v3/groups
# operationId: create_group
# --_links shape: {members?: list}
export def "groups group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new group name.
  --links: record # shape: {members?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/groups")
  let body = {name: $name, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete group
#
# DELETE /api/v3/groups/{id}
# operationId: delete_group
export def "groups group-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group
#
# GET /api/v3/groups/{id}
# operationId: get_group
export def "groups group-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/groups/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group
#
# PATCH /api/v3/groups/{id}
# operationId: update_group
# --_links shape: {members?: list}
export def "groups group-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new group name.
  --links: record # shape: {members?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/groups/($id)")
  let body = {name: $name, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List help texts
#
# GET /api/v3/help_texts
# operationId: list_help_texts
export def "help-texts texts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/help_texts")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get help text
#
# GET /api/v3/help_texts/{id}
# operationId: get_help_text
export def "help-texts text" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/help_texts/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all visible meetings
#
# GET /api/v3/meetings
# operationId: list_meetings
export def "meetings meetings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/meetings")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create meeting
#
# POST /api/v3/meetings
# operationId: create_meeting
# --_links shape: {project?: any}
export def "meetings meeting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The meeting's title
  --location: string # The meeting's location
  --startTime: string # The scheduled meeting start time. (format: date-time)
  --duration: string # The meeting duration as an ISO 8601 duration (e.g. `PT1H` for 1 hour, `PT1H30M` for 1.5 hours).
  --state: string@state-completer # The current state of the meeting. Possible values:  - *open* - *draft* - *in_progress* - *cancelled* - *closed*
  --sharing: string@sharing-completer # How the meeting template is shared. Only applicable for one-time templates.
  --template: oneof<nothing, bool> # Whether this meeting is a template.
  --notify: oneof<nothing, bool> # Whether to send email notifications to participants.
  --lockVersion: int # The version of the item as used for optimistic locking.  Required for PATCH operations to detect concurrent modifications.
  --links: record # shape: {project?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/meetings")
  let body = {title: $title, location: $location, startTime: $startTime, duration: $duration, state: $state, sharing: $sharing, template: $template, notify: $notify, lockVersion: $lockVersion, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a meeting
#
# GET /api/v3/meetings/{id}
# operationId: get_meeting
export def "meetings meeting-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update meeting
#
# PATCH /api/v3/meetings/{id}
# operationId: update_meeting
# --_links shape: {project?: any}
export def "meetings meeting-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The meeting's title
  --location: string # The meeting's location
  --startTime: string # The scheduled meeting start time. (format: date-time)
  --duration: string # The meeting duration as an ISO 8601 duration (e.g. `PT1H` for 1 hour, `PT1H30M` for 1.5 hours).
  --state: string@state-completer # The current state of the meeting. Possible values:  - *open* - *draft* - *in_progress* - *cancelled* - *closed*
  --sharing: string@sharing-completer # How the meeting template is shared. Only applicable for one-time templates.
  --template: oneof<nothing, bool> # Whether this meeting is a template.
  --notify: oneof<nothing, bool> # Whether to send email notifications to participants.
  --lockVersion: int # The version of the item as used for optimistic locking.  Required for PATCH operations to detect concurrent modifications.
  --links: record # shape: {project?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)")
  let body = {title: $title, location: $location, startTime: $startTime, duration: $duration, state: $state, sharing: $sharing, template: $template, notify: $notify, lockVersion: $lockVersion, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete meeting
#
# DELETE /api/v3/meetings/{id}
# operationId: delete_meeting
export def "meetings meeting-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List meeting agenda items
#
# GET /api/v3/meetings/{id}/agenda_items
# operationId: list_meeting_agenda_items
export def "meetings-agenda-items items" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/agenda_items")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create meeting agenda item
#
# POST /api/v3/meetings/{id}/agenda_items
# operationId: create_meeting_agenda_item
# --notes shape: {raw?: string}
# --_links shape: {workPackage?: any, presenter?: any, section?: any}
export def "meetings-agenda-items item-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The agenda item's title.
  --notes: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --durationInMinutes: int # The agenda item's duration in minutes. (nullable)
  --itemType: string@itemType-completer # The type of this agenda item (simple or work_package).
  --lockVersion: int # The version of the item as used for optimistic locking. Required for PATCH operations.
  --links: record # shape: {workPackage?: any, presenter?: any, section?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/agenda_items")
  let body = {title: $title, notes: $notes, durationInMinutes: $durationInMinutes, itemType: $itemType, lockVersion: $lockVersion, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a meeting agenda item
#
# GET /api/v3/meetings/{meeting_id}/agenda_items/{id}
# operationId: get_meeting_agenda_item
export def "meetings-agenda-items item-by-meeting_id-id" [
  meeting_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($meeting_id)/agenda_items/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a meeting agenda item
#
# PATCH /api/v3/meetings/{meeting_id}/agenda_items/{id}
# operationId: update_meeting_agenda_item
# --notes shape: {raw?: string}
# --_links shape: {workPackage?: any, presenter?: any, section?: any}
export def "meetings-agenda-items item-by-meeting_id-id-1" [
  meeting_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The agenda item's title.
  --notes: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --durationInMinutes: int # The agenda item's duration in minutes. (nullable)
  --itemType: string@itemType-completer # The type of this agenda item (simple or work_package).
  --lockVersion: int # The version of the item as used for optimistic locking. Required for PATCH operations.
  --links: record # shape: {workPackage?: any, presenter?: any, section?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($meeting_id)/agenda_items/($id)")
  let body = {title: $title, notes: $notes, durationInMinutes: $durationInMinutes, itemType: $itemType, lockVersion: $lockVersion, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a meeting agenda item
#
# DELETE /api/v3/meetings/{meeting_id}/agenda_items/{id}
# operationId: delete_meeting_agenda_item
export def "meetings-agenda-items item-by-meeting_id-id-2" [
  meeting_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($meeting_id)/agenda_items/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attachments by meeting
#
# GET /api/v3/meetings/{id}/attachments
# operationId: List_attachments_by_meeting
export def "meetings-attachments meeting-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add attachment to meeting
#
# POST /api/v3/meetings/{id}/attachments
# operationId: Add_attachment_to_meeting
export def "meetings-attachments meeting-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Meeting update form
#
# POST /api/v3/meetings/{id}/form
# operationId: meeting_update_form
export def "meetings-form form-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List meeting sections
#
# GET /api/v3/meetings/{id}/sections
# operationId: list_meeting_sections
export def "meetings-sections sections" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/sections")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create meeting section
#
# POST /api/v3/meetings/{id}/sections
# operationId: create_meeting_section
export def "meetings-sections section-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The section's title.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($id)/sections")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a meeting section
#
# GET /api/v3/meetings/{meeting_id}/sections/{id}
# operationId: get_meeting_section
export def "meetings-sections section-by-meeting_id-id" [
  meeting_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($meeting_id)/sections/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a meeting section
#
# PATCH /api/v3/meetings/{meeting_id}/sections/{id}
# operationId: update_meeting_section
export def "meetings-sections section-by-meeting_id-id-1" [
  meeting_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The section's title.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($meeting_id)/sections/($id)")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a meeting section
#
# DELETE /api/v3/meetings/{meeting_id}/sections/{id}
# operationId: delete_meeting_section
export def "meetings-sections section-by-meeting_id-id-2" [
  meeting_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/meetings/($meeting_id)/sections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Meeting create form
#
# POST /api/v3/meetings/form
# operationId: meeting_create_form
export def "meetings-form form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/meetings/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get meeting schema
#
# GET /api/v3/meetings/schema
# operationId: get_meeting_schema
export def "meetings-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/meetings/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List memberships
#
# GET /api/v3/memberships
# operationId: list_memberships
export def "memberships memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + any_name_attribute: filters memberships based on the name of the principal. All possible name variants   (and also email and login) are searched. + blocked: reduces the result set to all memberships that are temporarily blocked or that are not blocked   temporarily. + group: filters memberships based on the name of a group. The group however is not the principal used for   filtering. Rather, the memberships of the group are used as the filter values. + name: filters memberships based on the name of the principal. Note that only the name is used which depends   on a setting in the OpenProject instance. + principal: filters memberships based on the id of the principal. + project: filters memberships based on the id of the project. + role: filters memberships based on the id of any role assigned to the membership. + status: filters memberships based on the status of the principal. + created_at: filters memberships based on the time the membership was created. + updated_at: filters memberships based on the time the membership was updated last.
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by primary key + name: Sort by the name of the principal. Note that this depends on the setting for how the name is to be   displayed at least for users. + email: Sort by the email address of the principal. Groups and principal users, which do not have an email,   are sorted last. + status: Sort by the status of the principal. Groups and principal users, which do not have a status, are   sorted together with the active users. + created_at: Sort by membership creation datetime + updated_at: Sort by the time the membership was updated last (default: [["id", "asc"]], e.g. [["id", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/memberships" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a membership
#
# POST /api/v3/memberships
# operationId: create_membership
# --_links shape: {principal?: any, roles?: list, project?: any}
# --_meta shape: {notificationMessage?: any, sendNotification?: bool}
export def "memberships membership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  links: record # shape: {principal?: any, roles?: list, project?: any}
  --meta: record # shape: {notificationMessage?: any, sendNotification?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/memberships")
  let body = {_links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Available projects for memberships
#
# GET /api/v3/memberships/available_projects
# operationId: get_memberships_available_projects
export def "memberships-available-projects projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/memberships/available_projects")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Form create membership
#
# POST /api/v3/memberships/form
# operationId: form_create_membership
# --_links shape: {principal?: any, roles?: list, project?: any}
# --_meta shape: {notificationMessage?: any, sendNotification?: bool}
export def "memberships-form membership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  links: record # shape: {principal?: any, roles?: list, project?: any}
  --meta: record # shape: {notificationMessage?: any, sendNotification?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/memberships/form")
  let body = {_links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Schema membership
#
# GET /api/v3/memberships/schema
# operationId: get_membership_schema
export def "memberships-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/memberships/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete membership
#
# DELETE /api/v3/memberships/{id}
# operationId: delete_membership
export def "memberships membership-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/memberships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a membership
#
# GET /api/v3/memberships/{id}
# operationId: get_membership
export def "memberships membership-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/memberships/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update membership
#
# PATCH /api/v3/memberships/{id}
# operationId: update_membership
# --_links shape: {principal?: any, roles?: list, project?: any}
# --_meta shape: {notificationMessage?: any, sendNotification?: bool}
export def "memberships membership-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  links: record # shape: {principal?: any, roles?: list, project?: any}
  --meta: record # shape: {notificationMessage?: any, sendNotification?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/memberships/($id)")
  let body = {_links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Form update membership
#
# POST /api/v3/memberships/{id}/form
# operationId: form_update_membership
# --_links shape: {principal?: any, roles?: list, project?: any}
# --_meta shape: {notificationMessage?: any, sendNotification?: bool}
export def "memberships-form membership-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  links: record # shape: {principal?: any, roles?: list, project?: any}
  --meta: record # shape: {notificationMessage?: any, sendNotification?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/memberships/($id)/form")
  let body = {_links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show my preferences
#
# GET /api/v3/my_preferences
# operationId: Show_my_preferences
export def "my-preferences preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/my_preferences")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update my preferences
#
# PATCH /api/v3/my_preferences
# operationId: Update_UserPreferences
export def "my-preferences UserPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoHidePopups: oneof<nothing, bool>
  --timeZone: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/my_preferences")
  let body = {autoHidePopups: $autoHidePopups, timeZone: $timeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List News
#
# GET /api/v3/news
# operationId: List_News
export def "news News" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by primary key  + created_at: Sort by news creation datetime (e.g. [["created_at", "asc"]])
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + project_id: Filter news by project (e.g. [{ "project_id": { "operator": "=", "values": ["1", "2"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/news" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create News
#
# POST /api/v3/news
# operationId: create_news
# --_links shape: {project: any}
export def "news news" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
  --links: record # shape: {project: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/news")
  let body = {description: $description, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View news
#
# GET /api/v3/news/{id}
# operationId: View_news
export def "news news-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/news/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update news
#
# PATCH /api/v3/news/{id}
# operationId: update_news
# --_links shape: {project: any}
export def "news news-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any
  --links: record # shape: {project: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/news/($id)")
  let body = {description: $description, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete news
#
# DELETE /api/v3/news/{id}
# operationId: delete_news
export def "news news-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/news/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification collection
#
# GET /api/v3/notifications
# operationId: list_notifications
export def "notifications notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (default: 20, e.g. 25)
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by primary key  + reason: Sort by notification reason  + readIAN: Sort by read status (e.g. [["reason", "asc"]])
  --groupBy: string # string specifying group_by criteria.  + reason: Group by notification reason  + project: Sort by associated project (e.g. reason)
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + id: Filter by primary key  + project: Filter by the project the notification was created in  + readIAN: Filter by read status  + reason: Filter by the reason, e.g. 'mentioned' or 'assigned' the notification was created because of  + resourceId: Filter by the id of the resource the notification was created for. Ideally used together with the `resourceType` filter.  + resourceType: Filter by the type of the resource the notification was created for. Ideally used together with the `resourceId` filter. (e.g. [{ "readIAN": { "operator": "=", "values": ["t"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/notifications" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read all notifications
#
# POST /api/v3/notifications/read_ian
# operationId: read_notifications
export def "notifications-read-ian notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + id: Filter by primary key  + project: Filter by the project the notification was created in  + reason: Filter by the reason, e.g. 'mentioned' or 'assigned' the notification was created because of  + resourceId: Filter by the id of the resource the notification was created for. Ideally used together with the   `resourceType` filter.  + resourceType: Filter by the type of the resource the notification was created for. Ideally used together with   the `resourceId` filter. (e.g. [{ "reason": { "operator": "=", "values": ["mentioned"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/notifications/read_ian" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unread all notifications
#
# POST /api/v3/notifications/unread_ian
# operationId: unread_notifications
export def "notifications-unread-ian notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + id: Filter by primary key  + project: Filter by the project the notification was created in  + reason: Filter by the reason, e.g. 'mentioned' or 'assigned' the notification was created because of  + resourceId: Filter by the id of the resource the notification was created for. Ideally used together with the   `resourceType` filter.  + resourceType: Filter by the type of the resource the notification was created for. Ideally used together with   the `resourceId` filter. (e.g. [{ "reason": { "operator": "=", "values": ["mentioned"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/notifications/unread_ian" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the notification
#
# GET /api/v3/notifications/{id}
# operationId: view_notification
export def "notifications notification" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/notifications/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a notification detail
#
# GET /api/v3/notifications/{notification_id}/details/{id}
# operationId: view_notification_detail
export def "notifications-details detail" [
  notification_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/notifications/($notification_id)/details/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read notification
#
# POST /api/v3/notifications/{id}/read_ian
# operationId: read_notification
export def "notifications-read-ian notification" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/notifications/($id)/read_ian")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unread notification
#
# POST /api/v3/notifications/{id}/unread_ian
# operationId: unread_notification
export def "notifications-unread-ian notification" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/notifications/($id)/unread_ian")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the oauth application.
#
# GET /api/v3/oauth_applications/{id}
# operationId: get_oauth_application
export def "oauth-applications application" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/oauth_applications/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the oauth client credentials object.
#
# GET /api/v3/oauth_client_credentials/{id}
# operationId: get_oauth_client_credentials
export def "oauth-client-credentials credentials" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/oauth_client_credentials/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List placehoder users
#
# GET /api/v3/placeholder_users
# operationId: list_placeholder_users
export def "placeholder-users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  - name: filters placeholder users by the name. - group: filters placeholder by the group it is contained in. - status: filters placeholder by the status it has. (e.g. [{ "name": { "operator": "~", "values": ["Darth"] } }])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/name,elements/self,self)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/placeholder_users" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create placeholder user
#
# POST /api/v3/placeholder_users
# operationId: create_placeholder_user
export def "placeholder-users user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the placeholder user to be created.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/placeholder_users")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete placeholder user
#
# DELETE /api/v3/placeholder_users/{id}
# operationId: delete_placeholder_user
export def "placeholder-users user-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/placeholder_users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View placeholder user
#
# GET /api/v3/placeholder_users/{id}
# operationId: view_placeholder_user
export def "placeholder-users user-by-id-1" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/placeholder_users/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update placeholder user
#
# PATCH /api/v3/placeholder_users/{id}
# operationId: update_placeholder_user
export def "placeholder-users user-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the placeholder user to be created.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/placeholder_users/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List portfolios
#
# GET /api/v3/portfolios
# operationId: list_portfolios
export def "portfolios portfolios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openportfolio.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + active: based on the active property of the portfolio + ancestor: filters portfolios by their ancestor. A portfolio is not considered to be its own ancestor. + available_project_attributes: filters portfolios based on the activated project attributes. + created_at: based on the time the portfolio was created + favorited: based on the favorited property of the portfolio + id: based on portfolios' id. + latest_activity_at: based on the time the last activity was registered on a portfolio. + name_and_identifier: based on both the name and the identifier. + parent_id: filters portfolios by their parent. + principal: based on members of the portfolio. + project_phase_any: based on the project phases active in a portfolio. + project_status_code: based on status code of the portfolio + storage_id: filters portfolios by linked storages + storage_url: filters portfolios by linked storages identified by the host url + type_id: based on the types active in a portfolio. + user_action: based on the actions the current user has in the portfolio. + visible: based on the visibility for the user (id) provided as the filter value. This filter is useful for admins to identify the portfolios visible to a user.  There might also be additional filters based on the custom fields that have been configured.  Each defined lifecycle step will also define a filter in this list endpoint. Given that the elements are not static but rather dynamically created on each OpenProject instance, a list cannot be provided. Those filters follow the schema: + project_start_gate_[id]: a filter on a project phase's start gate active in a portfolio. The id is the id of the phase the gate belongs to. + project_finish_gate_[id]: a filter on a project phase's finish gate active in a portfolio. The id is the id of the phase the gate belongs to. + project_phase_[id]: a filter on a project phase active in a portfolio. The id is the id of the phase queried for. (e.g. [{ "ancestor": { "operator": "=", "values": ["1"] }" }])
  --sortBy: string # JSON specifying sort criteria. Currently supported orders are:  + id + name + typeahead (sorting by hierarchy and name) + created_at + public + latest_activity_at + required_disk_space  There might also be additional orders based on the custom fields that have been configured. (e.g. [["id", "asc"]])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/identifier,elements/name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/portfolios" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View portfolio
#
# GET /api/v3/portfolios/{id}
# operationId: View_portfolio
export def "portfolios portfolio" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/portfolios/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Portfolio
#
# PATCH /api/v3/portfolios/{id}
# operationId: Update_Portfolio
# --description shape: {raw?: string}
# --_links shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
export def "portfolios Portfolio-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3
  --body-id: int # Portfolios' id
  --identifier: string
  --name: string
  --active: oneof<nothing, bool> # Indicates whether the portfolio is currently active or already archived
  --favorited: oneof<nothing, bool> # Indicates whether the portfolio is favorited by the current user
  --statusExplanation: any
  --public: oneof<nothing, bool> # Indicates whether the portfolio is accessible for everybody
  --description: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --createdAt: string # Time of creation. Can be writable by admins with the `apiv3_write_readonly_attributes` setting enabled. (format: date-time)
  --updatedAt: string # Time of the most recent change to the portfolio (format: date-time)
  --links: record # shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/portfolios/($id)")
  let body = {_type: $type, id: $body_id, identifier: $identifier, name: $name, active: $active, favorited: $favorited, statusExplanation: $statusExplanation, public: $public, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Portfolio
#
# DELETE /api/v3/portfolios/{id}
# operationId: Delete_Portfolio
export def "portfolios Portfolio-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/portfolios/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Portfolio update form
#
# POST /api/v3/portfolios/{id}/form
# operationId: Portfolio_update_form
export def "portfolios-form form" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/portfolios/($id)/form")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View Post
#
# GET /api/v3/posts/{id}
# operationId: View_Post
export def "posts Post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/posts/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attachments by post
#
# GET /api/v3/posts/{id}/attachments
# operationId: List_attachments_by_post
export def "posts-attachments post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/posts/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add attachment to post
#
# POST /api/v3/posts/{id}/attachments
# operationId: Add_attachment_to_post
export def "posts-attachments post-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/posts/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List principals
#
# GET /api/v3/principals
# operationId: list_principals
export def "principals principals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  - type: filters principals by their type (*User*, *Group*, *PlaceholderUser*). - member: filters principals by the projects they are members in. - name: filters principals by the user or group name. - any_name_attribute: filters principals by the user or group first- and last name, email or login. - status: filters principals by their status number (active = *1*, registered = *2*, locked = *3*, invited = *4*) (e.g. [{ "type": { "operator": "=", "values": ["User"] } }])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/name,elements/self,self)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/principals" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Priorities
#
# GET /api/v3/priorities
# operationId: List_all_Priorities
export def "priorities Priorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/priorities")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Priority
#
# GET /api/v3/priorities/{id}
# operationId: View_Priority
export def "priorities Priority" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/priorities/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List programs
#
# GET /api/v3/programs
# operationId: list_programs
export def "programs programs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + active: based on the active property of the program + ancestor: filters programs by their ancestor. A program is not considered to be its own ancestor. + available_project_attributes: filters programs based on the activated project attributes. + created_at: based on the time the program was created + favorited: based on the favorited property of the program + id: based on programs' id. + latest_activity_at: based on the time the last activity was registered on a program. + name_and_identifier: based on both the name and the identifier. + parent_id: filters programs by their parent. + principal: based on members of the program. + project_phase_any: based on the project phases active in a program. + project_status_code: based on status code of the program + storage_id: filters programs by linked storages + storage_url: filters programs by linked storages identified by the host url + type_id: based on the types active in a program. + user_action: based on the actions the current user has in the program. + visible: based on the visibility for the user (id) provided as the filter value. This filter is useful for admins to identify the programs visible to a user.  There might also be additional filters based on the custom fields that have been configured.  Each defined lifecycle step will also define a filter in this list endpoint. Given that the elements are not static but rather dynamically created on each OpenProject instance, a list cannot be provided. Those filters follow the schema: + project_start_gate_[id]: a filter on a project phase's start gate active in a program. The id is the id of the phase the gate belongs to. + project_finish_gate_[id]: a filter on a project phase's finish gate active in a program. The id is the id of the phase the gate belongs to. + project_phase_[id]: a filter on a project phase active in a program. The id is the id of the phase queried for. (e.g. [{ "ancestor": { "operator": "=", "values": ["1"] }" }])
  --sortBy: string # JSON specifying sort criteria. Currently supported orders are:  + id + name + typeahead (sorting by hierarchy and name) + created_at + public + latest_activity_at + required_disk_space  There might also be additional orders based on the custom fields that have been configured. (e.g. [["id", "asc"]])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/identifier,elements/name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/programs" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View program
#
# GET /api/v3/programs/{id}
# operationId: View_program
export def "programs program" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/programs/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Program
#
# PATCH /api/v3/programs/{id}
# operationId: Update_Program
# --description shape: {raw?: string}
# --_links shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
export def "programs Program-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-4
  --body-id: int # Programs' id
  --identifier: string
  --name: string
  --active: oneof<nothing, bool> # Indicates whether the program is currently active or already archived
  --favorited: oneof<nothing, bool> # Indicates whether the program is favorited by the current user
  --statusExplanation: any
  --public: oneof<nothing, bool> # Indicates whether the program is accessible for everybody
  --description: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --createdAt: string # Time of creation. Can be writable by admins with the `apiv3_write_readonly_attributes` setting enabled. (format: date-time)
  --updatedAt: string # Time of the most recent change to the program (format: date-time)
  --links: record # shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/programs/($id)")
  let body = {_type: $type, id: $body_id, identifier: $identifier, name: $name, active: $active, favorited: $favorited, statusExplanation: $statusExplanation, public: $public, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Program
#
# DELETE /api/v3/programs/{id}
# operationId: Delete_Program
export def "programs Program-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/programs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Program update form
#
# POST /api/v3/programs/{id}/form
# operationId: Program_update_form
export def "programs-form form" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/programs/($id)/form")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a project phase
#
# GET /api/v3/project_phases/{id}
# operationId: get_project_phase
export def "project-phases phase" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/project_phases/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project phase definitions
#
# GET /api/v3/project_phase_definitions
# operationId: list_project_phase_definitions
export def "project-phase-definitions definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/project_phase_definitions")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project phase definition
#
# GET /api/v3/project_phase_definitions/{id}
# operationId: get_project_phase_definition
export def "project-phase-definitions definition" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/project_phase_definitions/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of project storages
#
# GET /api/v3/project_storages
# operationId: list_project_storages
export def "project-storages storages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  - project_id - storage_id - storage_url (default: [], e.g. [{ "project_id": { "operator": "=", "values": ["42"] }}, { "storage_id": { "operator": "=", "values": ["1337"] }}])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/project_storages" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a project storage
#
# GET /api/v3/project_storages/{id}
# operationId: get_project_storage
export def "project-storages storage" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/project_storages/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open the project storage
#
# GET /api/v3/project_storages/{id}/open
# operationId: open_project_storage
export def "project-storages-open storage" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/project_storages/($id)/open")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projects
#
# GET /api/v3/projects
# operationId: list_projects
export def "projects projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + active: based on the active property of the project + ancestor: filters projects by their ancestor. A project is not considered to be its own ancestor. + available_project_attributes: filters projects based on the activated project project attributes. + created_at: based on the time the project was created + favorited: based on the favorited property of the project + id: based on projects' id. + latest_activity_at: based on the time the last activity was registered on a project. + name_and_identifier: based on both the name and the identifier. + parent_id: filters projects by their parent. + principal: based on members of the project. + project_phase_any: based on the project phases active in a project. + project_status_code: based on status code of the project + storage_id: filters projects by linked storages + storage_url: filters projects by linked storages identified by the host url + type_id: based on the types active in a project. + user_action: based on the actions the current user has in the project. + visible: based on the visibility for the user (id) provided as the filter value. This filter is useful for admins to identify the projects visible to a user.  There might also be additional filters based on the custom fields that have been configured.  Each defined lifecycle step will also define a filter in this list endpoint. Given that the elements are not static but rather dynamically created on each OpenProject instance, a list cannot be provided. Those filters follow the schema: + project_start_gate_[id]: a filter on a project phase's start gate active in a project. The id is the id of the phase the gate belongs to. + project_finish_gate_[id]: a filter on a project phase's finish gate active in a project. The id is the id of the phase the gate belongs to. + project_phase_[id]: a filter on a project phase active in a project. The id is the id of the phase queried for. (e.g. [{ "ancestor": { "operator": "=", "values": ["1"] }" }])
  --sortBy: string # JSON specifying sort criteria. Currently supported orders are:  + id + name + typeahead (sorting by hierarchy and name) + created_at + public + latest_activity_at + required_disk_space  There might also be additional orders based on the custom fields that have been configured. (e.g. [["id", "asc"]])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/identifier,elements/name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/projects" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project
#
# POST /api/v3/projects
# operationId: create_project
# --description shape: {raw?: string}
# --_links shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
export def "projects project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-5
  --id: int # Projects' id
  --identifier: string
  --name: string
  --active: oneof<nothing, bool> # Indicates whether the project is currently active or already archived
  --favorited: oneof<nothing, bool> # Indicates whether the project is favorited by the current user
  --statusExplanation: any
  --public: oneof<nothing, bool> # Indicates whether the project is accessible for everybody
  --description: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --createdAt: string # Time of creation. Can be writable by admins with the `apiv3_write_readonly_attributes` setting enabled. (format: date-time)
  --updatedAt: string # Time of the most recent change to the project (format: date-time)
  --links: record # shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/projects")
  let body = {_type: $type, id: $id, identifier: $identifier, name: $name, active: $active, favorited: $favorited, statusExplanation: $statusExplanation, public: $public, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Project create form
#
# POST /api/v3/projects/form
# operationId: Project_create_form
export def "projects-form form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/projects/form")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View project schema
#
# GET /api/v3/projects/schema
# operationId: View_project_schema
export def "projects-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/projects/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Project
#
# DELETE /api/v3/projects/{id}
# operationId: Delete_Project
export def "projects Project-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project
#
# GET /api/v3/projects/{id}
# operationId: View_project
export def "projects project-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Project
#
# PATCH /api/v3/projects/{id}
# operationId: Update_Project
# --description shape: {raw?: string}
# --_links shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
export def "projects Project-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-5
  --body-id: int # Projects' id
  --identifier: string
  --name: string
  --active: oneof<nothing, bool> # Indicates whether the project is currently active or already archived
  --favorited: oneof<nothing, bool> # Indicates whether the project is favorited by the current user
  --statusExplanation: any
  --public: oneof<nothing, bool> # Indicates whether the project is accessible for everybody
  --description: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --createdAt: string # Time of creation. Can be writable by admins with the `apiv3_write_readonly_attributes` setting enabled. (format: date-time)
  --updatedAt: string # Time of the most recent change to the project (format: date-time)
  --links: record # shape: {update?: any, updateImmediately?: any, delete?: any, favor?: any, disfavor?: any, createWorkPackage?: any, createWorkPackageImmediately?: any, self: any, categories: any, types?: any, versions?: any, memberships?: any, workPackages?: any, parent?: any, status?: any, storages?: list, projectStorages?: any, ancestors?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)")
  let body = {_type: $type, id: $body_id, identifier: $identifier, name: $name, active: $active, favorited: $favorited, statusExplanation: $statusExplanation, public: $public, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Project update form
#
# POST /api/v3/projects/{id}/form
# operationId: Project_update_form
export def "projects-form form-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/form")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create project copy
#
# POST /api/v3/projects/{id}/copy
# operationId: Create_project_copy
export def "projects-copy copy" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/copy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project copy form
#
# POST /api/v3/projects/{id}/copy/form
# operationId: Project_copy_form
export def "projects-copy-form form" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/copy/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project status
#
# GET /api/v3/project_statuses/{id}
# operationId: View_project_status
export def "project-statuses status" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/project_statuses/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available parent project candidates
#
# GET /api/v3/projects/available_parent_projects
# operationId: List_available_parent_project_candidates
export def "projects-available-parent-projects candidates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. (e.g. [{ "ancestor": { "operator": "=", "values": ['1'] }" }])
  --of: string # The id or identifier of the project the parent candidate is determined for (e.g. 123)
  --workspace-type: string@workspace-type-completer # The workspace type of the new project the parent candidate is determined for. Ignored when `of` parameter is provided. Note that while 'portfolio' is supported as a type (since it is a type of Workspace), the endpoint will currently always return an empty resultset as portfolios cannot have parents. (e.g. program)
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint and allows all the filters and sortBy supported by the project list endpoint. (e.g. [["id", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "of" $of "scalar") (serialize-qp "workspace_type" $workspace_type "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/projects/available_parent_projects" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# view Budgets of a Project
#
# GET /api/v3/projects/{id}/budgets
# operationId: view_Budgets_of_a_Project
export def "projects-budgets Project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/budgets")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View default query for project
#
# GET /api/v3/projects/{id}/queries/default
# operationId: View_default_query_for_project
export def "projects-queries-default project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. The filters provided as parameters are not applied to the query but are instead used to override the query's persisted filters. All filters also accepted by the work packages endpoint are accepted. If no filter is to be applied, the client should send an empty array (`[]`). (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "assignee": { "operator": "=", "values": ["1", "5"] }" }])
  --offset: int # Page number inside the queries' result collection of work packages. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page for the queries' result collection of work packages. (e.g. 25)
  --sortBy: string # JSON specifying sort criteria. The sort criteria is applied to the query's result collection of work packages overriding the query's persisted sort criteria. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. The grouping criteria is applied to the to the query's result collection of work packages overriding the query's persisted group criteria. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. The showSums parameter is applied to the to the query's result collection of work packages overriding the query's persisted sums property. (default: false, e.g. true)
  --timestamps: string # Indicates the timestamps to filter by when showing changed attributes on work packages. Values can be either ISO8601 dates, ISO8601 durations and the following relative date keywords: "oneDayAgo@HH:MM+HH:MM", "lastWorkingDay@HH:MM+HH:MM", "oneWeekAgo@HH:MM+HH:MM", "oneMonthAgo@HH:MM+HH:MM". The first "HH:MM" part represents the zero paded hours and minutes. The last "+HH:MM" part represents the timezone offset from UTC associated with the time. Values older than 1 day are accepted only with valid Enterprise Token available.  (default: PT0S, e.g. 2023-01-01,P-1Y,PT0S,lastWorkingDay@12:00)
  --timelineVisible: oneof<nothing, bool> # Indicates whether the timeline should be shown. (default: false, e.g. true)
  --showHierarchies: oneof<nothing, bool> # Indicates whether the hierarchy mode should be enabled. (default: true, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "timelineVisible" $timelineVisible "scalar") (serialize-qp "showHierarchies" $showHierarchies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/projects/($id)/queries/default" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Query Filter Instance Schemas for Project
#
# GET /api/v3/projects/{id}/queries/filter_instance_schemas
# operationId: List_Query_Filter_Instance_Schemas_for_Project
export def "projects-queries-filter-instance-schemas Project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/queries/filter_instance_schemas")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View schema for project queries
#
# GET /api/v3/projects/{id}/queries/schema
# operationId: View_schema_for_project_queries
export def "projects-queries-schema queries" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/queries/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get work packages of project
#
# GET /api/v3/projects/{id}/work_packages
# operationId: Get_Project_Work_Package_Collection
export def "projects-work-packages Collection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. If no filter is to be applied, the client should send an empty array (`[]`). (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "type_id": { "operator": "=", "values": ['1', '2'] }}])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. (default: false, e.g. true)
  --select: string # Comma separated list of properties to include. (e.g. total,elements/subject,elements/id,self)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/projects/($id)/work_packages" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create work package in project
#
# POST /api/v3/projects/{id}/work_packages
# operationId: Create_Project_Work_Package
# --_links shape: {addComment?: any, addRelation?: any, addWatcher?: any, previewMarkup?: any, removeWatcher?: any, delete?: any, logTime?: any, move?: any, copy?: any, unwatch?: any, update?: any, updateImmediately?: any, watch?: any, self: any, schema: any, attachments?: any, addAttachment?: any, prepareAttachment?: any, author: any, assignee?: any, availableWatchers?: any, budget?: any, category?: any, addFileLink?: any, fileLinks?: any, parent?: any, priority: any, project: any, projectPhase?: any, projectPhaseDefinition?: any, responsible?: any, relations?: any, revisions?: any, status: any, sprint?: any, timeEntries?: any, type: any, version?: any, watchers?: any}
export def "projects-work-packages Package" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Indicates whether change notifications (e.g. via E-Mail) should be sent. Note that this controls notifications for all users interested in changes to the work package (e.g. watchers, author and assignee), not just the current user. (default: true, e.g. false)
  subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --readonly: oneof<nothing, bool> # If true, the work package is in a readonly status so with the exception of the status, no other property can be altered.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --date: string # Date on which a milestone is achieved (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --storyPoints: int # The estimation in story points on how long this work package will take to complete  # Conditions  **Permission** Backlogs needs to be enabled in the work package's project and the work package's type is configured to be a backlog type. (nullable)
  --percentageDone: int # Amount of total completion for a work package (nullable)
  links: record # shape: {addComment?: any, addRelation?: any, addWatcher?: any, previewMarkup?: any, removeWatcher?: any, delete?: any, logTime?: any, move?: any, copy?: any, unwatch?: any, update?: any, updateImmediately?: any, watch?: any, self: any, schema: any, attachments?: any, addAttachment?: any, prepareAttachment?: any, author: any, assignee?: any, availableWatchers?: any, budget?: any, category?: any, addFileLink?: any, fileLinks?: any, parent?: any, priority: any, project: any, projectPhase?: any, projectPhaseDefinition?: any, responsible?: any, relations?: any, revisions?: any, status: any, sprint?: any, timeEntries?: any, type: any, version?: any, watchers?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/projects/($id)/work_packages" $qp)
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, readonly: $readonly, startDate: $startDate, dueDate: $dueDate, date: $date, estimatedTime: $estimatedTime, storyPoints: $storyPoints, percentageDone: $percentageDone, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Form for creating Work Packages in a Project
#
# POST /api/v3/projects/{id}/work_packages/form
# operationId: form_create_work_package_in_project
# --_links shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
# --_meta shape: {validateCustomFields?: bool}
export def "projects-work-packages-form project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --duration: string # The amount of time in hours the work package needs to be completed. This value must be bigger or equal to `P1D`, and any the value will get floored to the nearest day.  The duration has no effect, unless either a start date or a due date is set.  Not available for milestone type of work packages. (nullable, format: duration)
  --ignoreNonWorkingDays: oneof<nothing, bool> # When scheduling, whether or not to ignore the non working days being defined. A work package with the flag set to true will be allowed to be scheduled to a non working day.
  --links: record # shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
  --meta: record # Meta information for the work package request — shape: {validateCustomFields?: bool}
]: any -> record<_type: string, _embedded: record<payload: record<subject: string, description: record, scheduleManually: bool, startDate: string, dueDate: string, estimatedTime: string, duration: string, ignoreNonWorkingDays: bool, _links: record, _meta: record>, schema: record<_type: string, _dependencies: list, _attributeGroups: list, lockVersion: record, id: record, subject: record, description: record, duration: record, scheduleManually: record, ignoreNonWorkingDays: record, startDate: record, dueDate: record, derivedStartDate: record, derivedDueDate: record, estimatedTime: record, derivedEstimatedTime: record, remainingTime: record, derivedRemainingTime: record, percentageDone: record, derivedPercentageDone: record, readonly: record, createdAt: record, updatedAt: record, author: record, position: record, project: record, projectPhase: record, projectPhaseDefinition: record, parent: record, sprint: record, storyPoints: record, assignee: record, responsible: record, type: record, status: record, category: record, version: record, priority: record, _links: record>, validationErrors: record>, _links: record<self: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, validate: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, previewMarkup: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, customFields: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, configureForm: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/work_packages/form")
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, startDate: $startDate, dueDate: $dueDate, estimatedTime: $estimatedTime, duration: $duration, ignoreNonWorkingDays: $ignoreNonWorkingDays, _links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Project Available assignees
#
# GET /api/v3/projects/{id}/available_assignees
# operationId: Project_Available_assignees
export def "projects-available-assignees assignees" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/available_assignees")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List categories of a project
#
# GET /api/v3/projects/{id}/categories
# operationId: List_categories_of_a_project
export def "projects-categories project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/categories")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sprints in project
#
# GET /api/v3/projects/{id}/sprints
# operationId: List_sprints_in_project
export def "projects-sprints project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions.  Accepts the same format and filters as returned by the [sprints](https://www.openproject.org/docs/api/endpoints/sprints/) endpoint. (e.g. [{ "definingWorkspace": { "operator": "=", "values": ["1"] }" }])
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/projects/($id)/sprints" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List types available in a project
#
# GET /api/v3/projects/{id}/types
# operationId: List_types_available_in_a_project
export def "projects-types project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/types")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List versions available in a project
#
# GET /api/v3/projects/{id}/versions
# operationId: List_versions_available_in_a_project
export def "projects-versions project" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/versions")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unfavorite Project
#
# DELETE /api/v3/projects/{id}/favorite
# operationId: Unfavorite_Project
export def "projects-favorite Project-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/favorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Favorite Project
#
# POST /api/v3/projects/{id}/favorite
# operationId: Favorite_Project
export def "projects-favorite Project-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/favorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project configuration
#
# GET /api/v3/projects/{id}/configuration
# operationId: View_project_configuration
export def "projects-configuration configuration" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/projects/($id)/configuration")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List queries
#
# GET /api/v3/queries
# operationId: List_queries
export def "queries queries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Currently supported filters are:  + project: filters queries by the project they are assigned to. If the project filter is passed with the `!*` (not any) operator, global queries are returned.  + id: filters queries based on their id  + updated_at: filters queries based on the last time they where updated (e.g. [{ "project_id": { "operator": "!*", "values": null }" }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/queries" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create query
#
# POST /api/v3/queries
# operationId: Create_query
export def "queries query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Query name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queries")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Available projects for query
#
# GET /api/v3/queries/available_projects
# operationId: Available_projects_for_query
export def "queries-available-projects query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queries/available_projects")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Query Column
#
# GET /api/v3/queries/columns/{id}
# operationId: View_Query_Column
export def "queries-columns Column" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/columns/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View default query
#
# GET /api/v3/queries/default
# operationId: View_default_query
export def "queries-default query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. The filters provided as parameters are not applied to the query but are instead used to override the query's persisted filters. All filters also accepted by the work packages endpoint are accepted. If no filter is to be applied, the client should send an empty array (`[]`). (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "assignee": { "operator": "=", "values": ["1", "5"] }" }])
  --offset: int # Page number inside the queries' result collection of work packages. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page for the queries' result collection of work packages. (e.g. 25)
  --sortBy: string # JSON specifying sort criteria. The sort criteria is applied to the query's result collection of work packages overriding the query's persisted sort criteria. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. The grouping criteria is applied to the to the query's result collection of work packages overriding the query's persisted group criteria. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. The showSums parameter is applied to the to the query's result collection of work packages overriding the query's persisted sums property. (default: false, e.g. true)
  --timestamps: string # Indicates the timestamps to filter by when showing changed attributes on work packages. Values can be either ISO8601 dates, ISO8601 durations and the following relative date keywords: "oneDayAgo@HH:MM+HH:MM", "lastWorkingDay@HH:MM+HH:MM", "oneWeekAgo@HH:MM+HH:MM", "oneMonthAgo@HH:MM+HH:MM". The first "HH:MM" part represents the zero paded hours and minutes. The last "+HH:MM" part represents the timezone offset from UTC associated with the time, the offset can be positive or negative e.g."oneDayAgo@01:00+01:00", "oneDayAgo@01:00-01:00". Values older than 1 day are accepted only with valid Enterprise Token available.  (default: PT0S, e.g. 2023-01-01,P-1Y,PT0S,lastWorkingDay@12:00)
  --timelineVisible: oneof<nothing, bool> # Indicates whether the timeline should be shown. (default: false, e.g. true)
  --timelineZoomLevel: string # Indicates in what zoom level the timeline should be shown. Valid values are  `days`, `weeks`, `months`, `quarters`, and `years`. (default: days, e.g. days)
  --showHierarchies: oneof<nothing, bool> # Indicates whether the hierarchy mode should be enabled. (default: true, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "timelineVisible" $timelineVisible "scalar") (serialize-qp "timelineZoomLevel" $timelineZoomLevel "scalar") (serialize-qp "showHierarchies" $showHierarchies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/queries/default" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Query Filter Instance Schemas
#
# GET /api/v3/queries/filter_instance_schemas
# operationId: List_Query_Filter_Instance_Schemas
export def "queries-filter-instance-schemas Schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queries/filter_instance_schemas")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Query Filter Instance Schema
#
# GET /api/v3/queries/filter_instance_schemas/{id}
# operationId: View_Query_Filter_Instance_Schema
export def "queries-filter-instance-schemas Schema" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/filter_instance_schemas/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Query Filter
#
# GET /api/v3/queries/filters/{id}
# operationId: View_Query_Filter
export def "queries-filters Filter" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/filters/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query Create Form
#
# POST /api/v3/queries/form
# operationId: Query_Create_Form
export def "queries-form Form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Query name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queries/form")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View Query Operator
#
# GET /api/v3/queries/operators/{id}
# operationId: View_Query_Operator
export def "queries-operators Operator" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/operators/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View schema for global queries
#
# GET /api/v3/queries/schema
# operationId: View_schema_for_global_queries
export def "queries-schema queries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queries/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Query Sort By
#
# GET /api/v3/queries/sort_bys/{id}
# operationId: View_Query_Sort_By
export def "queries-sort-bys By" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/sort_bys/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete query
#
# DELETE /api/v3/queries/{id}
# operationId: Delete_query
export def "queries query-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View query
#
# GET /api/v3/queries/{id}
# operationId: View_query
export def "queries query-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. The filters provided as parameters are not applied to the query but are instead used to override the query's persisted filters. All filters also accepted by the work packages endpoint are accepted. If no filter is to be applied, the client should send an empty array (`[]`). (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "assignee": { "operator": "=", "values": ["1", "5"] }" }])
  --offset: int # Page number inside the queries' result collection of work packages. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page for the queries' result collection of work packages. (e.g. 25)
  --columns: string # Selected columns for the table view. (default: ['type', 'priority'], e.g. [])
  --sortBy: string # JSON specifying sort criteria. The sort criteria is applied to the query's result collection of work packages overriding the query's persisted sort criteria. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. The grouping criteria is applied to the to the query's result collection of work packages overriding the query's persisted group criteria. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. The showSums parameter is applied to the to the query's result collection of work packages overriding the query's persisted sums property. (default: false, e.g. true)
  --timestamps: string # Indicates the timestamps to filter by when showing changed attributes on work packages. Values can be either ISO8601 dates, ISO8601 durations and the following relative date keywords: "oneDayAgo@HH:MM+HH:MM", "lastWorkingDay@HH:MM+HH:MM", "oneWeekAgo@HH:MM+HH:MM", "oneMonthAgo@HH:MM+HH:MM". The first "HH:MM" part represents the zero paded hours and minutes. The last "+HH:MM" part represents the timezone offset from UTC associated with the time, the offset can be positive or negative e.g."oneDayAgo@01:00+01:00", "oneDayAgo@01:00-01:00". Values older than 1 day are accepted only with valid Enterprise Token available.  (default: PT0S, e.g. 2023-01-01,P-1Y,PT0S,lastWorkingDay@12:00)
  --timelineVisible: oneof<nothing, bool> # Indicates whether the timeline should be shown. (default: false, e.g. true)
  --timelineLabels: string # Overridden labels in the timeline view (default: {}, e.g. {})
  --highlightingMode: string # Highlighting mode for the table view. (default: inline, e.g. inline)
  --highlightedAttributes: string # Highlighted attributes mode for the table view when `highlightingMode` is `inline`. When set to `[]` all highlightable attributes will be returned as `highlightedAttributes`. (default: ['type', 'priority'], e.g. [])
  --showHierarchies: oneof<nothing, bool> # Indicates whether the hierarchy mode should be enabled. (default: true, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "columns" $columns "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "timelineVisible" $timelineVisible "scalar") (serialize-qp "timelineLabels" $timelineLabels "scalar") (serialize-qp "highlightingMode" $highlightingMode "scalar") (serialize-qp "highlightedAttributes" $highlightedAttributes "scalar") (serialize-qp "showHierarchies" $showHierarchies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/queries/($id)" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit Query
#
# PATCH /api/v3/queries/{id}
# operationId: Edit_Query
export def "queries Query" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Query name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query Update Form
#
# POST /api/v3/queries/{id}/form
# operationId: Query_Update_Form
export def "queries-form Form-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Query name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/($id)/form")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Star query
#
# PATCH /api/v3/queries/{id}/star
# operationId: Star_query
export def "queries-star query" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/($id)/star")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unstar query
#
# PATCH /api/v3/queries/{id}/unstar
# operationId: Unstar_query
export def "queries-unstar query" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/queries/($id)/unstar")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all visible recurring meetings
#
# GET /api/v3/recurring_meetings
# operationId: list_recurring_meetings
export def "recurring-meetings meetings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/recurring_meetings")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create recurring meeting
#
# POST /api/v3/recurring_meetings
# operationId: create_recurring_meeting
# --_links shape: {project?: any}
export def "recurring-meetings meeting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The recurring meeting's title
  --frequency: string@frequency-completer # The recurrence frequency. Possible values:  - *daily* - *working_days* - *weekly* - *monthly_day_of_month* - *monthly_nth_weekday*
  --interval: int # The interval between occurrences. Not applicable for working_days frequency.
  --monthlyDay: int # Day of month for `monthly_day_of_month` frequency. Required for `monthly_day_of_month` unless inferred from `startTime`.
  --monthlyOrdinal: int@monthlyOrdinal-completer # Ordinal position for `monthly_nth_weekday` frequency. Required for `monthly_nth_weekday` unless inferred from `startTime`. Allowed values: - `1` (first) - `2` (second) - `3` (third) - `4` (fourth) - `-1` (last)
  --monthlyWeekday: string@monthlyWeekday-completer # Weekday for `monthly_nth_weekday` frequency. Required for `monthly_nth_weekday` unless inferred from `startTime`.
  --endAfter: string@endAfter-completer # How the recurrence ends. Possible values:  - *specific_date* - *iterations* - *never*
  --endDate: string # The date on which the recurrence ends. Required when endAfter is `specific_date`. (nullable, format: date)
  --iterations: int # The number of occurrences after which the recurrence ends. Required when endAfter is `iterations`. (nullable)
  --startTime: string # The scheduled start time of the recurring meeting. (format: date-time)
  --location: string # The meeting's location.
  --duration: float # The meeting duration in hours.
  --notify: oneof<nothing, bool> # Whether to send email notifications to participants.
  --links: record # shape: {project?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/recurring_meetings")
  let body = {title: $title, frequency: $frequency, interval: $interval, monthlyDay: $monthlyDay, monthlyOrdinal: $monthlyOrdinal, monthlyWeekday: $monthlyWeekday, endAfter: $endAfter, endDate: $endDate, iterations: $iterations, startTime: $startTime, location: $location, duration: $duration, notify: $notify, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a recurring meeting
#
# GET /api/v3/recurring_meetings/{id}
# operationId: get_recurring_meeting
export def "recurring-meetings meeting-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update recurring meeting
#
# PATCH /api/v3/recurring_meetings/{id}
# operationId: update_recurring_meeting
# --_links shape: {project?: any}
export def "recurring-meetings meeting-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The recurring meeting's title
  --frequency: string@frequency-completer # The recurrence frequency. Possible values:  - *daily* - *working_days* - *weekly* - *monthly_day_of_month* - *monthly_nth_weekday*
  --interval: int # The interval between occurrences. Not applicable for working_days frequency.
  --monthlyDay: int # Day of month for `monthly_day_of_month` frequency. Required for `monthly_day_of_month` unless inferred from `startTime`.
  --monthlyOrdinal: int@monthlyOrdinal-completer # Ordinal position for `monthly_nth_weekday` frequency. Required for `monthly_nth_weekday` unless inferred from `startTime`. Allowed values: - `1` (first) - `2` (second) - `3` (third) - `4` (fourth) - `-1` (last)
  --monthlyWeekday: string@monthlyWeekday-completer # Weekday for `monthly_nth_weekday` frequency. Required for `monthly_nth_weekday` unless inferred from `startTime`.
  --endAfter: string@endAfter-completer # How the recurrence ends. Possible values:  - *specific_date* - *iterations* - *never*
  --endDate: string # The date on which the recurrence ends. Required when endAfter is `specific_date`. (nullable, format: date)
  --iterations: int # The number of occurrences after which the recurrence ends. Required when endAfter is `iterations`. (nullable)
  --startTime: string # The scheduled start time of the recurring meeting. (format: date-time)
  --location: string # The meeting's location.
  --duration: float # The meeting duration in hours.
  --notify: oneof<nothing, bool> # Whether to send email notifications to participants.
  --links: record # shape: {project?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)")
  let body = {title: $title, frequency: $frequency, interval: $interval, monthlyDay: $monthlyDay, monthlyOrdinal: $monthlyOrdinal, monthlyWeekday: $monthlyWeekday, endAfter: $endAfter, endDate: $endDate, iterations: $iterations, startTime: $startTime, location: $location, duration: $duration, notify: $notify, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete recurring meeting
#
# DELETE /api/v3/recurring_meetings/{id}
# operationId: delete_recurring_meeting
export def "recurring-meetings meeting-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List upcoming occurrences of a recurring meeting
#
# GET /api/v3/recurring_meetings/{id}/occurrences/upcoming
# operationId: list_recurring_meeting_occurrences_upcoming
export def "recurring-meetings-occurrences-upcoming upcoming" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of occurrences to return. Defaults to 20. (default: 20, e.g. 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)/occurrences/upcoming" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List past occurrences of a recurring meeting
#
# GET /api/v3/recurring_meetings/{id}/occurrences/past
# operationId: list_recurring_meeting_occurrences_past
export def "recurring-meetings-occurrences-past past" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)/occurrences/past")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List cancelled occurrences of a recurring meeting
#
# GET /api/v3/recurring_meetings/{id}/occurrences/cancelled
# operationId: list_recurring_meeting_occurrences_cancelled
export def "recurring-meetings-occurrences-cancelled cancelled" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)/occurrences/cancelled")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List open occurrences of a recurring meeting
#
# GET /api/v3/recurring_meetings/{id}/occurrences/open
# operationId: list_recurring_meeting_occurrences_open
export def "recurring-meetings-occurrences-open open" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)/occurrences/open")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel an occurrence
#
# DELETE /api/v3/recurring_meetings/{id}/occurrences/{start_time}
# operationId: cancel_recurring_meeting_occurrence
export def "recurring-meetings-occurrences occurrence" [
  id: int
  start_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)/occurrences/($start_time)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Instantiate an occurrence
#
# POST /api/v3/recurring_meetings/{id}/occurrences/{start_time}/init
# operationId: init_recurring_meeting_occurrence
export def "recurring-meetings-occurrences-init occurrence" [
  id: int
  start_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/recurring_meetings/($id)/occurrences/($start_time)/init")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Relations
#
# GET /api/v3/relations
# operationId: list_relations
export def "relations relations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Valid fields to filter by are:  - id - ID of relation - from - ID of work package from which the filtered relations emanates. - to - ID of work package to which this related points. - involved - ID of either the `from` or the `to` work package. - type - The type of relation to filter by, e.g. "follows". (e.g. [{ "from": { "operator": "=", "values": 42 }" }])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. (e.g. [["type", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/relations" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Relation
#
# GET /api/v3/relations/{id}
# operationId: get_relation
export def "relations relation-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/relations/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Relation
#
# DELETE /api/v3/relations/{id}
# operationId: delete_relation
export def "relations relation-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/relations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Relation
#
# PATCH /api/v3/relations/{id}
# operationId: update_relation
# --_links shape: {to?: any}
export def "relations relation-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-6 # The relation type.
  --description: string # A descriptive text for the relation. (nullable)
  --lag: int # The lag in days between closing of `from` and start of `to` (nullable)
  links: record # shape: {to?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/relations/($id)")
  let body = {type: $type, description: $description, lag: $lag, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview Markdown document
#
# POST /api/v3/render/markdown
# operationId: Preview_Markdown_document
export def "render-markdown document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # API-Link to the context in which the rendering occurs, for example a specific work package.  If left out only context-agnostic rendering takes place. Please note that OpenProject features markdown-extensions on top of the extensions GitHub Flavored Markdown (gfm) already provides that can only work given a context (e.g. display attached images).  **Supported contexts:**  * `/api/v3/work_packages/{id}` - an existing work package (e.g. /api/v3/work_packages/42)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context" $context "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/render/markdown" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview plain document
#
# POST /api/v3/render/plain
# operationId: Preview_plain_document
export def "render-plain document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/render/plain")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View revision
#
# GET /api/v3/revisions/{id}
# operationId: View_revision
export def "revisions revision" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/revisions/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all active reminders
#
# GET /api/v3/reminders
# operationId: list_reminders
export def "reminders reminders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/reminders")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a reminder
#
# PATCH /api/v3/reminders/{id}
# operationId: update_reminder
export def "reminders reminder-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remindAt: string # The date and time when the reminder is due (format: date-time)
  --note: string # The note of the reminder (optional)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/reminders/($id)")
  let body = {remindAt: $remindAt, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a reminder
#
# DELETE /api/v3/reminders/{id}
# operationId: delete_reminder
export def "reminders reminder-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/reminders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List roles
#
# GET /api/v3/roles
# operationId: List_roles
export def "roles roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + grantable: filters roles based on whether they are selectable for a membership  + unit: filters roles based on the unit ('project' or 'system') for which they are selectable for a membership (e.g. [{ "unit": { "operator": "=", "values": ["system"] }" }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/roles" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View role
#
# GET /api/v3/roles/{id}
# operationId: View_role
export def "roles role" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/roles/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sprints
#
# GET /api/v3/sprints
# operationId: List_sprints
export def "sprints sprints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + definingWorkspace: filters sprints based on the project they are defined in. This is opposed to the projects they are shared with. (e.g. [{ "definingWorkspace": { "operator": "=", "values": ["1"] }" }])
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/sprints" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sprint
#
# GET /api/v3/sprints/{id}
# operationId: get_sprint
export def "sprints sprint" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/sprints/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the collection of all statuses
#
# GET /api/v3/statuses
# operationId: list_statuses
export def "statuses statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/statuses")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a work package status
#
# GET /api/v3/statuses/{id}
# operationId: get_status
export def "statuses status" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/statuses/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Storages
#
# GET /api/v3/storages
# operationId: list_storages
export def "storages storages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/storages")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a storage.
#
# POST /api/v3/storages
# operationId: create_storage
# --_links shape: {origin: any, type: any, authenticationMethod?: any}
export def "storages storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Storage name, if not provided, falls back to a default.
  --storageAudience: string # The audience that the storage expects in tokens for requests to it, usually the storage's client ID at the identity provider.  This is only required for authentication through single-sign-on and so far only supported for provider type Nextcloud.
  --tokenExchangeScope: string # The scope that will be requested when requesting a token for the storage through token exchange. Has no effect if no token exchange is performed.  This is only required for authentication through single-sign-on and so far only supported for provider type Nextcloud.
  --applicationPassword: string # The application password to use for the Nextcloud storage. Ignored if the provider type is not Nextcloud.  If a string is provided, the password is set and automatic management is enabled for the storage. If null is provided, the password is unset and automatic management is disabled for the storage. (nullable)
  --forbiddenFileNameCharacters: string # A string with all the characters forbidden to be used for file and folder names in the storage. Used by OpenProject to avoid creating files with unsupported names (e.g. when creating project folders).  Only supported for provider type Nextcloud so far.
  --links: record # shape: {origin: any, type: any, authenticationMethod?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/storages")
  let body = {name: $name, storageAudience: $storageAudience, tokenExchangeScope: $tokenExchangeScope, applicationPassword: $applicationPassword, forbiddenFileNameCharacters: $forbiddenFileNameCharacters, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a storage
#
# GET /api/v3/storages/{id}
# operationId: get_storage
export def "storages storage-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a storage
#
# PATCH /api/v3/storages/{id}
# operationId: update_storage
# --_links shape: {origin: any, type: any, authenticationMethod?: any}
export def "storages storage-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Storage name, if not provided, falls back to a default.
  --storageAudience: string # The audience that the storage expects in tokens for requests to it, usually the storage's client ID at the identity provider.  This is only required for authentication through single-sign-on and so far only supported for provider type Nextcloud.
  --tokenExchangeScope: string # The scope that will be requested when requesting a token for the storage through token exchange. Has no effect if no token exchange is performed.  This is only required for authentication through single-sign-on and so far only supported for provider type Nextcloud.
  --applicationPassword: string # The application password to use for the Nextcloud storage. Ignored if the provider type is not Nextcloud.  If a string is provided, the password is set and automatic management is enabled for the storage. If null is provided, the password is unset and automatic management is disabled for the storage. (nullable)
  --forbiddenFileNameCharacters: string # A string with all the characters forbidden to be used for file and folder names in the storage. Used by OpenProject to avoid creating files with unsupported names (e.g. when creating project folders).  Only supported for provider type Nextcloud so far.
  --links: record # shape: {origin: any, type: any, authenticationMethod?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)")
  let body = {name: $name, storageAudience: $storageAudience, tokenExchangeScope: $tokenExchangeScope, applicationPassword: $applicationPassword, forbiddenFileNameCharacters: $forbiddenFileNameCharacters, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a storage
#
# DELETE /api/v3/storages/{id}
# operationId: delete_storage
export def "storages storage-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets files of a storage.
#
# GET /api/v3/storages/{id}/files
# operationId: get_storage_files
export def "storages-files files" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent: string # Parent file identification (e.g. /my/data)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/storages/($id)/files" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preparation of a direct upload of a file to the given storage.
#
# POST /api/v3/storages/{id}/files/prepare_upload
# operationId: prepare_storage_file_upload
export def "storages-files-prepare-upload upload" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  projectId: int # The project identifier, from where a user starts uploading a file.
  fileName: string # The file name.
  parent: string # The directory to which the file is to be uploaded. For root directories, the value `/` must be provided.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)/files/prepare_upload")
  let body = {projectId: $projectId, fileName: $fileName, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creation of a new folder
#
# POST /api/v3/storages/{id}/folders
# operationId: create_storage_folder
export def "storages-folders folder" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the folder to be created
  parentId: string # Unique identifier of the parent folder in which the new folder should be created in
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)/folders")
  let body = {name: $name, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an oauth client credentials object for a storage.
#
# POST /api/v3/storages/{id}/oauth_client_credentials
# operationId: create_storage_oauth_credentials
export def "storages-oauth-client-credentials credentials" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clientId: string # OAuth 2 client id
  clientSecret: string # OAuth 2 client secret
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)/oauth_client_credentials")
  let body = {clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Open the storage
#
# GET /api/v3/storages/{id}/open
# operationId: open_storage
export def "storages-open storage" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/storages/($id)/open")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List time entries
#
# GET /api/v3/time_entries
# operationId: list_time_entries
export def "time-entries entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported sorts are:  + id: Sort by primary key  + hours: Sort by logged hours  + spent_on: Sort by spent on date  + created_at: Sort by time entry creation datetime  + updated_at: Sort by the time the time entry was updated last (default: ["spent_on", "asc"], e.g. [["spent_on", "asc"]])
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + entity_type: Filter time entries depending on the entity they are logged on. Can either be `WorkPackage` or `Meeting`.  + entity_id: Filter time entries for the specified entity IDs.  + project_id: Filter time entries by project  + user_id: Filter time entries by users  + ongoing: Filter to only recevie ongoing timers  + spent_on: Filter time entries by spent on date  + created_at: Filter time entries by creation datetime  + updated_at: Filter time entries by the last time they where updated  + activity_id: Filter time entries by time entry activity (e.g. [{ "entity_type": { "operator": "=", "values": ["WorkPackage"] }}, { "entity_id": { "operator": "=", "values": ["1", "2"] } }, { "project": { "operator": "=", "values": ["1"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/time_entries" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create time entry
#
# POST /api/v3/time_entries
# operationId: create_time_entry
# --_links shape: {self: any, updateImmediately?: any, update?: any, delete?: any, schema?: any, project: any, entity: any, user: any, activity: any}
export def "time-entries entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # The id of the time entry
  --comment: any
  --spentOn: string # The date the expenditure is booked for (format: date)
  --hours: string # The time quantifying the expenditure (format: duration)
  --ongoing: oneof<nothing, bool> # Whether the time entry is actively tracking time
  --createdAt: string # The time the time entry was created (format: date-time)
  --startTime: string # The time the time entry was started, or null if the time entry does not have a start time.  The time is returned as UTC time, if presented to the user it should be converted to the user's timezone.  This field is only available if the global `allow_tracking_start_and_end_times` setting is enabled. (nullable, format: date-time)
  --endTime: string # The time the time entry was ended, or null if the time entry does not have a start time.  The time is returned as UTC time, if presented to the user it should be converted to the user's timezone.  This field is only available if the global `allow_tracking_start_and_end_times` setting is enabled. (nullable, format: date-time)
  --updatedAt: string # The time the time entry was last updated (format: date-time)
  --links: record # shape: {self: any, updateImmediately?: any, update?: any, delete?: any, schema?: any, project: any, entity: any, user: any, activity: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/time_entries")
  let body = {id: $id, comment: $comment, spentOn: $spentOn, hours: $hours, ongoing: $ongoing, createdAt: $createdAt, startTime: $startTime, endTime: $endTime, updatedAt: $updatedAt, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Time entry update form
#
# POST /api/v3/time_entries/{id}/form
# operationId: Time_entry_update_form
export def "time-entries-form form-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/time_entries/($id)/form")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View time entries activity
#
# GET /api/v3/time_entries/activity/{id}
# operationId: get_time_entries_activity
export def "time-entries-activity activity" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/time_entries/activity/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available projects for time entries
#
# GET /api/v3/time_entries/available_projects
# operationId: Available_projects_for_time_entries
export def "time-entries-available-projects entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/time_entries/available_projects")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Time entry create form
#
# POST /api/v3/time_entries/form
# operationId: Time_entry_create_form
export def "time-entries-form form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/time_entries/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View time entry schema
#
# GET /api/v3/time_entries/schema
# operationId: View_time_entry_schema
export def "time-entries-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/time_entries/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete time entry
#
# DELETE /api/v3/time_entries/{id}
# operationId: delete_time_entry
export def "time-entries entry-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/time_entries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get time entry
#
# GET /api/v3/time_entries/{id}
# operationId: get_time_entry
export def "time-entries entry-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/time_entries/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# update time entry
#
# PATCH /api/v3/time_entries/{id}
# operationId: update_time_entry
export def "time-entries entry-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/time_entries/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Types
#
# GET /api/v3/types
# operationId: List_all_Types
export def "types Types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/types")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Type
#
# GET /api/v3/types/{id}
# operationId: View_Type
export def "types Type" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/types/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Users
#
# GET /api/v3/users
# operationId: list_Users
export def "users Users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + status: Status the user has  + group: Name of the group in which to-be-listed users are members.  + name: Filter users in whose first or last names, or email addresses the given string occurs.  + login: User's login (e.g. [{ "status": { "operator": "=", "values": ["invited"] } }, { "group": { "operator": "=", "values": ["1"] } }, { "name": { "operator": "=", "values": ["h.wurst@openproject.com"] } }])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. (e.g. [["status", "asc"]])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/name,elements/self,self)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/users" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create User
#
# POST /api/v3/users
# operationId: create_user
export def "users user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool>
  email: string
  login: string
  --password: string # The user's password.  *Conditions:*  Writable on create.  Writable on update only when: - the caller updates their own account - `currentPassword` is provided and valid
  --currentPassword: string # The user's current password.  *Conditions:*  Required when changing `password` for a self update (`PATCH /api/v3/users/me` or `PATCH /api/v3/users/{id}` where `id` is the caller).  Ignored for non-self updates (for example, administrators updating other users).
  firstName: string
  lastName: string
  --status: string # The current activation status of the user.  *Conditions:*  Only writable on creation, not on update.
  language: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/users")
  let body = {admin: $admin, email: $email, login: $login, password: $password, currentPassword: $currentPassword, firstName: $firstName, lastName: $lastName, status: $status, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View user schema
#
# GET /api/v3/users/schema
# operationId: View_user_schema
export def "users-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/users/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /api/v3/users/{id}
# operationId: delete_user
export def "users user-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View user
#
# GET /api/v3/users/{id}
# operationId: view_user
export def "users user-by-id-1" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user
#
# PATCH /api/v3/users/{id}
# operationId: update_user
export def "users user-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin: oneof<nothing, bool>
  email: string
  login: string
  --password: string # The user's password.  *Conditions:*  Writable on create.  Writable on update only when: - the caller updates their own account - `currentPassword` is provided and valid
  --currentPassword: string # The user's current password.  *Conditions:*  Required when changing `password` for a self update (`PATCH /api/v3/users/me` or `PATCH /api/v3/users/{id}` where `id` is the caller).  Ignored for non-self updates (for example, administrators updating other users).
  firstName: string
  lastName: string
  --status: string # The current activation status of the user.  *Conditions:*  Only writable on creation, not on update.
  language: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)")
  let body = {admin: $admin, email: $email, login: $login, password: $password, currentPassword: $currentPassword, firstName: $firstName, lastName: $lastName, status: $status, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# User update form
#
# POST /api/v3/users/{id}/form
# operationId: User_update_form
export def "users-form form" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlock user
#
# DELETE /api/v3/users/{id}/lock
# operationId: unlock_user
export def "users-lock user-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/lock")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lock user
#
# POST /api/v3/users/{id}/lock
# operationId: lock_user
export def "users-lock user-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/lock")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List personal non-working times for a user
#
# GET /api/v3/users/{id}/non_working_times
# operationId: list_user_non_working_times
export def "users-non-working-times times" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Filter results to the given year. Defaults to the current year if not provided. (e.g. 2025)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/users/($id)/non_working_times" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a personal non-working day for a user
#
# POST /api/v3/users/{id}/non_working_times
# operationId: create_user_non_working_time
# --_links shape: {self: any, user: any}
export def "users-non-working-times time-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-7
  --body-id: int # The unique identifier of the non-working time record.
  startDate: string # The first date of the non-working time range in ISO 8601 format (YYYY-MM-DD). (format: date)
  endDate: string # The last date of the non-working time range in ISO 8601 format (YYYY-MM-DD). Must be greater than or equal to `startDate`. (format: date)
  --links: record # shape: {self: any, user: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/non_working_times")
  let body = {_type: $type, id: $body_id, startDate: $startDate, endDate: $endDate, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a personal non-working time record
#
# GET /api/v3/users/{id}/non_working_times/{non_working_time_id}
# operationId: view_user_non_working_time
export def "users-non-working-times time-by-id-non_working_time_id" [
  id: string
  non_working_time_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/non_working_times/($non_working_time_id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a personal non-working time record
#
# PATCH /api/v3/users/{id}/non_working_times/{non_working_time_id}
# operationId: update_user_non_working_time
# --_links shape: {self: any, user: any}
export def "users-non-working-times time-by-id-non_working_time_id-1" [
  id: string
  non_working_time_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-7
  --body-id: int # The unique identifier of the non-working time record.
  startDate: string # The first date of the non-working time range in ISO 8601 format (YYYY-MM-DD). (format: date)
  endDate: string # The last date of the non-working time range in ISO 8601 format (YYYY-MM-DD). Must be greater than or equal to `startDate`. (format: date)
  --links: record # shape: {self: any, user: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/non_working_times/($non_working_time_id)")
  let body = {_type: $type, id: $body_id, startDate: $startDate, endDate: $endDate, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a personal non-working time record
#
# DELETE /api/v3/users/{id}/non_working_times/{non_working_time_id}
# operationId: delete_user_non_working_time
export def "users-non-working-times time-by-id-non_working_time_id-2" [
  id: string
  non_working_time_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/non_working_times/($non_working_time_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List working hours for a user
#
# GET /api/v3/users/{id}/working_hours
# operationId: list_user_working_hours
export def "users-working-hours hours-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/working_hours")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a working hours record for a user
#
# POST /api/v3/users/{id}/working_hours
# operationId: create_user_working_hours
# --_links shape: {self: any, user: any}
export def "users-working-hours hours-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-8
  --body-id: int # The unique identifier of the working hours record.
  validFrom: string # The date from which this working hours configuration is in effect (ISO 8601 format). Multiple records may exist for a user; the one with the latest `validFrom` that is not in the future is the currently active record. (format: date)
  mondayHours: float # Hours worked on Monday. (format: float)
  tuesdayHours: float # Hours worked on Tuesday. (format: float)
  wednesdayHours: float # Hours worked on Wednesday. (format: float)
  thursdayHours: float # Hours worked on Thursday. (format: float)
  fridayHours: float # Hours worked on Friday. (format: float)
  saturdayHours: float # Hours worked on Saturday. (format: float)
  sundayHours: float # Hours worked on Sunday. (format: float)
  availabilityFactor: int # The percentage of working hours the user is available. Must be between 0 and 100.
  --links: record # shape: {self: any, user: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/working_hours")
  let body = {_type: $type, id: $body_id, validFrom: $validFrom, mondayHours: $mondayHours, tuesdayHours: $tuesdayHours, wednesdayHours: $wednesdayHours, thursdayHours: $thursdayHours, fridayHours: $fridayHours, saturdayHours: $saturdayHours, sundayHours: $sundayHours, availabilityFactor: $availabilityFactor, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a working hours record
#
# GET /api/v3/users/{id}/working_hours/{working_hours_id}
# operationId: view_user_working_hours_record
export def "users-working-hours record-by-id-working_hours_id" [
  id: int
  working_hours_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/working_hours/($working_hours_id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a working hours record
#
# PATCH /api/v3/users/{id}/working_hours/{working_hours_id}
# operationId: update_user_working_hours_record
# --_links shape: {self: any, user: any}
export def "users-working-hours record-by-id-working_hours_id-1" [
  id: int
  working_hours_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-8
  --body-id: int # The unique identifier of the working hours record.
  validFrom: string # The date from which this working hours configuration is in effect (ISO 8601 format). Multiple records may exist for a user; the one with the latest `validFrom` that is not in the future is the currently active record. (format: date)
  mondayHours: float # Hours worked on Monday. (format: float)
  tuesdayHours: float # Hours worked on Tuesday. (format: float)
  wednesdayHours: float # Hours worked on Wednesday. (format: float)
  thursdayHours: float # Hours worked on Thursday. (format: float)
  fridayHours: float # Hours worked on Friday. (format: float)
  saturdayHours: float # Hours worked on Saturday. (format: float)
  sundayHours: float # Hours worked on Sunday. (format: float)
  availabilityFactor: int # The percentage of working hours the user is available. Must be between 0 and 100.
  --links: record # shape: {self: any, user: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/working_hours/($working_hours_id)")
  let body = {_type: $type, id: $body_id, validFrom: $validFrom, mondayHours: $mondayHours, tuesdayHours: $tuesdayHours, wednesdayHours: $wednesdayHours, thursdayHours: $thursdayHours, fridayHours: $fridayHours, saturdayHours: $saturdayHours, sundayHours: $sundayHours, availabilityFactor: $availabilityFactor, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a working hours record
#
# DELETE /api/v3/users/{id}/working_hours/{working_hours_id}
# operationId: delete_user_working_hours_record
export def "users-working-hours record-by-id-working_hours_id-2" [
  id: int
  working_hours_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/users/($id)/working_hours/($working_hours_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Values schema
#
# GET /api/v3/values/schema/{id}
# operationId: View_values_schema
export def "values-schema schema" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/values/schema/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List versions
#
# GET /api/v3/versions
# operationId: list_versions
export def "versions versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  - sharing: filters versions by how they are shared within the server (*none*, *descendants*, *hierarchy*, *tree*, *system*). - name: filters versions by their name. (e.g. [{ "sharing": { "operator": "=", "values": ["system"] } }])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported attributes are:  - id: Sort by the version id - name: Sort by the version name using numeric collation, comparing sequences of decimal digits by their numeric value (e.g. [["name", "desc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/versions" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create version
#
# POST /api/v3/versions
# operationId: create_version
# --description shape: {raw?: string}
export def "versions version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Version name
  --description: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --startDate: string # nullable, format: date
  --endDate: string # nullable, format: date
  --status: string@status-completer # The current status of the version. This could be:  - *open*: if the version is available to be assigned to work packages in all shared projects - *locked*: if the version is not finished, but locked for further assignments to work packages - *closed*: if the version is finished
  --sharing: string@sharing-completer-1 # The indicator of how the version is shared between projects. This could be:  - *none*: if the version is only available in the defining project - *descendants*: if the version is shared with the descendants of the defining project - *hierarchy*: if the version is shared with the descendants and the ancestors of the defining project - *tree*: if the version is shared with the root project of the defining project and all descendants of the root project - *system*: if the version is shared globally
  --links: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/versions")
  let body = {name: $name, description: $description, startDate: $startDate, endDate: $endDate, status: $status, sharing: $sharing, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Available projects for versions
#
# GET /api/v3/versions/available_projects
# operationId: Available_projects_for_versions
export def "versions-available-projects versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/versions/available_projects")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Version create form
#
# POST /api/v3/versions/form
# operationId: Version_create_form
export def "versions-form form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/versions/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View version schema
#
# GET /api/v3/versions/schema
# operationId: View_version_schema
export def "versions-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/versions/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version
#
# GET /api/v3/versions/{id}
# operationId: get_version
export def "versions version-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/versions/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete version
#
# DELETE /api/v3/versions/{id}
# operationId: delete_Version
export def "versions Version-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/versions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Version
#
# PATCH /api/v3/versions/{id}
# operationId: update_Version
# --description shape: {raw?: string}
export def "versions Version-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Version name
  --description: record # e.g. {format: markdown, raw: I am formatted!, html: I am formatted!} — shape: {raw?: string}
  --startDate: string # nullable, format: date
  --endDate: string # nullable, format: date
  --status: string@status-completer # The current status of the version. This could be:  - *open*: if the version is available to be assigned to work packages in all shared projects - *locked*: if the version is not finished, but locked for further assignments to work packages - *closed*: if the version is finished
  --sharing: string@sharing-completer-1 # The indicator of how the version is shared between projects. This could be:  - *none*: if the version is only available in the defining project - *descendants*: if the version is shared with the descendants of the defining project - *hierarchy*: if the version is shared with the descendants and the ancestors of the defining project - *tree*: if the version is shared with the root project of the defining project and all descendants of the root project - *system*: if the version is shared globally
  --links: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/versions/($id)")
  let body = {name: $name, description: $description, startDate: $startDate, endDate: $endDate, status: $status, sharing: $sharing, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Version update form
#
# POST /api/v3/versions/{id}/form
# operationId: Version_update_form
export def "versions-form form-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/versions/($id)/form")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projects having version
#
# GET /api/v3/versions/{id}/projects
# operationId: List_projects_with_version
export def "versions-projects version" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/versions/($id)/projects")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List workspaces having version
#
# GET /api/v3/versions/{id}/workspaces
# operationId: List_workspaces_with_version
export def "versions-workspaces version" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/versions/($id)/workspaces")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List views
#
# GET /api/v3/views
# operationId: List_views
export def "views views" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Currently supported filters are:  + project: filters views by the project their associated query is assigned to. If the project filter is passed with the `!*` (not any) operator, global views are returned.  + id: filters views based on their id  + type: filters views based on their type (e.g. [{ "project_id": { "operator": "!*", "values": null }" }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/views" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View view
#
# GET /api/v3/views/{id}
# operationId: View_view
export def "views view" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/views/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create view
#
# POST /api/v3/views/{id}
# operationId: Create_views
# --_links shape: {query?: record}
export def "views views-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {query?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/views/($id)")
  let body = {_links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View Wiki Page
#
# GET /api/v3/wiki_pages/{id}
# operationId: View_Wiki_Page
export def "wiki-pages Page" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/wiki_pages/($id)")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attachments by wiki page
#
# GET /api/v3/wiki_pages/{id}/attachments
# operationId: List_attachments_by_wiki_page
export def "wiki-pages-attachments page-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/wiki_pages/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add attachment to wiki page
#
# POST /api/v3/wiki_pages/{id}/attachments
# operationId: Add_attachment_to_wiki_page
export def "wiki-pages-attachments page-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/wiki_pages/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List work packages
#
# GET /api/v3/work_packages
# operationId: list_work_packages
export def "work-packages packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. If no filter is to be applied, the client should send an empty array (`[]`), otherwise a default filter is applied. A Currently supported filters are (there are additional filters added by modules):  - assigned_to - assignee_or_group - attachment_base - attachment_content - attachment_file_name - author - blocked - blocks - category - comment - created_at - custom_field - dates_interval - description - done_ratio - due_date - duplicated - duplicates - duration - estimated_hours - file_link_origin_id - follows - group - id - includes - linkable_to_storage_id - linkable_to_storage_url - manual_sort - milestone - only_subproject - parent - partof - precedes - principal_base - priority - project - relatable - relates - required - requires - responsible - role - search - start_date - status - storage_id - storage_url - subject - subject_or_id - subproject - type - typeahead - updated_at - version - watcher - work_package (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "type_id": { "operator": "=", "values": ["1", "2"] }}])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. (default: false, e.g. true)
  --select: string # Comma separated list of properties to include. (e.g. total,elements/subject,elements/id,self)
  --timestamps: string # In order to perform a [baseline comparison](/docs/api/baseline-comparisons), you may provide one or several timestamps in ISO-8601 format as comma-separated list. The timestamps may be absolute or relative, such as ISO8601 dates, ISO8601 durations and the following relative date keywords: "oneDayAgo@HH:MM+HH:MM", "lastWorkingDay@HH:MM+HH:MM", "oneWeekAgo@HH:MM+HH:MM", "oneMonthAgo@HH:MM+HH:MM". The first "HH:MM" part represents the zero paded hours and minutes. The last "+HH:MM" part represents the timezone offset from UTC associated with the time, the offset can be positive or negative e.g."oneDayAgo@01:00+01:00", "oneDayAgo@01:00-01:00".  Usually, the first timestamp is the baseline date, the last timestamp is the current date. Values older than 1 day are accepted only with valid Enterprise Token available. (default: PT0S, e.g. 2022-01-01T00:00:00Z,PT0S)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "timestamps" $timestamps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/work_packages" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Work Package
#
# POST /api/v3/work_packages
# operationId: create_work_package
# --_links shape: {addComment?: any, addRelation?: any, addWatcher?: any, previewMarkup?: any, removeWatcher?: any, delete?: any, logTime?: any, move?: any, copy?: any, unwatch?: any, update?: any, updateImmediately?: any, watch?: any, self: any, schema: any, attachments?: any, addAttachment?: any, prepareAttachment?: any, author: any, assignee?: any, availableWatchers?: any, budget?: any, category?: any, addFileLink?: any, fileLinks?: any, parent?: any, priority: any, project: any, projectPhase?: any, projectPhaseDefinition?: any, responsible?: any, relations?: any, revisions?: any, status: any, sprint?: any, timeEntries?: any, type: any, version?: any, watchers?: any}
export def "work-packages package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Indicates whether change notifications (e.g. via E-Mail) should be sent. Note that this controls notifications for all users interested in changes to the work package (e.g. watchers, author and assignee), not just the current user. (default: true, e.g. false)
  subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --readonly: oneof<nothing, bool> # If true, the work package is in a readonly status so with the exception of the status, no other property can be altered.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --date: string # Date on which a milestone is achieved (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --storyPoints: int # The estimation in story points on how long this work package will take to complete  # Conditions  **Permission** Backlogs needs to be enabled in the work package's project and the work package's type is configured to be a backlog type. (nullable)
  --percentageDone: int # Amount of total completion for a work package (nullable)
  links: record # shape: {addComment?: any, addRelation?: any, addWatcher?: any, previewMarkup?: any, removeWatcher?: any, delete?: any, logTime?: any, move?: any, copy?: any, unwatch?: any, update?: any, updateImmediately?: any, watch?: any, self: any, schema: any, attachments?: any, addAttachment?: any, prepareAttachment?: any, author: any, assignee?: any, availableWatchers?: any, budget?: any, category?: any, addFileLink?: any, fileLinks?: any, parent?: any, priority: any, project: any, projectPhase?: any, projectPhaseDefinition?: any, responsible?: any, relations?: any, revisions?: any, status: any, sprint?: any, timeEntries?: any, type: any, version?: any, watchers?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/work_packages" $qp)
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, readonly: $readonly, startDate: $startDate, dueDate: $dueDate, date: $date, estimatedTime: $estimatedTime, storyPoints: $storyPoints, percentageDone: $percentageDone, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Form for creating a Work Package
#
# POST /api/v3/work_packages/form
# operationId: form_create_work_package
# --_links shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
# --_meta shape: {validateCustomFields?: bool}
export def "work-packages-form package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --duration: string # The amount of time in hours the work package needs to be completed. This value must be bigger or equal to `P1D`, and any the value will get floored to the nearest day.  The duration has no effect, unless either a start date or a due date is set.  Not available for milestone type of work packages. (nullable, format: duration)
  --ignoreNonWorkingDays: oneof<nothing, bool> # When scheduling, whether or not to ignore the non working days being defined. A work package with the flag set to true will be allowed to be scheduled to a non working day.
  --links: record # shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
  --meta: record # Meta information for the work package request — shape: {validateCustomFields?: bool}
]: any -> record<_type: string, _embedded: record<payload: record<subject: string, description: record, scheduleManually: bool, startDate: string, dueDate: string, estimatedTime: string, duration: string, ignoreNonWorkingDays: bool, _links: record, _meta: record>, schema: record<_type: string, _dependencies: list, _attributeGroups: list, lockVersion: record, id: record, subject: record, description: record, duration: record, scheduleManually: record, ignoreNonWorkingDays: record, startDate: record, dueDate: record, derivedStartDate: record, derivedDueDate: record, estimatedTime: record, derivedEstimatedTime: record, remainingTime: record, derivedRemainingTime: record, percentageDone: record, derivedPercentageDone: record, readonly: record, createdAt: record, updatedAt: record, author: record, position: record, project: record, projectPhase: record, projectPhaseDefinition: record, parent: record, sprint: record, storyPoints: record, assignee: record, responsible: record, type: record, status: record, category: record, version: record, priority: record, _links: record>, validationErrors: record>, _links: record<self: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, validate: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, previewMarkup: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, customFields: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, configureForm: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/work_packages/form")
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, startDate: $startDate, dueDate: $dueDate, estimatedTime: $estimatedTime, duration: $duration, ignoreNonWorkingDays: $ignoreNonWorkingDays, _links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Work Package Schemas
#
# GET /api/v3/work_packages/schemas
# operationId: list_work_package_schemas
export def "work-packages-schemas schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + id: The schema's id  Schema id has the form `project_id-work_package_type_id`. (e.g. [{ "id": { "operator": "=", "values": ["12-1", "14-2"] } }])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/work_packages/schemas" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Work Package Schema
#
# GET /api/v3/work_packages/schemas/{identifier}
# operationId: View_Work_Package_Schema
export def "work-packages-schemas Schema" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/schemas/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Work Package
#
# DELETE /api/v3/work_packages/{id}
# operationId: delete_work_package
export def "work-packages package-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Work Package
#
# GET /api/v3/work_packages/{id}
# operationId: view_work_package
export def "work-packages package-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamps: string # In order to perform a [baseline comparison](/docs/api/baseline-comparisons) of the work-package attributes, you may provide one or several timestamps in ISO-8601 format as comma-separated list. The timestamps may be absolute or relative, such as ISO8601 dates, ISO8601 durations and the following relative date keywords: "oneDayAgo@HH:MM+HH:MM", "lastWorkingDay@HH:MM+HH:MM", "oneWeekAgo@HH:MM+HH:MM", "oneMonthAgo@HH:MM+HH:MM". The first "HH:MM" part represents the zero paded hours and minutes. The last "+HH:MM" part represents the timezone offset from UTC associated with the time, the offset can be positive or negative e.g."oneDayAgo@01:00+01:00", "oneDayAgo@01:00-01:00".  Usually, the first timestamp is the baseline date, the last timestamp is the current date. Values older than 1 day are accepted only with valid Enterprise Token available. (default: PT0S, e.g. 2022-01-01T00:00:00Z,PT0S)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamps" $timestamps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/work_packages/($id)" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Work Package
#
# PATCH /api/v3/work_packages/{id}
# operationId: update_work_package
# --_links shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
# --_meta shape: {validateCustomFields?: bool}
export def "work-packages package-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Indicates whether change notifications should be sent. Note that this controls notifications for all users interested in changes to the work package (e.g. watchers, author and assignee), not just the current user. (default: true, e.g. false)
  --subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --duration: string # The amount of time in hours the work package needs to be completed. This value must be bigger or equal to `P1D`, and any the value will get floored to the nearest day.  The duration has no effect, unless either a start date or a due date is set.  Not available for milestone type of work packages. (nullable, format: duration)
  --ignoreNonWorkingDays: oneof<nothing, bool> # When scheduling, whether or not to ignore the non working days being defined. A work package with the flag set to true will be allowed to be scheduled to a non working day.
  --links: record # shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
  --meta: record # Meta information for the work package request — shape: {validateCustomFields?: bool}
  lockVersion: int # The version of the item as used for optimistic locking
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/work_packages/($id)" $qp)
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, startDate: $startDate, dueDate: $dueDate, estimatedTime: $estimatedTime, duration: $duration, ignoreNonWorkingDays: $ignoreNonWorkingDays, _links: $links, _meta: $meta, lockVersion: $lockVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List work package activities
#
# GET /api/v3/work_packages/{id}/activities
# operationId: List_work_package_activities
export def "work-packages-activities activities" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/activities")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Comment work package
#
# POST /api/v3/work_packages/{id}/activities
# operationId: Comment_work_package
# --comment shape: {raw?: string}
export def "work-packages-activities package" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Indicates whether change notifications (e.g. via E-Mail) should be sent. Note that this controls notifications for all users interested in changes to the work package (e.g. watchers, author and assignee), not just the current user. (default: true, e.g. false)
  --comment: record # shape: {raw?: string}
  --internal: oneof<nothing, bool> # Determines whether this comment is internal. This is only available to users with `add_internal_comments` permission. It defaults to `false`, if unset. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/activities" $qp)
  let body = {comment: $comment, internal: $internal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List emoji reactions by work package activities
#
# GET /api/v3/work_packages/{id}/activities_emoji_reactions
# operationId: list_work_package_activities_emoji_reactions
export def "work-packages-activities-emoji-reactions reactions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/activities_emoji_reactions")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attachments by work package
#
# GET /api/v3/work_packages/{id}/attachments
# operationId: list_work_package_attachments
export def "work-packages-attachments attachments" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create work package attachment
#
# POST /api/v3/work_packages/{id}/attachments
# operationId: create_work_package_attachment
export def "work-packages-attachments attachment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/attachments")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Work Package Available assignees
#
# GET /api/v3/work_packages/{id}/available_assignees
# operationId: Work_Package_Available_assignees
export def "work-packages-available-assignees assignees" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/available_assignees")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available projects for work package
#
# GET /api/v3/work_packages/{id}/available_projects
# operationId: Available_projects_for_work_package
export def "work-packages-available-projects package" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/available_projects")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available relation candidates
#
# GET /api/v3/work_packages/{id}/available_relation_candidates
# operationId: list_available_relation_candidates
export def "work-packages-available-relation-candidates candidates" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Maximum number of candidates to list (default 10) (e.g. 25)
  --filters: string # JSON specifying filter conditions. Accepts the same filters as the [work packages](https://www.openproject.org/docs/api/endpoints/work-packages/) endpoint. (e.g. [{ "status_id": { "operator": "o", "values": null } }])
  --qp-query: string # Shortcut for filtering by ID or subject (e.g. "rollout")
  --type: string # Type of relation to find candidates for (default "relates") (e.g. "follows")
  --sortBy: string # JSON specifying sort criteria. Accepts the same sort criteria as the [work packages](https://www.openproject.org/docs/api/endpoints/work-packages/) endpoint. (default: [["id", "asc"]], e.g. [["status", "asc"]])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/available_relation_candidates" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available watchers
#
# GET /api/v3/work_packages/{id}/available_watchers
# operationId: Available_watchers
export def "work-packages-available-watchers watchers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/available_watchers")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates file links.
#
# POST /api/v3/work_packages/{id}/file_links
# operationId: create_work_package_file_link
# --_embedded shape: {elements: list}
export def "work-packages-file-links link" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  embedded: record # shape: {elements: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/file_links")
  let body = {_embedded: $embedded} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all file links of a work package
#
# GET /api/v3/work_packages/{id}/file_links
# operationId: list_work_package_file_links
export def "work-packages-file-links links" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. The following filters are supported:  - storage (e.g. [{"storage":{"operator":"=","values":["42"]}}])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/file_links" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Form for editing a Work Package
#
# POST /api/v3/work_packages/{id}/form
# operationId: form_edit_work_package
# --_links shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
# --_meta shape: {validateCustomFields?: bool}
export def "work-packages-form package-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --duration: string # The amount of time in hours the work package needs to be completed. This value must be bigger or equal to `P1D`, and any the value will get floored to the nearest day.  The duration has no effect, unless either a start date or a due date is set.  Not available for milestone type of work packages. (nullable, format: duration)
  --ignoreNonWorkingDays: oneof<nothing, bool> # When scheduling, whether or not to ignore the non working days being defined. A work package with the flag set to true will be allowed to be scheduled to a non working day.
  --links: record # shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
  --meta: record # Meta information for the work package request — shape: {validateCustomFields?: bool}
]: any -> record<_type: string, _embedded: record<payload: record<subject: string, description: record, scheduleManually: bool, startDate: string, dueDate: string, estimatedTime: string, duration: string, ignoreNonWorkingDays: bool, _links: record, _meta: record>, schema: record<_type: string, _dependencies: list, _attributeGroups: list, lockVersion: record, id: record, subject: record, description: record, duration: record, scheduleManually: record, ignoreNonWorkingDays: record, startDate: record, dueDate: record, derivedStartDate: record, derivedDueDate: record, estimatedTime: record, derivedEstimatedTime: record, remainingTime: record, derivedRemainingTime: record, percentageDone: record, derivedPercentageDone: record, readonly: record, createdAt: record, updatedAt: record, author: record, position: record, project: record, projectPhase: record, projectPhaseDefinition: record, parent: record, sprint: record, storyPoints: record, assignee: record, responsible: record, type: record, status: record, category: record, version: record, priority: record, _links: record>, validationErrors: record>, _links: record<self: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, validate: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, previewMarkup: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, customFields: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, configureForm: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/form")
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, startDate: $startDate, dueDate: $dueDate, estimatedTime: $estimatedTime, duration: $duration, ignoreNonWorkingDays: $ignoreNonWorkingDays, _links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revisions
#
# GET /api/v3/work_packages/{id}/revisions
# operationId: Revisions
export def "work-packages-revisions Revisions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/revisions")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create relation
#
# POST /api/v3/work_packages/{id}/relations
# operationId: create_relation
# --_links shape: {to?: any}
export def "work-packages-relations relation" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-6 # The relation type.
  --description: string # A descriptive text for the relation. (nullable)
  --lag: int # The lag in days between closing of `from` and start of `to` (nullable)
  links: record # shape: {to?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/relations")
  let body = {type: $type, description: $description, lag: $lag, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List work package reminders
#
# GET /api/v3/work_packages/{work_package_id}/reminders
# operationId: list_work_package_reminders
export def "work-packages-reminders reminders" [
  work_package_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($work_package_id)/reminders")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a work package reminder
#
# POST /api/v3/work_packages/{work_package_id}/reminders
# operationId: create_work_package_reminder
export def "work-packages-reminders reminder" [
  work_package_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  remindAt: string # The date and time when the reminder is due (format: date-time)
  --note: string # The note of the reminder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($work_package_id)/reminders")
  let body = {remindAt: $remindAt, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List watchers
#
# GET /api/v3/work_packages/{id}/watchers
# operationId: List_watchers
export def "work-packages-watchers watchers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/watchers")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add watcher
#
# POST /api/v3/work_packages/{id}/watchers
# operationId: Add_watcher
# --user shape: {href?: string}
export def "work-packages-watchers watcher-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # shape: {href?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/watchers")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove watcher
#
# DELETE /api/v3/work_packages/{id}/watchers/{user_id}
# operationId: Remove_watcher
export def "work-packages-watchers watcher-by-id-user_id" [
  id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/work_packages/($id)/watchers/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List workspace
#
# GET /api/v3/workspaces
# operationId: list_workspace
export def "workspaces workspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. Currently supported filters are:  + active: based on the active property of the workspace + ancestor: filters workspace by their ancestor. A workspace is not considered to be its own ancestor. + available_project_attributes: filters workspace based on the activated project attributes. + created_at: based on the time the workspace was created + favorited: based on the favorited property of the workspace + id: based on workspace' id. + latest_activity_at: based on the time the last activity was registered on a workspace. + name_and_identifier: based on both the name and the identifier. + parent_id: filters workspace by their parent. + principal: based on members of the workspace. + project_phase_any: based on the project phases active in a workspace. + project_status_code: based on status code of the workspace + storage_id: filters workspace by linked storages + storage_url: filters workspace by linked storages identified by the host url + type_id: based on the types active in a workspace. + user_action: based on the actions the current user has in the workspace. + visible: based on the visibility for the user (id) provided as the filter value. This filter is useful for admins to identify the workspace visible to a user.  There might also be additional filters based on the custom fields that have been configured.  Each defined lifecycle step will also define a filter in this list endpoint. Given that the elements are not static but rather dynamically created on each OpenProject instance, a list cannot be provided. Those filters follow the schema: + project_start_gate_[id]: a filter on a project phase's start gate active in a workspace. The id is the id of the phase the gate belongs to. + project_finish_gate_[id]: a filter on a project phase's finish gate active in a workspace. The id is the id of the phase the gate belongs to. + project_phase_[id]: a filter on a project phase active in a workspace. The id is the id of the phase queried for. (e.g. [{ "ancestor": { "operator": "=", "values": ["1"] }" }])
  --sortBy: string # JSON specifying sort criteria. Currently supported orders are:  + id + name + typeahead (sorting by hierarchy and name) + created_at + public + latest_activity_at + required_disk_space  There might also be additional orders based on the custom fields that have been configured. (e.g. [["id", "asc"]])
  --select: string # Comma separated list of properties to include. (e.g. total,elements/identifier,elements/name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/workspaces" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Workspace Available assignees
#
# GET /api/v3/workspaces/{id}/available_assignees
# operationId: Workspace_Available_assignees
export def "workspaces-available-assignees assignees" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/available_assignees")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List categories of a workspace
#
# GET /api/v3/workspaces/{id}/categories
# operationId: List_categories_of_a_workspace
export def "workspaces-categories workspace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/categories")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unfavorite Workspace
#
# DELETE /api/v3/workspaces/{id}/favorite
# operationId: Unfavorite_Workspace
export def "workspaces-favorite Workspace-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/favorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Favorite Workspace
#
# POST /api/v3/workspaces/{id}/favorite
# operationId: Favorite_Workspace
export def "workspaces-favorite Workspace-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/favorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View default query for workspace
#
# GET /api/v3/workspaces/{id}/queries/default
# operationId: View_default_query_for_workspace
export def "workspaces-queries-default workspace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON specifying filter conditions. The filters provided as parameters are not applied to the query but are instead used to override the query's persisted filters. All filters also accepted by the work packages endpoint are accepted. If no filter is to be applied, the client should send an empty array (`[]`). (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "assignee": { "operator": "=", "values": ["1", "5"] }" }])
  --offset: int # Page number inside the queries' result collection of work packages. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page for the queries' result collection of work packages. (e.g. 25)
  --sortBy: string # JSON specifying sort criteria. The sort criteria is applied to the query's result collection of work packages overriding the query's persisted sort criteria. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. The grouping criteria is applied to the to the query's result collection of work packages overriding the query's persisted group criteria. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. The showSums parameter is applied to the to the query's result collection of work packages overriding the query's persisted sums property. (default: false, e.g. true)
  --timestamps: string # Indicates the timestamps to filter by when showing changed attributes on work packages. Values can be either ISO8601 dates, ISO8601 durations and the following relative date keywords: "oneDayAgo@HH:MM+HH:MM", "lastWorkingDay@HH:MM+HH:MM", "oneWeekAgo@HH:MM+HH:MM", "oneMonthAgo@HH:MM+HH:MM". The first "HH:MM" part represents the zero paded hours and minutes. The last "+HH:MM" part represents the timezone offset from UTC associated with the time. Values older than 1 day are accepted only with valid Enterprise Token available.  (default: PT0S, e.g. 2023-01-01,P-1Y,PT0S,lastWorkingDay@12:00)
  --timelineVisible: oneof<nothing, bool> # Indicates whether the timeline should be shown. (default: false, e.g. true)
  --showHierarchies: oneof<nothing, bool> # Indicates whether the hierarchy mode should be enabled. (default: true, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "timelineVisible" $timelineVisible "scalar") (serialize-qp "showHierarchies" $showHierarchies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/queries/default" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Query Filter Instance Schemas for Workspace
#
# GET /api/v3/workspace/{id}/queries/filter_instance_schemas
# operationId: List_Query_Filter_Instance_Schemas_for_Workspace
export def "workspace-queries-filter-instance-schemas Workspace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspace/($id)/queries/filter_instance_schemas")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View schema for workspace queries
#
# GET /api/v3/workspace/{id}/queries/schema
# operationId: View_schema_for_workspace_queries
export def "workspace-queries-schema queries" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspace/($id)/queries/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List types available in a workspace
#
# GET /api/v3/workspaces/{id}/types
# operationId: List_types_available_in_a_workspace
export def "workspaces-types workspace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/types")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get work packages of workspace
#
# GET /api/v3/workspaces/{id}/work_packages
# operationId: Get_Workspace_Work_Package_Collection
export def "workspaces-work-packages Collection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Page number inside the requested collection. (default: 1, e.g. 25)
  --pageSize: int # Number of elements to display per page. (e.g. 25)
  --filters: string # JSON specifying filter conditions. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. If no filter is to be applied, the client should send an empty array (`[]`). (default: [{ "status_id": { "operator": "o", "values": null }}], e.g. [{ "type_id": { "operator": "=", "values": ['1', '2'] }}])
  --sortBy: string # JSON specifying sort criteria. Accepts the same format as returned by the [queries](https://www.openproject.org/docs/api/endpoints/queries/) endpoint. (default: [["id", "asc"]], e.g. [["status", "asc"]])
  --groupBy: string # The column to group by. (e.g. status)
  --showSums: oneof<nothing, bool> # Indicates whether properties should be summed up if they support it. (default: false, e.g. true)
  --select: string # Comma separated list of properties to include. (e.g. total,elements/subject,elements/id,self)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "showSums" $showSums "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/work_packages" $qp)
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create work package in workspace
#
# POST /api/v3/workspaces/{id}/work_packages
# operationId: Create_Workspace_Work_Package
# --_links shape: {addComment?: any, addRelation?: any, addWatcher?: any, previewMarkup?: any, removeWatcher?: any, delete?: any, logTime?: any, move?: any, copy?: any, unwatch?: any, update?: any, updateImmediately?: any, watch?: any, self: any, schema: any, attachments?: any, addAttachment?: any, prepareAttachment?: any, author: any, assignee?: any, availableWatchers?: any, budget?: any, category?: any, addFileLink?: any, fileLinks?: any, parent?: any, priority: any, project: any, projectPhase?: any, projectPhaseDefinition?: any, responsible?: any, relations?: any, revisions?: any, status: any, sprint?: any, timeEntries?: any, type: any, version?: any, watchers?: any}
export def "workspaces-work-packages Package" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Indicates whether change notifications (e.g. via E-Mail) should be sent. Note that this controls notifications for all users interested in changes to the work package (e.g. watchers, author and assignee), not just the current user. (default: true, e.g. false)
  subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --readonly: oneof<nothing, bool> # If true, the work package is in a readonly status so with the exception of the status, no other property can be altered.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --date: string # Date on which a milestone is achieved (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --storyPoints: int # The estimation in story points on how long this work package will take to complete  # Conditions  **Permission** Backlogs needs to be enabled in the work package's project and the work package's type is configured to be a backlog type. (nullable)
  --percentageDone: int # Amount of total completion for a work package (nullable)
  links: record # shape: {addComment?: any, addRelation?: any, addWatcher?: any, previewMarkup?: any, removeWatcher?: any, delete?: any, logTime?: any, move?: any, copy?: any, unwatch?: any, update?: any, updateImmediately?: any, watch?: any, self: any, schema: any, attachments?: any, addAttachment?: any, prepareAttachment?: any, author: any, assignee?: any, availableWatchers?: any, budget?: any, category?: any, addFileLink?: any, fileLinks?: any, parent?: any, priority: any, project: any, projectPhase?: any, projectPhaseDefinition?: any, responsible?: any, relations?: any, revisions?: any, status: any, sprint?: any, timeEntries?: any, type: any, version?: any, watchers?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/work_packages" $qp)
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, readonly: $readonly, startDate: $startDate, dueDate: $dueDate, date: $date, estimatedTime: $estimatedTime, storyPoints: $storyPoints, percentageDone: $percentageDone, _links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Form for creating Work Packages in a Workspace
#
# POST /api/v3/workspaces/{id}/work_packages/form
# operationId: form_create_work_package_in_workspace
# --_links shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
# --_meta shape: {validateCustomFields?: bool}
export def "workspaces-work-packages-form workspace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # Work package subject
  --description: any
  --scheduleManually: oneof<nothing, bool> # Uses manual scheduling mode when true (default). Uses automatic scheduling mode when false. Can be automatic only when predecessors or children are present.
  --startDate: string # Scheduled beginning of a work package (nullable, format: date)
  --dueDate: string # Scheduled end of a work package (nullable, format: date)
  --estimatedTime: string # Time a work package likely needs to be completed excluding its descendants (nullable, format: duration)
  --duration: string # The amount of time in hours the work package needs to be completed. This value must be bigger or equal to `P1D`, and any the value will get floored to the nearest day.  The duration has no effect, unless either a start date or a due date is set.  Not available for milestone type of work packages. (nullable, format: duration)
  --ignoreNonWorkingDays: oneof<nothing, bool> # When scheduling, whether or not to ignore the non working days being defined. A work package with the flag set to true will be allowed to be scheduled to a non working day.
  --links: record # shape: {category?: any, type?: any, priority?: any, project?: any, status?: any, responsible?: any, assignee?: any, version?: any, parent?: any}
  --meta: record # Meta information for the work package request — shape: {validateCustomFields?: bool}
]: any -> record<_type: string, _embedded: record<payload: record<subject: string, description: record, scheduleManually: bool, startDate: string, dueDate: string, estimatedTime: string, duration: string, ignoreNonWorkingDays: bool, _links: record, _meta: record>, schema: record<_type: string, _dependencies: list, _attributeGroups: list, lockVersion: record, id: record, subject: record, description: record, duration: record, scheduleManually: record, ignoreNonWorkingDays: record, startDate: record, dueDate: record, derivedStartDate: record, derivedDueDate: record, estimatedTime: record, derivedEstimatedTime: record, remainingTime: record, derivedRemainingTime: record, percentageDone: record, derivedPercentageDone: record, readonly: record, createdAt: record, updatedAt: record, author: record, position: record, project: record, projectPhase: record, projectPhaseDefinition: record, parent: record, sprint: record, storyPoints: record, assignee: record, responsible: record, type: record, status: record, category: record, version: record, priority: record, _links: record>, validationErrors: record>, _links: record<self: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, validate: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, previewMarkup: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, customFields: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>, configureForm: record<href: string, title: string, templated: bool, method: string, payload: record, identifier: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/work_packages/form")
  let body = {subject: $subject, description: $description, scheduleManually: $scheduleManually, startDate: $startDate, dueDate: $dueDate, estimatedTime: $estimatedTime, duration: $duration, ignoreNonWorkingDays: $ignoreNonWorkingDays, _links: $links, _meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List versions available in a workspace
#
# GET /api/v3/workspaces/{id}/versions
# operationId: List_versions_available_in_a_workspace
export def "workspaces-versions workspace" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/workspaces/($id)/versions")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View workspace schema
#
# GET /api/v3/workspaces/schema
# operationId: View_workspace_schema
export def "workspaces-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/workspaces/schema")
  let accept_val = "application/hal+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
