# Auto-generated client for Basecamp v2026-03-23
# Source: https://raw.githubusercontent.com/basecamp/basecamp-sdk/main/openapi.json
# Auth: --token flag or $env.BASECAMP_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BASECAMP_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def first-week-day-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accountjson GetAccount" } } | get name | first)
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

# Get the account for the current access token
#
# GET /{accountId}/account.json
# operationId: GetAccount
export def "accountjson GetAccount" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, owner_name: string, active: bool, created_at: string, updated_at: string, trial: bool, trial_ends_on: string, frozen: bool, paused: bool, limits: record<can_create_projects: bool, can_pin_projects: bool, can_create_users: bool, can_upload_files: bool>, subscription: record<short_name: string, proper_name: string, project_limit: int, teams: bool, clients: bool, templates: bool, logo: bool, timesheet: bool>, settings: record<company_hq_enabled: bool, teams_enabled: bool, projects_enabled: bool>, logo: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/account.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove the account logo. Only administrators and account owners can use this endpoint.
#
# DELETE /{accountId}/account/logo.json
# operationId: RemoveAccountLogo
export def "account-logojson RemoveAccountLogo" [
  accountId: string
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
  let full_url = (build-url $base $"/($accountId)/account/logo.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload or replace the account logo. Accepted formats: PNG, JPEG, GIF, WebP, AVIF, HEIC. Maximum 5 MB. Owners and admins only.
#
# PUT /{accountId}/account/logo.json
# operationId: UpdateAccountLogo
export def "account-logojson UpdateAccountLogo" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  logo: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/account/logo.json")
  let body = {logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Rename the current account. Only account owners can use this endpoint.
#
# PUT /{accountId}/account/name.json
# operationId: UpdateAccountName
export def "account-namejson UpdateAccountName" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<id: int, name: string, owner_name: string, active: bool, created_at: string, updated_at: string, trial: bool, trial_ends_on: string, frozen: bool, paused: bool, limits: record<can_create_projects: bool, can_pin_projects: bool, can_create_users: bool, can_upload_files: bool>, subscription: record<short_name: string, proper_name: string, project_limit: int, teams: bool, clients: bool, templates: bool, logo: bool, timesheet: bool>, settings: record<company_hq_enabled: bool, teams_enabled: bool, projects_enabled: bool>, logo: record<url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/account/name.json")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an attachment (upload a file for embedding)
#
# POST /{accountId}/attachments.json
# operationId: CreateAttachment
export def "attachmentsjson CreateAttachment" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --body: record
]: any -> record<attachable_sgid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/attachments.json" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Delete a boost
#
# DELETE /{accountId}/boosts/{boostId}
# operationId: DeleteBoost
export def "boosts DeleteBoost" [
  accountId: string
  boostId: int
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
  let full_url = (build-url $base $"/($accountId)/boosts/($boostId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single boost
#
# GET /{accountId}/boosts/{boostId}
# operationId: GetBoost
export def "boosts GetBoost" [
  accountId: string
  boostId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, content: string, created_at: string, booster: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, recording: record<id: int, title: string, type: string, url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/boosts/($boostId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the color of a column
#
# PUT /{accountId}/buckets/{bucketId}/card_tables/columns/{columnId}/color.json
# operationId: SetCardColumnColor
export def "buckets-card-tables-columns-colorjson SetCardColumnColor" [
  accountId: string
  bucketId: int
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  color: string # Valid colors: white, red, orange, yellow, green, blue, aqua, purple, gray, pink, brown
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, on_hold: record<id: int, status: string, inherits_status: bool, title: string, created_at: string, updated_at: string, cards_count: int, cards_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/buckets/($bucketId)/card_tables/columns/($columnId)/color.json")
  let body = {color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable on-hold section in a column
#
# DELETE /{accountId}/buckets/{bucketId}/card_tables/columns/{columnId}/on_hold.json
# operationId: DisableCardColumnOnHold
export def "buckets-card-tables-columns-on-holdjson DisableCardColumnOnHold" [
  accountId: string
  bucketId: int
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, on_hold: record<id: int, status: string, inherits_status: bool, title: string, created_at: string, updated_at: string, cards_count: int, cards_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/buckets/($bucketId)/card_tables/columns/($columnId)/on_hold.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable on-hold section in a column
#
# POST /{accountId}/buckets/{bucketId}/card_tables/columns/{columnId}/on_hold.json
# operationId: EnableCardColumnOnHold
export def "buckets-card-tables-columns-on-holdjson EnableCardColumnOnHold" [
  accountId: string
  bucketId: int
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, on_hold: record<id: int, status: string, inherits_status: bool, title: string, created_at: string, updated_at: string, cards_count: int, cards_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/buckets/($bucketId)/card_tables/columns/($columnId)/on_hold.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all webhooks for a project  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/buckets/{bucketId}/webhooks.json
# operationId: ListWebhooks
export def "buckets-webhooksjson ListWebhooks" [
  accountId: string
  bucketId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, active: bool, created_at: string, updated_at: string, payload_url: string, types: list<string>, url: string, app_url: string, recent_deliveries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/buckets/($bucketId)/webhooks.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new webhook for a project
#
# POST /{accountId}/buckets/{bucketId}/webhooks.json
# operationId: CreateWebhook
export def "buckets-webhooksjson CreateWebhook" [
  accountId: string
  bucketId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payload_url: string
  types: list
  --active: string@bool-completer
]: any -> record<id: int, active: bool, created_at: string, updated_at: string, payload_url: string, types: list<string>, url: string, app_url: string, recent_deliveries: table<id: int, created_at: string, request: record, response: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/buckets/($bucketId)/webhooks.json")
  let body = {payload_url: $payload_url, types: $types, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a card by ID
#
# GET /{accountId}/card_tables/cards/{cardId}
# operationId: GetCard
export def "card-tables-cards GetCard" [
  accountId: string
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, position: int, content: string, description: string, due_on: string, completed: bool, completed_at: string, comments_count: int, comments_url: string, completion_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, steps: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record, bucket: record, creator: record, completer: record, assignees: list, completion_url: string>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/cards/($cardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing card
#
# PUT /{accountId}/card_tables/cards/{cardId}
# operationId: UpdateCard
export def "card-tables-cards UpdateCard" [
  accountId: string
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --content: string
  --due-on: string
  --assignee-ids: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, position: int, content: string, description: string, due_on: string, completed: bool, completed_at: string, comments_count: int, comments_url: string, completion_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, steps: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record, bucket: record, creator: record, completer: record, assignees: list, completion_url: string>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/cards/($cardId)")
  let body = {title: $title, content: $content, due_on: $due_on, assignee_ids: $assignee_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move a card to a different column
#
# POST /{accountId}/card_tables/cards/{cardId}/moves.json
# operationId: MoveCard
export def "card-tables-cards-movesjson MoveCard" [
  accountId: string
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  column_id: int # format: int64
  --position: int # 1-indexed position within the destination column. Defaults to 1 (top). (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/cards/($cardId)/moves.json")
  let body = {column_id: $column_id, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reposition a step within a card
#
# POST /{accountId}/card_tables/cards/{cardId}/positions.json
# operationId: RepositionCardStep
export def "card-tables-cards-positionsjson RepositionCardStep" [
  accountId: string
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_id: int # format: int64
  position: int # 0-indexed position (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/cards/($cardId)/positions.json")
  let body = {source_id: $source_id, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a step on a card
#
# POST /{accountId}/card_tables/cards/{cardId}/steps.json
# operationId: CreateCardStep
export def "card-tables-cards-stepsjson CreateCardStep" [
  accountId: string
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  --due-on: string
  --assignee-ids: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/cards/($cardId)/steps.json")
  let body = {title: $title, due_on: $due_on, assignee_ids: $assignee_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a card column by ID
#
# GET /{accountId}/card_tables/columns/{columnId}
# operationId: GetCardColumn
export def "card-tables-columns GetCardColumn" [
  accountId: string
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, on_hold: record<id: int, status: string, inherits_status: bool, title: string, created_at: string, updated_at: string, cards_count: int, cards_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/columns/($columnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing column
#
# PUT /{accountId}/card_tables/columns/{columnId}
# operationId: UpdateCardColumn
export def "card-tables-columns UpdateCardColumn" [
  accountId: string
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --description: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, on_hold: record<id: int, status: string, inherits_status: bool, title: string, created_at: string, updated_at: string, cards_count: int, cards_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/columns/($columnId)")
  let body = {title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List cards in a column  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/card_tables/lists/{columnId}/cards.json
# operationId: ListCards
export def "card-tables-lists-cardsjson ListCards" [
  accountId: string
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, position: int, content: string, description: string, due_on: string, completed: bool, completed_at: string, comments_count: int, comments_url: string, completion_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: list<record>, completion_subscribers: list<record>, steps: list<record>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/lists/($columnId)/cards.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a card in a column
#
# POST /{accountId}/card_tables/lists/{columnId}/cards.json
# operationId: CreateCard
export def "card-tables-lists-cardsjson CreateCard" [
  accountId: string
  columnId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  --content: string
  --due-on: string
  --notify: string@bool-completer
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, position: int, content: string, description: string, due_on: string, completed: bool, completed_at: string, comments_count: int, comments_url: string, completion_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, steps: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record, bucket: record, creator: record, completer: record, assignees: list, completion_url: string>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/lists/($columnId)/cards.json")
  let body = {title: $title, content: $content, due_on: $due_on, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsubscribe from a card column (stop watching for changes)
#
# DELETE /{accountId}/card_tables/lists/{columnId}/subscription.json
# operationId: UnsubscribeFromCardColumn
export def "card-tables-lists-subscriptionjson UnsubscribeFromCardColumn" [
  accountId: string
  columnId: int
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
  let full_url = (build-url $base $"/($accountId)/card_tables/lists/($columnId)/subscription.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe to a card column (watch for changes)
#
# POST /{accountId}/card_tables/lists/{columnId}/subscription.json
# operationId: SubscribeToCardColumn
export def "card-tables-lists-subscriptionjson SubscribeToCardColumn" [
  accountId: string
  columnId: int
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
  let full_url = (build-url $base $"/($accountId)/card_tables/lists/($columnId)/subscription.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a step by ID
#
# GET /{accountId}/card_tables/steps/{stepId}
# operationId: GetCardStep
export def "card-tables-steps GetCardStep" [
  accountId: string
  stepId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/steps/($stepId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing step
#
# PUT /{accountId}/card_tables/steps/{stepId}
# operationId: UpdateCardStep
export def "card-tables-steps UpdateCardStep" [
  accountId: string
  stepId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --due-on: string
  --assignee-ids: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/steps/($stepId)")
  let body = {title: $title, due_on: $due_on, assignee_ids: $assignee_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set card step completion status (PUT with completion: "on" to complete, "" to uncomplete)
#
# PUT /{accountId}/card_tables/steps/{stepId}/completions.json
# operationId: SetCardStepCompletion
export def "card-tables-steps-completionsjson SetCardStepCompletion" [
  accountId: string
  stepId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  completion: string # Set to "on" to complete the step, "" (empty) to uncomplete
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, due_on: string, completed: bool, completed_at: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completer: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/steps/($stepId)/completions.json")
  let body = {completion: $completion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a card table by ID
#
# GET /{accountId}/card_tables/{cardTableId}
# operationId: GetCardTable
export def "card-tables GetCardTable" [
  accountId: string
  cardTableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, lists: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record, bucket: record, creator: record, subscribers: list, on_hold: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/($cardTableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a column in a card table
#
# POST /{accountId}/card_tables/{cardTableId}/columns.json
# operationId: CreateCardColumn
export def "card-tables-columnsjson CreateCardColumn" [
  accountId: string
  cardTableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  --description: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, color: string, description: string, cards_count: int, comments_count: int, cards_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, on_hold: record<id: int, status: string, inherits_status: bool, title: string, created_at: string, updated_at: string, cards_count: int, cards_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/($cardTableId)/columns.json")
  let body = {title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move a column within a card table
#
# POST /{accountId}/card_tables/{cardTableId}/moves.json
# operationId: MoveCardColumn
export def "card-tables-movesjson MoveCardColumn" [
  accountId: string
  cardTableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_id: int # format: int64
  target_id: int # format: int64
  --position: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/card_tables/($cardTableId)/moves.json")
  let body = {source_id: $source_id, target_id: $target_id, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List message types in a project  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/categories.json
# operationId: ListMessageTypes
export def "categoriesjson ListMessageTypes" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, icon: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/categories.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new message type in a project
#
# POST /{accountId}/categories.json
# operationId: CreateMessageType
export def "categoriesjson CreateMessageType" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  icon: string
]: any -> record<id: int, name: string, icon: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/categories.json")
  let body = {name: $name, icon: $icon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a message type
#
# DELETE /{accountId}/categories/{typeId}
# operationId: DeleteMessageType
export def "categories DeleteMessageType" [
  accountId: string
  typeId: int
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
  let full_url = (build-url $base $"/($accountId)/categories/($typeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single message type by id
#
# GET /{accountId}/categories/{typeId}
# operationId: GetMessageType
export def "categories GetMessageType" [
  accountId: string
  typeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, icon: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/categories/($typeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing message type
#
# PUT /{accountId}/categories/{typeId}
# operationId: UpdateMessageType
export def "categories UpdateMessageType" [
  accountId: string
  typeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --icon: string
]: any -> record<id: int, name: string, icon: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/categories/($typeId)")
  let body = {name: $name, icon: $icon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all campfires across the account  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/chats.json
# operationId: ListCampfires
export def "chatsjson ListCampfires" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, topic: string, lines_url: string, files_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a campfire by ID
#
# GET /{accountId}/chats/{campfireId}
# operationId: GetCampfire
export def "chats GetCampfire" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, topic: string, lines_url: string, files_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all chatbots for a campfire  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/chats/{campfireId}/integrations.json
# operationId: ListChatbots
export def "chats-integrationsjson ListChatbots" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, created_at: string, updated_at: string, service_name: string, command_url: string, url: string, app_url: string, lines_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/integrations.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new chatbot for a campfire
#
# POST /{accountId}/chats/{campfireId}/integrations.json
# operationId: CreateChatbot
export def "chats-integrationsjson CreateChatbot" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  service_name: string
  --command-url: string
]: any -> record<id: int, created_at: string, updated_at: string, service_name: string, command_url: string, url: string, app_url: string, lines_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/integrations.json")
  let body = {service_name: $service_name, command_url: $command_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a chatbot
#
# DELETE /{accountId}/chats/{campfireId}/integrations/{chatbotId}
# operationId: DeleteChatbot
export def "chats-integrations DeleteChatbot" [
  accountId: string
  campfireId: int
  chatbotId: int
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
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/integrations/($chatbotId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a chatbot by ID
#
# GET /{accountId}/chats/{campfireId}/integrations/{chatbotId}
# operationId: GetChatbot
export def "chats-integrations GetChatbot" [
  accountId: string
  campfireId: int
  chatbotId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, created_at: string, updated_at: string, service_name: string, command_url: string, url: string, app_url: string, lines_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/integrations/($chatbotId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing chatbot
#
# PUT /{accountId}/chats/{campfireId}/integrations/{chatbotId}
# operationId: UpdateChatbot
export def "chats-integrations UpdateChatbot" [
  accountId: string
  campfireId: int
  chatbotId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  service_name: string
  --command-url: string
]: any -> record<id: int, created_at: string, updated_at: string, service_name: string, command_url: string, url: string, app_url: string, lines_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/integrations/($chatbotId)")
  let body = {service_name: $service_name, command_url: $command_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all lines (messages) in a campfire  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/chats/{campfireId}/lines.json
# operationId: ListCampfireLines
export def "chats-linesjson ListCampfireLines" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, attachments: list<record>, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/lines.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new line (message) in a campfire
#
# POST /{accountId}/chats/{campfireId}/lines.json
# operationId: CreateCampfireLine
export def "chats-linesjson CreateCampfireLine" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
  --content-type: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, attachments: table<title: string, url: string, filename: string, content_type: string, byte_size: int, download_url: string>, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/lines.json")
  let body = {content: $content, content_type: $content_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a campfire line
#
# DELETE /{accountId}/chats/{campfireId}/lines/{lineId}
# operationId: DeleteCampfireLine
export def "chats-lines DeleteCampfireLine" [
  accountId: string
  campfireId: int
  lineId: int
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
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/lines/($lineId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a campfire line by ID
#
# GET /{accountId}/chats/{campfireId}/lines/{lineId}
# operationId: GetCampfireLine
export def "chats-lines GetCampfireLine" [
  accountId: string
  campfireId: int
  lineId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, attachments: table<title: string, url: string, filename: string, content_type: string, byte_size: int, download_url: string>, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/lines/($lineId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List uploaded files in a campfire  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/chats/{campfireId}/uploads.json
# operationId: ListCampfireUploads
export def "chats-uploadsjson ListCampfireUploads" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, attachments: list<record>, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/uploads.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file to a campfire
#
# POST /{accountId}/chats/{campfireId}/uploads.json
# operationId: CreateCampfireUpload
export def "chats-uploadsjson CreateCampfireUpload" [
  accountId: string
  campfireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Filename for the uploaded file (e.g. "report.pdf").
  --body: record
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, attachments: table<title: string, url: string, filename: string, content_type: string, byte_size: int, download_url: string>, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/chats/($campfireId)/uploads.json" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# List all account users who can be pinged  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/circles/people.json
# operationId: ListPingablePeople
export def "circles-peoplejson ListPingablePeople" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/circles/people.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all client approvals in a project  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/client/approvals.json
# operationId: ListClientApprovals
export def "client-approvalsjson ListClientApprovals" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, subject: string, due_on: string, replies_count: int, replies_url: string, approval_status: string, approver: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, responses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/client/approvals.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single client approval by id
#
# GET /{accountId}/client/approvals/{approvalId}
# operationId: GetClientApproval
export def "client-approvals GetClientApproval" [
  accountId: string
  approvalId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, subject: string, due_on: string, replies_count: int, replies_url: string, approval_status: string, approver: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, responses: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, app_url: string, bookmark_url: string, parent: record, bucket: record, creator: record, content: string, approved: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/client/approvals/($approvalId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all client correspondences in a project  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/client/correspondences.json
# operationId: ListClientCorrespondences
export def "client-correspondencesjson ListClientCorrespondences" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, subject: string, replies_count: int, replies_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/client/correspondences.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single client correspondence by id
#
# GET /{accountId}/client/correspondences/{correspondenceId}
# operationId: GetClientCorrespondence
export def "client-correspondences GetClientCorrespondence" [
  accountId: string
  correspondenceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, subject: string, replies_count: int, replies_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/client/correspondences/($correspondenceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all client replies for a recording (correspondence or approval)  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/client/recordings/{recordingId}/replies.json
# operationId: ListClientReplies
export def "client-recordings-repliesjson ListClientReplies" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/client/recordings/($recordingId)/replies.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single client reply by id
#
# GET /{accountId}/client/recordings/{recordingId}/replies/{replyId}
# operationId: GetClientReply
export def "client-recordings-replies GetClientReply" [
  accountId: string
  recordingId: int
  replyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/client/recordings/($recordingId)/replies/($replyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single comment by id
#
# GET /{accountId}/comments/{commentId}
# operationId: GetComment
export def "comments GetComment" [
  accountId: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing comment
#
# PUT /{accountId}/comments/{commentId}
# operationId: UpdateComment
export def "comments UpdateComment" [
  accountId: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/comments/($commentId)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone an existing tool to create a new one
#
# POST /{accountId}/dock/tools.json
# operationId: CloneTool
export def "dock-toolsjson CloneTool" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_recording_id: int # format: int64
  --title: string
]: any -> record<id: int, status: string, created_at: string, updated_at: string, title: string, name: string, enabled: bool, position: int, url: string, app_url: string, bucket: record<id: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/dock/tools.json")
  let body = {source_recording_id: $source_recording_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tool (trash it)
#
# DELETE /{accountId}/dock/tools/{toolId}
# operationId: DeleteTool
export def "dock-tools DeleteTool" [
  accountId: string
  toolId: int
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
  let full_url = (build-url $base $"/($accountId)/dock/tools/($toolId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a dock tool by id
#
# GET /{accountId}/dock/tools/{toolId}
# operationId: GetTool
export def "dock-tools GetTool" [
  accountId: string
  toolId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, created_at: string, updated_at: string, title: string, name: string, enabled: bool, position: int, url: string, app_url: string, bucket: record<id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/dock/tools/($toolId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update (rename) an existing tool
#
# PUT /{accountId}/dock/tools/{toolId}
# operationId: UpdateTool
export def "dock-tools UpdateTool" [
  accountId: string
  toolId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
]: any -> record<id: int, status: string, created_at: string, updated_at: string, title: string, name: string, enabled: bool, position: int, url: string, app_url: string, bucket: record<id: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/dock/tools/($toolId)")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single document by id
#
# GET /{accountId}/documents/{documentId}
# operationId: GetDocument
export def "documents GetDocument" [
  accountId: string
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing document
#
# PUT /{accountId}/documents/{documentId}
# operationId: UpdateDocument
export def "documents UpdateDocument" [
  accountId: string
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --content: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/documents/($documentId)")
  let body = {title: $title, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Destroy a gauge needle
#
# DELETE /{accountId}/gauge_needles/{needleId}
# operationId: DestroyGaugeNeedle
export def "gauge-needles DestroyGaugeNeedle" [
  accountId: string
  needleId: int
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
  let full_url = (build-url $base $"/($accountId)/gauge_needles/($needleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a gauge needle by ID
#
# GET /{accountId}/gauge_needles/{needleId}
# operationId: GetGaugeNeedle
export def "gauge-needles GetGaugeNeedle" [
  accountId: string
  needleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, boosts_count: int, boosts_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, color: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/gauge_needles/($needleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a gauge needle's description. Position and color are immutable.
#
# PUT /{accountId}/gauge_needles/{needleId}
# operationId: UpdateGaugeNeedle
# --gauge_needle shape: {description?: string}
export def "gauge-needles UpdateGaugeNeedle" [
  accountId: string
  needleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gauge-needle: record # shape: {description?: string}
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, boosts_count: int, boosts_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, color: string, position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/gauge_needles/($needleId)")
  let body = {gauge_needle: $gauge_needle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a forward by ID
#
# GET /{accountId}/inbox_forwards/{forwardId}
# operationId: GetForward
export def "inbox-forwards GetForward" [
  accountId: string
  forwardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, subject: string, from: string, replies_count: int, replies_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/inbox_forwards/($forwardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all replies to a forward  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/inbox_forwards/{forwardId}/replies.json
# operationId: ListForwardReplies
export def "inbox-forwards-repliesjson ListForwardReplies" [
  accountId: string
  forwardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/inbox_forwards/($forwardId)/replies.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a reply to a forward
#
# POST /{accountId}/inbox_forwards/{forwardId}/replies.json
# operationId: CreateForwardReply
export def "inbox-forwards-repliesjson CreateForwardReply" [
  accountId: string
  forwardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/inbox_forwards/($forwardId)/replies.json")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a forward reply by ID
#
# GET /{accountId}/inbox_forwards/{forwardId}/replies/{replyId}
# operationId: GetForwardReply
export def "inbox-forwards-replies GetForwardReply" [
  accountId: string
  forwardId: int
  replyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/inbox_forwards/($forwardId)/replies/($replyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an inbox by ID
#
# GET /{accountId}/inboxes/{inboxId}
# operationId: GetInbox
export def "inboxes GetInbox" [
  accountId: string
  inboxId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, forwards_count: int, forwards_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/inboxes/($inboxId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all forwards in an inbox  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/inboxes/{inboxId}/forwards.json
# operationId: ListForwards
export def "inboxes-forwardsjson ListForwards" [
  accountId: string
  inboxId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, subject: string, from: string, replies_count: int, replies_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/inboxes/($inboxId)/forwards.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all lineup markers for the account
#
# GET /{accountId}/lineup/markers.json
# operationId: ListLineupMarkers
export def "lineup-markersjson ListLineupMarkers" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, date: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/lineup/markers.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new lineup marker
#
# POST /{accountId}/lineup/markers.json
# operationId: CreateLineupMarker
export def "lineup-markersjson CreateLineupMarker" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  date: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/lineup/markers.json")
  let body = {name: $name, date: $date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a lineup marker
#
# DELETE /{accountId}/lineup/markers/{markerId}
# operationId: DeleteLineupMarker
export def "lineup-markers DeleteLineupMarker" [
  accountId: string
  markerId: int
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
  let full_url = (build-url $base $"/($accountId)/lineup/markers/($markerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing lineup marker
#
# PUT /{accountId}/lineup/markers/{markerId}
# operationId: UpdateLineupMarker
export def "lineup-markers UpdateLineupMarker" [
  accountId: string
  markerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --date: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/lineup/markers/($markerId)")
  let body = {name: $name, date: $date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a message board
#
# GET /{accountId}/message_boards/{boardId}
# operationId: GetMessageBoard
export def "message-boards GetMessageBoard" [
  accountId: string
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, messages_count: int, messages_url: string, app_messages_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/message_boards/($boardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List messages on a message board  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/message_boards/{boardId}/messages.json
# operationId: ListMessages
export def "message-boards-messagesjson ListMessages" [
  accountId: string
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subject: string, content: string, category: record<id: int, name: string, icon: string, created_at: string, updated_at: string>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/message_boards/($boardId)/messages.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new message on a message board
#
# POST /{accountId}/message_boards/{boardId}/messages.json
# operationId: CreateMessage
export def "message-boards-messagesjson CreateMessage" [
  accountId: string
  boardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subject: string
  --content: string
  --status: string # active|drafted
  --category-id: int # format: int64
  --subscriptions: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subject: string, content: string, category: record<id: int, name: string, icon: string, created_at: string, updated_at: string>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/message_boards/($boardId)/messages.json")
  let body = {subject: $subject, content: $content, status: $status, category_id: $category_id, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single message by id
#
# GET /{accountId}/messages/{messageId}
# operationId: GetMessage
export def "messages GetMessage" [
  accountId: string
  messageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subject: string, content: string, category: record<id: int, name: string, icon: string, created_at: string, updated_at: string>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/messages/($messageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing message
#
# PUT /{accountId}/messages/{messageId}
# operationId: UpdateMessage
export def "messages UpdateMessage" [
  accountId: string
  messageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subject: string
  --content: string
  --status: string # active|drafted
  --category-id: int # format: int64
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, subject: string, content: string, category: record<id: int, name: string, icon: string, created_at: string, updated_at: string>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/messages/($messageId)")
  let body = {subject: $subject, content: $content, status: $status, category_id: $category_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the current user's active assignments grouped into priorities and non_priorities. Card table steps are normalized to their parent card with steps as children. This endpoint is not paginated.
#
# GET /{accountId}/my/assignments.json
# operationId: GetMyAssignments
export def "my-assignmentsjson GetMyAssignments" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<priorities: table<id: int, app_url: string, content: string, starts_on: string, due_on: string, bucket: record, completed: bool, type: string, assignees: list, comments_count: int, has_description: bool, priority_recording_id: int, parent: record, children: list>, non_priorities: table<id: int, app_url: string, content: string, starts_on: string, due_on: string, bucket: record, completed: bool, type: string, assignees: list, comments_count: int, has_description: bool, priority_recording_id: int, parent: record, children: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/assignments.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current user's completed assignments. Archived and trashed recordings are excluded. This endpoint is not paginated.
#
# GET /{accountId}/my/assignments/completed.json
# operationId: GetMyCompletedAssignments
export def "my-assignments-completedjson GetMyCompletedAssignments" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, app_url: string, content: string, starts_on: string, due_on: string, bucket: record<id: int, name: string, app_url: string>, completed: bool, type: string, assignees: list<record>, comments_count: int, has_description: bool, priority_recording_id: int, parent: record<id: int, title: string, app_url: string>, children: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/assignments/completed.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current user's assignments filtered by due date scope. Defaults to overdue when no scope is provided. This endpoint is not paginated.
#
# GET /{accountId}/my/assignments/due.json
# operationId: GetMyDueAssignments
export def "my-assignments-duejson GetMyDueAssignments" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # Filter by due date range: overdue, due_today, due_tomorrow, due_later_this_week, due_next_week, due_later
]: nothing -> table<id: int, app_url: string, content: string, starts_on: string, due_on: string, bucket: record<id: int, name: string, app_url: string>, completed: bool, type: string, assignees: list<record>, comments_count: int, has_description: bool, priority_recording_id: int, parent: record<id: int, title: string, app_url: string>, children: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/my/assignments/due.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current user's preferences
#
# GET /{accountId}/my/preferences.json
# operationId: GetMyPreferences
export def "my-preferencesjson GetMyPreferences" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string, app_url: string, time_zone_name: string, first_week_day: string, time_format: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/preferences.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the current user's preferences
#
# PUT /{accountId}/my/preferences.json
# operationId: UpdateMyPreferences
# --person shape: {time_zone_name?: string, first_week_day?: string, time_format?: string}
export def "my-preferencesjson UpdateMyPreferences" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  person: record # shape: {time_zone_name?: string, first_week_day?: string, time_format?: string}
]: any -> record<url: string, app_url: string, time_zone_name: string, first_week_day: string, time_format: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/preferences.json")
  let body = {person: $person} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the current authenticated user's profile
#
# GET /{accountId}/my/profile.json
# operationId: GetMyProfile
export def "my-profilejson GetMyProfile" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/profile.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the current authenticated user's profile (returns 204 No Content)
#
# PUT /{accountId}/my/profile.json
# operationId: UpdateMyProfile
export def "my-profilejson UpdateMyProfile" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # format: password
  --email-address: string # format: password
  --title: string # format: password
  --bio: string # format: password
  --location: string # format: password
  --time-zone-name: string
  --first-week-day: string@first-week-day-completer
  --time-format: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/profile.json")
  let body = {name: $name, email_address: $email_address, title: $title, bio: $bio, location: $location, time_zone_name: $time_zone_name, first_week_day: $first_week_day, time_format: $time_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pending check-in reminders for the current user  Returns questions that are pending a response from the authenticated user.  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages.
#
# GET /{accountId}/my/question_reminders.json
# operationId: GetQuestionReminders
export def "my-question-remindersjson GetQuestionReminders" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<reminder_id: int, remind_at: string, group_on: string, question: record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record, bucket: record, creator: record, paused: bool, schedule: record, answers_count: int, answers_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/question_reminders.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current user's notification inbox (the "Hey!" menu). Notifications are grouped into unreads, reads, and memories. Reads are paginated (50 per page). Unreads are capped at 100.
#
# GET /{accountId}/my/readings.json
# operationId: GetMyNotifications
export def "my-readingsjson GetMyNotifications" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for paginating through read items. Defaults to 1. (format: int32)
]: nothing -> record<unreads: table<id: int, created_at: string, updated_at: string, section: string, unread_count: int, unread_at: string, read_at: string, readable_sgid: string, readable_identifier: string, title: string, type: string, bucket_name: string, creator: record, content_excerpt: string, app_url: string, unread_url: string, bookmark_url: string, memory_url: string, subscription_url: string, subscribed: bool, previewable_attachments: list, participants: list, named: bool, image_url: string>, reads: table<id: int, created_at: string, updated_at: string, section: string, unread_count: int, unread_at: string, read_at: string, readable_sgid: string, readable_identifier: string, title: string, type: string, bucket_name: string, creator: record, content_excerpt: string, app_url: string, unread_url: string, bookmark_url: string, memory_url: string, subscription_url: string, subscribed: bool, previewable_attachments: list, participants: list, named: bool, image_url: string>, memories: table<id: int, created_at: string, updated_at: string, section: string, unread_count: int, unread_at: string, read_at: string, readable_sgid: string, readable_identifier: string, title: string, type: string, bucket_name: string, creator: record, content_excerpt: string, app_url: string, unread_url: string, bookmark_url: string, memory_url: string, subscription_url: string, subscribed: bool, previewable_attachments: list, participants: list, named: bool, image_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/my/readings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark specified items as read
#
# PUT /{accountId}/my/unreads.json
# operationId: MarkAsRead
export def "my-unreadsjson MarkAsRead" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  readables: list # Array of readable_sgid values identifying the items to mark as read
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/my/unreads.json")
  let body = {readables: $readables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all people visible to the current user  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/people.json
# operationId: ListPeople
export def "peoplejson ListPeople" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/people.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a person by ID
#
# GET /{accountId}/people/{personId}
# operationId: GetPerson
export def "people GetPerson" [
  accountId: string
  personId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/people/($personId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable out of office for a person. Admins on Pro Pack accounts can manage others; otherwise self only.
#
# DELETE /{accountId}/people/{personId}/out_of_office.json
# operationId: DisableOutOfOffice
export def "people-out-of-officejson DisableOutOfOffice" [
  accountId: string
  personId: int
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
  let full_url = (build-url $base $"/($accountId)/people/($personId)/out_of_office.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the out of office status for a person
#
# GET /{accountId}/people/{personId}/out_of_office.json
# operationId: GetOutOfOffice
export def "people-out-of-officejson GetOutOfOffice" [
  accountId: string
  personId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<person: record<id: int, name: string>, enabled: bool, ongoing: bool, start_date: string, end_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/people/($personId)/out_of_office.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable or replace out of office for a person. Admins on Pro Pack accounts can manage others; otherwise self only.
#
# POST /{accountId}/people/{personId}/out_of_office.json
# operationId: EnableOutOfOffice
# --out_of_office shape: {start_date: string, end_date: string}
export def "people-out-of-officejson EnableOutOfOffice" [
  accountId: string
  personId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  out_of_office: record # shape: {start_date: string, end_date: string}
]: any -> record<person: record<id: int, name: string>, enabled: bool, ongoing: bool, start_date: string, end_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/people/($personId)/out_of_office.json")
  let body = {out_of_office: $out_of_office} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List projects (active by default; optionally archived/trashed)  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/projects.json
# operationId: ListProjects
export def "projectsjson ListProjects" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # active|archived|trashed
]: nothing -> table<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, purpose: string, clients_enabled: bool, bookmark_url: string, url: string, app_url: string, dock: list<record>, bookmarked: bool, client_company: record<id: int, name: string>, clientside: record<url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/projects.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project
#
# POST /{accountId}/projects.json
# operationId: CreateProject
export def "projectsjson CreateProject" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, purpose: string, clients_enabled: bool, bookmark_url: string, url: string, app_url: string, dock: table<id: int, title: string, name: string, enabled: bool, position: int, url: string, app_url: string>, bookmarked: bool, client_company: record<id: int, name: string>, clientside: record<url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects.json")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List recordings of a given type across projects  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/projects/recordings.json
# operationId: ListRecordings
export def "projects-recordingsjson ListRecordings" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Comment|Document|Kanban::Card|Kanban::Step|Message|Question::Answer|Schedule::Entry|Todo|Todolist|Upload|Vault
  --bucket: string
  --status: string # active|archived|trashed
  --qp-sort: string # created_at|updated_at
  --direction: string # asc|desc
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, comments_count: int, comments_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/projects/recordings.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trash a project (returns 204 No Content)
#
# DELETE /{accountId}/projects/{projectId}
# operationId: TrashProject
export def "projects TrashProject" [
  accountId: string
  projectId: int
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
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single project by id
#
# GET /{accountId}/projects/{projectId}
# operationId: GetProject
export def "projects GetProject" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, purpose: string, clients_enabled: bool, bookmark_url: string, url: string, app_url: string, dock: table<id: int, title: string, name: string, enabled: bool, position: int, url: string, app_url: string>, bookmarked: bool, client_company: record<id: int, name: string>, clientside: record<url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing project
#
# PUT /{accountId}/projects/{projectId}
# operationId: UpdateProject
# --schedule_attributes shape: {start_date?: string, end_date?: string}
export def "projects UpdateProject" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --admissions: string # invite|employee|team
  --schedule-attributes: record # shape: {start_date?: string, end_date?: string}
]: any -> record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, purpose: string, clients_enabled: bool, bookmark_url: string, url: string, app_url: string, dock: table<id: int, title: string, name: string, enabled: bool, position: int, url: string, app_url: string>, bookmarked: bool, client_company: record<id: int, name: string>, clientside: record<url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)")
  let body = {name: $name, description: $description, admissions: $admissions, schedule_attributes: $schedule_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable or disable the gauge for a project. Only project admins can toggle gauges.
#
# PUT /{accountId}/projects/{projectId}/gauge.json
# operationId: ToggleGauge
# --gauge shape: {enabled: bool}
export def "projects-gaugejson ToggleGauge" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  gauge: record # shape: {enabled: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/gauge.json")
  let body = {gauge: $gauge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List gauge needles for a project, ordered newest first.
#
# GET /{accountId}/projects/{projectId}/gauge/needles.json
# operationId: ListGaugeNeedles
export def "projects-gauge-needlesjson ListGaugeNeedles" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, boosts_count: int, boosts_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, color: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/gauge/needles.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a gauge needle (progress update) for a project
#
# POST /{accountId}/projects/{projectId}/gauge/needles.json
# operationId: CreateGaugeNeedle
# --gauge_needle shape: {position: int, color?: string, description?: string}
export def "projects-gauge-needlesjson CreateGaugeNeedle" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  gauge_needle: record # shape: {position: int, color?: string, description?: string}
  --notify: string # Who to notify: "everyone", "working_on", "custom", or omit for nobody
  --subscriptions: list # Array of people IDs to notify (only used when notify is "custom")
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, boosts_count: int, boosts_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, color: string, position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/gauge/needles.json")
  let body = {gauge_needle: $gauge_needle, notify: $notify, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all active people on a project  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/projects/{projectId}/people.json
# operationId: ListProjectPeople
export def "projects-peoplejson ListProjectPeople" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/people.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project access (grant/revoke/create people)
#
# PUT /{accountId}/projects/{projectId}/people/users.json
# operationId: UpdateProjectAccess
# --create item shape: {name: string, email_address: string, title?: string, company_name?: string}
export def "projects-people-usersjson UpdateProjectAccess" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --grant: list
  --revoke: list
  --create: list # item shape: {name: string, email_address: string, title?: string, company_name?: string}
]: any -> record<granted: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, revoked: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/people/users.json")
  let body = {grant: $grant, revoke: $revoke, create: $create} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get project timeline
#
# GET /{accountId}/projects/{projectId}/timeline.json
# operationId: GetProjectTimeline
export def "projects-timelinejson GetProjectTimeline" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, created_at: string, kind: string, parent_recording_id: int, url: string, app_url: string, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, action: string, target: string, title: string, summary_excerpt: string, bucket: record<id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/timeline.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timesheet for a specific project
#
# GET /{accountId}/projects/{projectId}/timesheet.json
# operationId: GetProjectTimesheet
export def "projects-timesheetjson GetProjectTimesheet" [
  accountId: string
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string
  --qp-to: string
  --person-id: int # format: int64
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, date: string, description: string, hours: string, person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "person_id" $person_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/projects/($projectId)/timesheet.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single answer by id
#
# GET /{accountId}/question_answers/{answerId}
# operationId: GetAnswer
export def "question-answers GetAnswer" [
  accountId: string
  answerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, content: string, group_on: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/question_answers/($answerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing answer
#
# PUT /{accountId}/question_answers/{answerId}
# operationId: UpdateAnswer
export def "question-answers UpdateAnswer" [
  accountId: string
  answerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
  --group-on: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/question_answers/($answerId)")
  let body = {content: $content, group_on: $group_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a questionnaire (automatic check-ins container) by id
#
# GET /{accountId}/questionnaires/{questionnaireId}
# operationId: GetQuestionnaire
export def "questionnaires GetQuestionnaire" [
  accountId: string
  questionnaireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, questions_url: string, questions_count: int, name: string, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questionnaires/($questionnaireId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all questions in a questionnaire  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/questionnaires/{questionnaireId}/questions.json
# operationId: ListQuestions
export def "questionnaires-questionsjson ListQuestions" [
  accountId: string
  questionnaireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, paused: bool, schedule: record<frequency: string, days: list, hour: int, minute: int, week_instance: int, week_interval: int, month_interval: int, start_date: string, end_date: string>, answers_count: int, answers_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questionnaires/($questionnaireId)/questions.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new question in a questionnaire
#
# POST /{accountId}/questionnaires/{questionnaireId}/questions.json
# operationId: CreateQuestion
# --schedule shape: {frequency?: string, days?: list, hour?: int, minute?: int, week_instance?: int, week_interval?: int, month_interval?: int, start_date?: string, end_date?: string}
export def "questionnaires-questionsjson CreateQuestion" [
  accountId: string
  questionnaireId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  schedule: record # shape: {frequency?: string, days?: list, hour?: int, minute?: int, week_instance?: int, week_interval?: int, month_interval?: int, start_date?: string, end_date?: string}
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, paused: bool, schedule: record<frequency: string, days: list<int>, hour: int, minute: int, week_instance: int, week_interval: int, month_interval: int, start_date: string, end_date: string>, answers_count: int, answers_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questionnaires/($questionnaireId)/questions.json")
  let body = {title: $title, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single question by id
#
# GET /{accountId}/questions/{questionId}
# operationId: GetQuestion
export def "questions GetQuestion" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, paused: bool, schedule: record<frequency: string, days: list<int>, hour: int, minute: int, week_instance: int, week_interval: int, month_interval: int, start_date: string, end_date: string>, answers_count: int, answers_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing question
#
# PUT /{accountId}/questions/{questionId}
# operationId: UpdateQuestion
# --schedule shape: {frequency?: string, days?: list, hour?: int, minute?: int, week_instance?: int, week_interval?: int, month_interval?: int, start_date?: string, end_date?: string}
export def "questions UpdateQuestion" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --schedule: record # shape: {frequency?: string, days?: list, hour?: int, minute?: int, week_instance?: int, week_interval?: int, month_interval?: int, start_date?: string, end_date?: string}
  --paused: string@bool-completer
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, paused: bool, schedule: record<frequency: string, days: list<int>, hour: int, minute: int, week_instance: int, week_interval: int, month_interval: int, start_date: string, end_date: string>, answers_count: int, answers_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)")
  let body = {title: $title, schedule: $schedule, paused: $paused} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all answers for a question  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/questions/{questionId}/answers.json
# operationId: ListAnswers
export def "questions-answersjson ListAnswers" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, content: string, group_on: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/answers.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new answer for a question
#
# POST /{accountId}/questions/{questionId}/answers.json
# operationId: CreateAnswer
export def "questions-answersjson CreateAnswer" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
  --group-on: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, content: string, group_on: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/answers.json")
  let body = {content: $content, group_on: $group_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all people who have answered a question (answerers)  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages.
#
# GET /{accountId}/questions/{questionId}/answers/by.json
# operationId: ListQuestionAnswerers
export def "questions-answers-byjson ListQuestionAnswerers" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/answers/by.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all answers from a specific person for a question  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages.
#
# GET /{accountId}/questions/{questionId}/answers/by/{personId}
# operationId: GetAnswersByPerson
export def "questions-answers-by GetAnswersByPerson" [
  accountId: string
  questionId: int
  personId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, content: string, group_on: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/answers/by/($personId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update notification settings for a check-in question
#
# PUT /{accountId}/questions/{questionId}/notification_settings.json
# operationId: UpdateQuestionNotificationSettings
export def "questions-notification-settingsjson UpdateQuestionNotificationSettings" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notify-on-answer: string@bool-completer # Notify when someone answers
  --digest-include-unanswered: string@bool-completer # Include unanswered in digest
]: any -> record<responding: bool, subscribed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/notification_settings.json")
  let body = {notify_on_answer: $notify_on_answer, digest_include_unanswered: $digest_include_unanswered} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resume a paused check-in question (resumes sending reminders)
#
# DELETE /{accountId}/questions/{questionId}/pause.json
# operationId: ResumeQuestion
export def "questions-pausejson ResumeQuestion" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<paused: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/pause.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a check-in question (stops sending reminders)
#
# POST /{accountId}/questions/{questionId}/pause.json
# operationId: PauseQuestion
export def "questions-pausejson PauseQuestion" [
  accountId: string
  questionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<paused: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/questions/($questionId)/pause.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpin a message from the message board
#
# DELETE /{accountId}/recordings/{messageId}/pin.json
# operationId: UnpinMessage
export def "recordings-pinjson UnpinMessage" [
  accountId: string
  messageId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($messageId)/pin.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin a message to the top of the message board
#
# POST /{accountId}/recordings/{messageId}/pin.json
# operationId: PinMessage
export def "recordings-pinjson PinMessage" [
  accountId: string
  messageId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($messageId)/pin.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single recording by id
#
# GET /{accountId}/recordings/{recordingId}
# operationId: GetRecording
export def "recordings GetRecording" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, comments_count: int, comments_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List boosts on a recording
#
# GET /{accountId}/recordings/{recordingId}/boosts.json
# operationId: ListRecordingBoosts
export def "recordings-boostsjson ListRecordingBoosts" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, content: string, created_at: string, booster: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, recording: record<id: int, title: string, type: string, url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/boosts.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a boost on a recording
#
# POST /{accountId}/recordings/{recordingId}/boosts.json
# operationId: CreateRecordingBoost
export def "recordings-boostsjson CreateRecordingBoost" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
]: any -> record<id: int, content: string, created_at: string, booster: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, recording: record<id: int, title: string, type: string, url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/boosts.json")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set client visibility for a recording
#
# PUT /{accountId}/recordings/{recordingId}/client_visibility.json
# operationId: SetClientVisibility
export def "recordings-client-visibilityjson SetClientVisibility" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visible-to-clients: string@bool-completer
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, content: string, comments_count: int, comments_url: string, subscription_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/client_visibility.json")
  let body = {visible_to_clients: $visible_to_clients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List comments on a recording  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/recordings/{recordingId}/comments.json
# operationId: ListComments
export def "recordings-commentsjson ListComments" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/comments.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new comment on a recording
#
# POST /{accountId}/recordings/{recordingId}/comments.json
# operationId: CreateComment
export def "recordings-commentsjson CreateComment" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/comments.json")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all events for a recording  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/recordings/{recordingId}/events.json
# operationId: ListEvents
export def "recordings-eventsjson ListEvents" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, recording_id: int, action: string, details: record<added_person_ids: list, removed_person_ids: list, notified_recipient_ids: list>, created_at: string, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/events.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List boosts on a specific event within a recording
#
# GET /{accountId}/recordings/{recordingId}/events/{eventId}/boosts.json
# operationId: ListEventBoosts
export def "recordings-events-boostsjson ListEventBoosts" [
  accountId: string
  recordingId: int
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, content: string, created_at: string, booster: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, recording: record<id: int, title: string, type: string, url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/events/($eventId)/boosts.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a boost on a specific event within a recording
#
# POST /{accountId}/recordings/{recordingId}/events/{eventId}/boosts.json
# operationId: CreateEventBoost
export def "recordings-events-boostsjson CreateEventBoost" [
  accountId: string
  recordingId: int
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
]: any -> record<id: int, content: string, created_at: string, booster: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, recording: record<id: int, title: string, type: string, url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/events/($eventId)/boosts.json")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unarchive a recording (restore to active status)
#
# PUT /{accountId}/recordings/{recordingId}/status/active.json
# operationId: UnarchiveRecording
export def "recordings-status-activejson UnarchiveRecording" [
  accountId: string
  recordingId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/status/active.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a recording
#
# PUT /{accountId}/recordings/{recordingId}/status/archived.json
# operationId: ArchiveRecording
export def "recordings-status-archivedjson ArchiveRecording" [
  accountId: string
  recordingId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/status/archived.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trash a recording
#
# PUT /{accountId}/recordings/{recordingId}/status/trashed.json
# operationId: TrashRecording
export def "recordings-status-trashedjson TrashRecording" [
  accountId: string
  recordingId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/status/trashed.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe the current user from a recording
#
# DELETE /{accountId}/recordings/{recordingId}/subscription.json
# operationId: Unsubscribe
export def "recordings-subscriptionjson Unsubscribe" [
  accountId: string
  recordingId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/subscription.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscription information for a recording
#
# GET /{accountId}/recordings/{recordingId}/subscription.json
# operationId: GetSubscription
export def "recordings-subscriptionjson GetSubscription" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subscribed: bool, count: int, url: string, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/subscription.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe the current user to a recording
#
# POST /{accountId}/recordings/{recordingId}/subscription.json
# operationId: Subscribe
export def "recordings-subscriptionjson Subscribe" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subscribed: bool, count: int, url: string, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/subscription.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update subscriptions by adding or removing specific users
#
# PUT /{accountId}/recordings/{recordingId}/subscription.json
# operationId: UpdateSubscription
export def "recordings-subscriptionjson UpdateSubscription" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriptions: list
  --unsubscriptions: list
]: any -> record<subscribed: bool, count: int, url: string, subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/subscription.json")
  let body = {subscriptions: $subscriptions, unsubscriptions: $unsubscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get timesheet for a specific recording
#
# GET /{accountId}/recordings/{recordingId}/timesheet.json
# operationId: GetRecordingTimesheet
export def "recordings-timesheetjson GetRecordingTimesheet" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string
  --qp-to: string
  --person-id: int # format: int64
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, date: string, description: string, hours: string, person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "person_id" $person_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/timesheet.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a timesheet entry on a recording
#
# POST /{accountId}/recordings/{recordingId}/timesheet/entries.json
# operationId: CreateTimesheetEntry
export def "recordings-timesheet-entriesjson CreateTimesheetEntry" [
  accountId: string
  recordingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  date: string
  hours: string
  --description: string
  --person-id: int # format: int64
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, date: string, description: string, hours: string, person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($recordingId)/timesheet/entries.json")
  let body = {date: $date, hours: $hours, description: $description, person_id: $person_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable a tool (hide it from the project dock)
#
# DELETE /{accountId}/recordings/{toolId}/position.json
# operationId: DisableTool
export def "recordings-positionjson DisableTool" [
  accountId: string
  toolId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($toolId)/position.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable a tool (show it on the project dock)
#
# POST /{accountId}/recordings/{toolId}/position.json
# operationId: EnableTool
export def "recordings-positionjson EnableTool" [
  accountId: string
  toolId: int
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
  let full_url = (build-url $base $"/($accountId)/recordings/($toolId)/position.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reposition a tool on the project dock
#
# PUT /{accountId}/recordings/{toolId}/position.json
# operationId: RepositionTool
export def "recordings-positionjson RepositionTool" [
  accountId: string
  toolId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  position: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/recordings/($toolId)/position.json")
  let body = {position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List gauges across all projects the authenticated user has access to. Gauges are sorted by risk level (red, yellow, green), then alphabetically.
#
# GET /{accountId}/reports/gauges.json
# operationId: ListGauges
export def "reports-gaugesjson ListGauges" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bucket-ids: string # Comma-separated list of project IDs. When provided, results are returned in the order specified instead of by risk level.
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, enabled: bool, last_needle_color: string, last_needle_position: int, previous_needle_position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket_ids" $bucket_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/reports/gauges.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account-wide activity feed (progress report)
#
# GET /{accountId}/reports/progress.json
# operationId: GetProgressReport
export def "reports-progressjson GetProgressReport" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, created_at: string, kind: string, parent_recording_id: int, url: string, app_url: string, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, action: string, target: string, title: string, summary_excerpt: string, bucket: record<id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/reports/progress.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get upcoming schedule entries within a date window
#
# GET /{accountId}/reports/schedules/upcoming.json
# operationId: GetUpcomingSchedule
export def "reports-schedules-upcomingjson GetUpcomingSchedule" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --window-starts-on: string
  --window-ends-on: string
]: nothing -> record<schedule_entries: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record, bucket: record, creator: record, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: list, boosts_count: int, boosts_url: string>, recurring_schedule_entry_occurrences: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record, bucket: record, creator: record, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: list, boosts_count: int, boosts_url: string>, assignables: table<id: int, title: string, type: string, url: string, app_url: string, bucket: record, parent: record, due_on: string, starts_on: string, assignees: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "window_starts_on" $window_starts_on "scalar") (serialize-qp "window_ends_on" $window_ends_on "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/reports/schedules/upcoming.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account-wide timesheet report
#
# GET /{accountId}/reports/timesheet.json
# operationId: GetTimesheetReport
export def "reports-timesheetjson GetTimesheetReport" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string
  --qp-to: string
  --person-id: int # format: int64
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, date: string, description: string, hours: string, person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "person_id" $person_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/reports/timesheet.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List people who can be assigned todos
#
# GET /{accountId}/reports/todos/assigned.json
# operationId: ListAssignablePeople
export def "reports-todos-assignedjson ListAssignablePeople" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/reports/todos/assigned.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get todos assigned to a specific person
#
# GET /{accountId}/reports/todos/assigned/{personId}
# operationId: GetAssignedTodos
export def "reports-todos-assigned GetAssignedTodos" [
  accountId: string
  personId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-by: string # Group by "bucket" or "date"
]: nothing -> record<person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, grouped_by: string, todos: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record, bucket: record, creator: record, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: list, completion_subscribers: list, completion_url: string, boosts_count: int, boosts_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/reports/todos/assigned/($personId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get overdue todos grouped by lateness
#
# GET /{accountId}/reports/todos/overdue.json
# operationId: GetOverdueTodos
export def "reports-todos-overduejson GetOverdueTodos" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<under_a_week_late: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record, bucket: record, creator: record, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: list, completion_subscribers: list, completion_url: string, boosts_count: int, boosts_url: string>, over_a_week_late: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record, bucket: record, creator: record, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: list, completion_subscribers: list, completion_url: string, boosts_count: int, boosts_url: string>, over_a_month_late: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record, bucket: record, creator: record, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: list, completion_subscribers: list, completion_url: string, boosts_count: int, boosts_url: string>, over_three_months_late: table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record, bucket: record, creator: record, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: list, completion_subscribers: list, completion_url: string, boosts_count: int, boosts_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/reports/todos/overdue.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a person's activity timeline
#
# GET /{accountId}/reports/users/progress/{personId}.json
# operationId: GetPersonProgress
export def "reports-users-progress GetPersonProgress" [
  accountId: string
  personId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, events: table<id: int, created_at: string, kind: string, parent_recording_id: int, url: string, app_url: string, creator: record, action: string, target: string, title: string, summary_excerpt: string, bucket: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/reports/users/progress/($personId).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single schedule entry by id. Note: Recurring entries will redirect (302) to their recordable URL. Use GetScheduleEntryOccurrence for recurring entries instead.
#
# GET /{accountId}/schedule_entries/{entryId}
# operationId: GetScheduleEntry
export def "schedule-entries GetScheduleEntry" [
  accountId: string
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/schedule_entries/($entryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing schedule entry
#
# PUT /{accountId}/schedule_entries/{entryId}
# operationId: UpdateScheduleEntry
export def "schedule-entries UpdateScheduleEntry" [
  accountId: string
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --summary: string
  --starts-at: string
  --ends-at: string
  --description: string
  --participant-ids: list
  --all-day: string@bool-completer
  --notify: string@bool-completer
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/schedule_entries/($entryId)")
  let body = {summary: $summary, starts_at: $starts_at, ends_at: $ends_at, description: $description, participant_ids: $participant_ids, all_day: $all_day, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific occurrence of a recurring schedule entry
#
# GET /{accountId}/schedule_entries/{entryId}/occurrences/{date}
# operationId: GetScheduleEntryOccurrence
export def "schedule-entries-occurrences GetScheduleEntryOccurrence" [
  accountId: string
  entryId: int
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/schedule_entries/($entryId)/occurrences/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a schedule
#
# GET /{accountId}/schedules/{scheduleId}
# operationId: GetSchedule
export def "schedules GetSchedule" [
  accountId: string
  scheduleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, include_due_assignments: bool, entries_count: int, entries_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update schedule settings
#
# PUT /{accountId}/schedules/{scheduleId}
# operationId: UpdateScheduleSettings
export def "schedules UpdateScheduleSettings" [
  accountId: string
  scheduleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-due-assignments: string@bool-completer
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, include_due_assignments: bool, entries_count: int, entries_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/schedules/($scheduleId)")
  let body = {include_due_assignments: $include_due_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List entries on a schedule  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/schedules/{scheduleId}/entries.json
# operationId: ListScheduleEntries
export def "schedules-entriesjson ListScheduleEntries" [
  accountId: string
  scheduleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # active|archived|trashed
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: list<record>, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/schedules/($scheduleId)/entries.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new schedule entry
#
# POST /{accountId}/schedules/{scheduleId}/entries.json
# operationId: CreateScheduleEntry
export def "schedules-entriesjson CreateScheduleEntry" [
  accountId: string
  scheduleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  summary: string
  starts_at: string
  ends_at: string
  --description: string
  --participant-ids: list
  --all-day: string@bool-completer
  --notify: string@bool-completer
  --subscriptions: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, summary: string, description: string, all_day: bool, starts_at: string, ends_at: string, participants: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/schedules/($scheduleId)/entries.json")
  let body = {summary: $summary, starts_at: $starts_at, ends_at: $ends_at, description: $description, participant_ids: $participant_ids, all_day: $all_day, notify: $notify, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for content across the account
#
# GET /{accountId}/search.json
# operationId: Search
export def "searchjson Search" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string
  --qp-sort: string # best_match|created_at
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, description: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get search metadata (available filter options)
#
# GET /{accountId}/searches/metadata.json
# operationId: GetSearchMetadata
export def "searches-metadatajson GetSearchMetadata" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<projects: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/searches/metadata.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all templates visible to the current user  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/templates.json
# operationId: ListTemplates
export def "templatesjson ListTemplates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # active|archived|trashed
]: nothing -> table<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, url: string, app_url: string, dock: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/templates.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new template
#
# POST /{accountId}/templates.json
# operationId: CreateTemplate
export def "templatesjson CreateTemplate" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, url: string, app_url: string, dock: table<id: int, title: string, name: string, enabled: bool, position: int, url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/templates.json")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template (trash it)
#
# DELETE /{accountId}/templates/{templateId}
# operationId: DeleteTemplate
export def "templates DeleteTemplate" [
  accountId: string
  templateId: int
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
  let full_url = (build-url $base $"/($accountId)/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single template by id
#
# GET /{accountId}/templates/{templateId}
# operationId: GetTemplate
export def "templates GetTemplate" [
  accountId: string
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, url: string, app_url: string, dock: table<id: int, title: string, name: string, enabled: bool, position: int, url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing template
#
# PUT /{accountId}/templates/{templateId}
# operationId: UpdateTemplate
export def "templates UpdateTemplate" [
  accountId: string
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
]: any -> record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, url: string, app_url: string, dock: table<id: int, title: string, name: string, enabled: bool, position: int, url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/templates/($templateId)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a project from a template (asynchronous)
#
# POST /{accountId}/templates/{templateId}/project_constructions.json
# operationId: CreateProjectFromTemplate
export def "templates-project-constructionsjson CreateProjectFromTemplate" [
  accountId: string
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> record<id: int, status: string, url: string, project: record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, purpose: string, clients_enabled: bool, bookmark_url: string, url: string, app_url: string, dock: list<record>, bookmarked: bool, client_company: record<id: int, name: string>, clientside: record<url: string, app_url: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/templates/($templateId)/project_constructions.json")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of a project construction
#
# GET /{accountId}/templates/{templateId}/project_constructions/{constructionId}
# operationId: GetProjectConstruction
export def "templates-project-constructions GetProjectConstruction" [
  accountId: string
  templateId: int
  constructionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, url: string, project: record<id: int, status: string, created_at: string, updated_at: string, name: string, description: string, purpose: string, clients_enabled: bool, bookmark_url: string, url: string, app_url: string, dock: list<record>, bookmarked: bool, client_company: record<id: int, name: string>, clientside: record<url: string, app_url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/templates/($templateId)/project_constructions/($constructionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single timesheet entry
#
# GET /{accountId}/timesheet_entries/{entryId}
# operationId: GetTimesheetEntry
export def "timesheet-entries GetTimesheetEntry" [
  accountId: string
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, date: string, description: string, hours: string, person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/timesheet_entries/($entryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a timesheet entry
#
# PUT /{accountId}/timesheet_entries/{entryId}
# operationId: UpdateTimesheetEntry
export def "timesheet-entries UpdateTimesheetEntry" [
  accountId: string
  entryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string
  --hours: string
  --description: string
  --person-id: int # format: int64
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, date: string, description: string, hours: string, person: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/timesheet_entries/($entryId)")
  let body = {date: $date, hours: $hours, description: $description, person_id: $person_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reposition a todolist group
#
# PUT /{accountId}/todolists/{groupId}/position.json
# operationId: RepositionTodolistGroup
export def "todolists-positionjson RepositionTodolistGroup" [
  accountId: string
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  position: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todolists/($groupId)/position.json")
  let body = {position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single todolist or todolist group by id The endpoint is polymorphic - the same URI returns either a Todolist or TodolistGroup
#
# GET /{accountId}/todolists/{id}
# operationId: GetTodolistOrGroup
export def "todolists GetTodolistOrGroup" [
  accountId: string
  id: int
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
  let full_url = (build-url $base $"/($accountId)/todolists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing todolist or todolist group The endpoint is polymorphic - updates either a Todolist or TodolistGroup
#
# PUT /{accountId}/todolists/{id}
# operationId: UpdateTodolistOrGroup
export def "todolists UpdateTodolistOrGroup" [
  accountId: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name (required for both Todolist and TodolistGroup)
  --description: string # Description (Todolist only, ignored for groups)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todolists/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List groups in a todolist  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/todolists/{todolistId}/groups.json
# operationId: ListTodolistGroups
export def "todolists-groupsjson ListTodolistGroups" [
  accountId: string
  todolistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, name: string, completed: bool, completed_ratio: string, todos_url: string, app_todos_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todolists/($todolistId)/groups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new group in a todolist
#
# POST /{accountId}/todolists/{todolistId}/groups.json
# operationId: CreateTodolistGroup
export def "todolists-groupsjson CreateTodolistGroup" [
  accountId: string
  todolistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, name: string, completed: bool, completed_ratio: string, todos_url: string, app_todos_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todolists/($todolistId)/groups.json")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List todos in a todolist  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/todolists/{todolistId}/todos.json
# operationId: ListTodos
export def "todolists-todosjson ListTodos" [
  accountId: string
  todolistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # active|archived|trashed
  --completed: string@bool-completer
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: list<record>, completion_subscribers: list<record>, completion_url: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "completed" $completed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/todolists/($todolistId)/todos.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new todo in a todolist
#
# POST /{accountId}/todolists/{todolistId}/todos.json
# operationId: CreateTodo
export def "todolists-todosjson CreateTodo" [
  accountId: string
  todolistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string
  --description: string
  --assignee-ids: list
  --completion-subscriber-ids: list
  --notify: string@bool-completer
  --due-on: string
  --starts-on: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todolists/($todolistId)/todos.json")
  let body = {content: $content, description: $description, assignee_ids: $assignee_ids, completion_subscriber_ids: $completion_subscriber_ids, notify: $notify, due_on: $due_on, starts_on: $starts_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trash a todo (returns 204 No Content)
#
# DELETE /{accountId}/todos/{todoId}
# operationId: TrashTodo
export def "todos TrashTodo" [
  accountId: string
  todoId: int
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
  let full_url = (build-url $base $"/($accountId)/todos/($todoId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single todo by id
#
# GET /{accountId}/todos/{todoId}
# operationId: GetTodo
export def "todos GetTodo" [
  accountId: string
  todoId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todos/($todoId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing todo
#
# PUT /{accountId}/todos/{todoId}
# operationId: UpdateTodo
export def "todos UpdateTodo" [
  accountId: string
  todoId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string
  --description: string
  --assignee-ids: list
  --completion-subscriber-ids: list
  --notify: string@bool-completer
  --due-on: string
  --starts-on: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, completed: bool, content: string, starts_on: string, due_on: string, assignees: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_subscribers: table<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, completion_url: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todos/($todoId)")
  let body = {content: $content, description: $description, assignee_ids: $assignee_ids, completion_subscriber_ids: $completion_subscriber_ids, notify: $notify, due_on: $due_on, starts_on: $starts_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark a todo as incomplete
#
# DELETE /{accountId}/todos/{todoId}/completion.json
# operationId: UncompleteTodo
export def "todos-completionjson UncompleteTodo" [
  accountId: string
  todoId: int
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
  let full_url = (build-url $base $"/($accountId)/todos/($todoId)/completion.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a todo as complete
#
# POST /{accountId}/todos/{todoId}/completion.json
# operationId: CompleteTodo
export def "todos-completionjson CompleteTodo" [
  accountId: string
  todoId: int
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
  let full_url = (build-url $base $"/($accountId)/todos/($todoId)/completion.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reposition a todo within its todolist
#
# PUT /{accountId}/todos/{todoId}/position.json
# operationId: RepositionTodo
export def "todos-positionjson RepositionTodo" [
  accountId: string
  todoId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  position: int # format: int32
  --parent-id: int # Optional todolist ID to move the todo to a different parent (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todos/($todoId)/position.json")
  let body = {position: $position, parent_id: $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a todoset (container for todolists in a project)
#
# GET /{accountId}/todosets/{todosetId}
# operationId: GetTodoset
export def "todosets GetTodoset" [
  accountId: string
  todosetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, name: string, todolists_count: int, todolists_url: string, completed_ratio: string, completed: bool, app_todolists_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todosets/($todosetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the hill chart for a todoset
#
# GET /{accountId}/todosets/{todosetId}/hill.json
# operationId: GetHillChart
export def "todosets-hilljson GetHillChart" [
  accountId: string
  todosetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, stale: bool, updated_at: string, app_update_url: string, app_versions_url: string, dots: table<id: int, label: string, color: string, position: int, url: string, app_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todosets/($todosetId)/hill.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Track or untrack todolists on a hill chart
#
# PUT /{accountId}/todosets/{todosetId}/hills/settings.json
# operationId: UpdateHillChartSettings
export def "todosets-hills-settingsjson UpdateHillChartSettings" [
  accountId: string
  todosetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tracked: list
  --untracked: list
]: any -> record<enabled: bool, stale: bool, updated_at: string, app_update_url: string, app_versions_url: string, dots: table<id: int, label: string, color: string, position: int, url: string, app_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todosets/($todosetId)/hills/settings.json")
  let body = {tracked: $tracked, untracked: $untracked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List todolists in a todoset  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/todosets/{todosetId}/todolists.json
# operationId: ListTodolists
export def "todosets-todolistsjson ListTodolists" [
  accountId: string
  todosetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # active|archived|trashed
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, completed: bool, completed_ratio: string, name: string, todos_url: string, groups_url: string, app_todos_url: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($accountId)/todosets/($todosetId)/todolists.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new todolist in a todoset
#
# POST /{accountId}/todosets/{todosetId}/todolists.json
# operationId: CreateTodolist
export def "todosets-todolistsjson CreateTodolist" [
  accountId: string
  todosetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, completed: bool, completed_ratio: string, name: string, todos_url: string, groups_url: string, app_todos_url: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/todosets/($todosetId)/todolists.json")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single upload by id
#
# GET /{accountId}/uploads/{uploadId}
# operationId: GetUpload
export def "uploads GetUpload" [
  accountId: string
  uploadId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, content_type: string, byte_size: int, width: int, height: int, download_url: string, filename: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/uploads/($uploadId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing upload
#
# PUT /{accountId}/uploads/{uploadId}
# operationId: UpdateUpload
export def "uploads UpdateUpload" [
  accountId: string
  uploadId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --base-name: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, content_type: string, byte_size: int, width: int, height: int, download_url: string, filename: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/uploads/($uploadId)")
  let body = {description: $description, base_name: $base_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List versions of an upload  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/uploads/{uploadId}/versions.json
# operationId: ListUploadVersions
export def "uploads-versionsjson ListUploadVersions" [
  accountId: string
  uploadId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, content_type: string, byte_size: int, width: int, height: int, download_url: string, filename: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/uploads/($uploadId)/versions.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single vault by id
#
# GET /{accountId}/vaults/{vaultId}
# operationId: GetVault
export def "vaults GetVault" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, documents_count: int, documents_url: string, uploads_count: int, uploads_url: string, vaults_count: int, vaults_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing vault
#
# PUT /{accountId}/vaults/{vaultId}
# operationId: UpdateVault
export def "vaults UpdateVault" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, documents_count: int, documents_url: string, uploads_count: int, uploads_url: string, vaults_count: int, vaults_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List documents in a vault  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/vaults/{vaultId}/documents.json
# operationId: ListDocuments
export def "vaults-documentsjson ListDocuments" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)/documents.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new document in a vault
#
# POST /{accountId}/vaults/{vaultId}/documents.json
# operationId: CreateDocument
export def "vaults-documentsjson CreateDocument" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  --content: string
  --status: string # active|drafted
  --subscriptions: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, content: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)/documents.json")
  let body = {title: $title, content: $content, status: $status, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List uploads in a vault  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/vaults/{vaultId}/uploads.json
# operationId: ListUploads
export def "vaults-uploadsjson ListUploads" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, content_type: string, byte_size: int, width: int, height: int, download_url: string, filename: string, boosts_count: int, boosts_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)/uploads.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new upload in a vault
#
# POST /{accountId}/vaults/{vaultId}/uploads.json
# operationId: CreateUpload
export def "vaults-uploadsjson CreateUpload" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attachable_sgid: string
  --description: string
  --base-name: string
  --subscriptions: list
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, subscription_url: string, comments_count: int, comments_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, description: string, content_type: string, byte_size: int, width: int, height: int, download_url: string, filename: string, boosts_count: int, boosts_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)/uploads.json")
  let body = {attachable_sgid: $attachable_sgid, description: $description, base_name: $base_name, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List vaults (subfolders) in a vault  **Pagination**: Uses Link header (RFC5988). Follow the `next` rel URL to fetch additional pages. X-Total-Count header provides total count.
#
# GET /{accountId}/vaults/{vaultId}/vaults.json
# operationId: ListVaults
export def "vaults-vaultsjson ListVaults" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, documents_count: int, documents_url: string, uploads_count: int, uploads_url: string, vaults_count: int, vaults_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)/vaults.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new vault (subfolder) in a vault
#
# POST /{accountId}/vaults/{vaultId}/vaults.json
# operationId: CreateVault
export def "vaults-vaultsjson CreateVault" [
  accountId: string
  vaultId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
]: any -> record<id: int, status: string, visible_to_clients: bool, created_at: string, updated_at: string, title: string, inherits_status: bool, type: string, url: string, app_url: string, bookmark_url: string, position: int, parent: record<id: int, title: string, type: string, url: string, app_url: string>, bucket: record<id: int, name: string, type: string>, creator: record<id: int, attachable_sgid: string, name: string, email_address: string, personable_type: string, title: string, bio: string, location: string, created_at: string, updated_at: string, admin: bool, owner: bool, client: bool, employee: bool, time_zone: string, avatar_url: string, company: record<id: int, name: string>, can_manage_projects: bool, can_manage_people: bool, can_ping: bool, can_access_timesheet: bool, can_access_hill_charts: bool>, documents_count: int, documents_url: string, uploads_count: int, uploads_url: string, vaults_count: int, vaults_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/vaults/($vaultId)/vaults.json")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /{accountId}/webhooks/{webhookId}
# operationId: DeleteWebhook
export def "webhooks DeleteWebhook" [
  accountId: string
  webhookId: int
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
  let full_url = (build-url $base $"/($accountId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single webhook by id
#
# GET /{accountId}/webhooks/{webhookId}
# operationId: GetWebhook
export def "webhooks GetWebhook" [
  accountId: string
  webhookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, active: bool, created_at: string, updated_at: string, payload_url: string, types: list<string>, url: string, app_url: string, recent_deliveries: table<id: int, created_at: string, request: record, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing webhook
#
# PUT /{accountId}/webhooks/{webhookId}
# operationId: UpdateWebhook
export def "webhooks UpdateWebhook" [
  accountId: string
  webhookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payload-url: string
  --types: list
  --active: string@bool-completer
]: any -> record<id: int, active: bool, created_at: string, updated_at: string, payload_url: string, types: list<string>, url: string, app_url: string, recent_deliveries: table<id: int, created_at: string, request: record, response: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($accountId)/webhooks/($webhookId)")
  let body = {payload_url: $payload_url, types: $types, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
