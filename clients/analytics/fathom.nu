# Auto-generated client for Fathom Analytics API vv1
# Source: https://usefathom.com/api/openapi.json
# Auth: --token flag or $env.FATHOM_ANALYTICS_API_TOKEN

const BASE_URL = "https://api.usefathom.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FATHOM_ANALYTICS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.usefathom.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sharing-completer [] { ["none" "private" "public"] }
def entity-completer [] { ["event" "pageview"] }
def date-grouping-completer [] { ["day" "hour" "month" "none" "year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Get account info
#
# GET /account
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, object: string, name: string, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sites
#
# GET /sites
export def "sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned, between 1 and 100. (default: 10)
  --starting-after: string # A cursor for pagination/navigation. starting_after is an object ID. For example, if you requested 10 site objects, and the last item in the list was ABCDEF, you would send your next request with starting_after=ABCDEF.
  --ending-before: string # A cursor for pagination/navigation. ending_before is an object ID. For example, if you requested 10 site objects, and the first item in the list was ABCDEF, you would send your next request with ending_before=ABCDEF.
]: nothing -> record<object: string, url: string, has_more: bool, data: table<id: string, object: string, name: string, sharing: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new site
#
# POST /sites
export def "sites post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the website. Any string (up to 255 characters) is acceptable, and it doesn't have to match the website URL
  --sharing: string@sharing-completer # The sharing configuration. Supported values are: none, private or public.
  --share-password: string # When sharing is set to private, you must also send a password to access the site with.
]: any -> record<id: string, object: string, name: string, sharing: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sites")
  let body = {name: $name, sharing: $sharing, share_password: $share_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a site
#
# GET /sites/{site_id}
export def "sites get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, sharing: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a site
#
# POST /sites/{site_id}
export def "sites post-by-site_id" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the website. Any string (up to 255 characters) is acceptable, and it doesn't have to match the website URL
  --sharing: string@sharing-completer # The sharing configuration. Supported values are: none, private or public.
  --share-password: string # When sharing is set to private, you must also send a password to access the site with.
]: any -> record<id: string, object: string, name: string, sharing: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let body = {name: $name, sharing: $sharing, share_password: $share_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a site
#
# DELETE /sites/{site_id}
export def "sites delete" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Wipe a site
#
# DELETE /sites/{site_id}/data
export def "sites-data delete" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, sharing: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List events
#
# GET /sites/{site_id}/events
export def "sites-events list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned, between 1 and 100. (default: 10)
  --starting-after: string # A cursor for pagination/navigation. starting_after is an object ID. For example, if you requested 10 site objects, and the last item in the list was ABCDEF, you would send your next request with starting_after=ABCDEF.
  --ending-before: string # A cursor for pagination/navigation. ending_before is an object ID. For example, if you requested 10 site objects, and the first item in the list was ABCDEF, you would send your next request with ending_before=ABCDEF.
]: nothing -> record<object: string, url: string, has_more: bool, data: table<id: string, object: string, name: string, site_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new event
#
# POST /sites/{site_id}/events
export def "sites-events post-by-site_id" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the event (up to 255 characters)
]: any -> record<id: string, object: string, name: string, site_id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/events")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an event
#
# GET /sites/{site_id}/events/{event_id}
export def "sites-events get" [
  site_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, site_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an event
#
# POST /sites/{site_id}/events/{event_id}
export def "sites-events post-by-site_id-event_id" [
  site_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the event (up to 255 characters)
]: any -> record<id: string, object: string, name: string, site_id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/events/($event_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an event
#
# DELETE /sites/{site_id}/events/{event_id}
export def "sites-events delete" [
  site_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, site_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List milestones
#
# GET /sites/{site_id}/milestones
export def "sites-milestones list" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned, between 1 and 100. (default: 10)
  --starting-after: string # A cursor for pagination/navigation. starting_after is an object ID. For example, if you requested 10 site objects, and the last item in the list was ABCDEF, you would send your next request with starting_after=ABCDEF.
  --ending-before: string # A cursor for pagination/navigation. ending_before is an object ID. For example, if you requested 10 site objects, and the first item in the list was ABCDEF, you would send your next request with ending_before=ABCDEF.
]: nothing -> record<object: string, url: string, has_more: bool, data: table<id: string, object: string, name: string, milestone_date: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($site_id)/milestones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new milestone
#
# POST /sites/{site_id}/milestones
export def "sites-milestones post-by-site_id" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the milestone.
  milestone_date: string # The date of the milestone in format `YYYY-MM-DD` (UTC timezone). The date must be before today's date. (e.g. 2025-04-06)
]: any -> record<id: string, object: string, name: string, milestone_date: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/milestones")
  let body = {name: $name, milestone_date: $milestone_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a milestone
#
# GET /sites/{site_id}/milestones/{milestone_id}
export def "sites-milestones get" [
  site_id: string
  milestone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, milestone_date: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/milestones/($milestone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a milestone
#
# POST /sites/{site_id}/milestones/{milestone_id}
export def "sites-milestones post-by-site_id-milestone_id" [
  site_id: string
  milestone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the milestone.
  --milestone-date: string # The date of the milestone in format `YYYY-MM-DD` (no timezone). The date must be before today's date. (e.g. 2025-04-06)
]: any -> record<id: string, object: string, name: string, milestone_date: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/milestones/($milestone_id)")
  let body = {name: $name, milestone_date: $milestone_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a milestone
#
# DELETE /sites/{site_id}/milestones/{milestone_id}
export def "sites-milestones delete" [
  site_id: string
  milestone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/milestones/($milestone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Wipe an event
#
# DELETE /sites/{site_id}/events/{event_id}/data
export def "sites-events-data delete" [
  site_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, site_id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sites/($site_id)/events/($event_id)/data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analytics aggregation
#
# GET /aggregations
export def "aggregations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity: string@entity-completer # The entity you want to report on. Events are treated separately from pageviews. Supported values: pageview and event.
  --entity-id: string # Required when entity is "pageview". The ID of the site that you want to aggregate pageviews on. Do not include this parameter when entity is set to "event".  Deprecation note: For backward compatibility, we still support goal IDs in this field but we don't recommend using this field for that anymore. Use site_id and entity_name parameters instead.
  --site-id: string # Required when entity is "event". The ID of the site the event belongs to.
  --entity-name: string # Required when entity is "event". The name of the event you want to report on. Example: purchase.
  --aggregates: string # The SUM aggregates you wish to include, separated by a comma.  Supported values for pageview entities: visits, uniques, pageviews, avg_duration and bounce_rate. The difference between "visitors" and "uniques" is that visitors are unique site visits whilst uniques are unique page visits. So a single user can only have one "visit" to your site, but they can view 10 unique pages.  Supported values for event entities: conversions, unique_conversions and value. Note: Value will be returned in cents.
  --date-grouping: string@date-grouping-completer # By default, we don't do any kind of date grouping, and we offer "total" aggregations. You can override this but you still have limits such as: When grouping daily, you cannot aggregate over 6 months of data. (default: none)
  --field-grouping: string # The fields you want to group by. Supported values are hostname, pathname, referrer_hostname, referrer_pathname, referrer_source, browser, country_code, city, region, device_type, operating_system, utm_campaign, utm_content, utm_medium, utm_source, utm_term, keyword, q, ref and s.  You can group by multiple fields using a comma hostname,pathname.
  --sort-by: string # The field you want to sort by. Format is: field:asc|desc. You can use any field that you've asked for in the aggregations and field_grouping options. If using date_grouping, you can also use timestamp:asc or timestamp:desc here, which allows you to sort by date. (e.g. pageviews:desc)
  --timezone: string # The timezone you want us to use in our queries. We store all data in UTC, and use that by default, but can support any timezone. The timezone you send should be a TZ database name. (default: UTC)
  --date-from: string # Timestamp (e.g. 2022-04-01 15:31:00). This should match the timezone you specified. (format: date)
  --date-to: string # Timestamp (e.g. 2022-04-01 15:31:00). This should match the timezone you specified. (format: date, default: now)
  --limit: int # A limit on the number of entries to return. For example, if your site had 10,000 unique pathnames, and you had "pathname" in field_grouping, you might get 10,000 rows back by default. You should limit this to prevent timeouts. We have no limits right now but we'll be introducing pagination for this endpoint in the future, and setting a maximum amount of rows that can be returned.
  --starting-after: string
  --filters: record # JSON payload. An array of objects. You can add as many filters as you like.  The filtering is hyper flexible and is best illustrated via some JSON payload examples to the right (or below if you're on a mobile).  We support the following operators: is, is not, is like, is not like, matching (regex), and not matching (regex).
]: nothing -> record<object: string, url: string, has_more: bool, data: table<browser: string, device_type: string, pageviews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "entity_name" $entity_name "scalar") (serialize-qp "aggregates" $aggregates "scalar") (serialize-qp "date_grouping" $date_grouping "scalar") (serialize-qp "field_grouping" $field_grouping "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Current visitors
#
# GET /current_visitors
export def "current-visitors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --site-id: string # The ID of the site.
  --detailed: oneof<nothing, bool> # Set this parameter if you want a detailed breakdown. Otherwise you'll only get a count. (default: false)
]: nothing -> record<total: int, content: table<pathname: string, hostname: string, total: int>, referrers: table<referrer_hostname: string, referrer_pathname: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "site_id" $site_id "scalar") (serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/current_visitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
