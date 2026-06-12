# Auto-generated client for Zenduty v1.1.0
# Source: https://apidocs.zenduty.com/openapi.json
# Auth: --token flag or $env.ZENDUTY_TOKEN

const BASE_URL = "https://www.zenduty.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ZENDUTY_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.zenduty.com" "https://events.zenduty.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def tta-comparator-completer [] { ["gt" "lt"] }
def ttr-comparator-completer [] { ["gt" "lt"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-api-invite post" } } | get name | first)
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

# Invite User
#
# POST /api/account/api_invite/
# --user_detail shape: {first_name?: string, last_name?: string, email?: string, role?: int}
export def "account-api-invite post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  team: string # A system-generated string that represents the Team object's unique_id
  user_detail: record # User object schema — shape: {first_name?: string, last_name?: string, email?: string, role?: int}
]: any -> record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/api_invite/")
  let body = {team: $team, user_detail: $user_detail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Account Member objects
#
# GET /api/account/members/
export def "account-members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, time_zone: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int, is_verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/members/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Account Member object
#
# GET /api/account/members/{username}/
export def "account-members get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, time_zone: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int, is_verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/members/($username)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Account Member object
#
# PUT /api/account/members/{username}/
# --user shape: {username?: string, first_name?: string, last_name?: string, email?: string}
export def "account-members put" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --time-zone: string # A formatted string that represents the Account Member object's time zone. You can check out the time zone list here https://timezonedb.com/time-zones (default: UTC)
  user: record # User object schema — shape: {username?: string, first_name?: string, last_name?: string, email?: string}
  --role: int # An integer that represents the Account Member object's role. 1 is owner, 2 is admin and 3 is user (default: 3)
]: any -> record<unique_id: string, time_zone: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int, is_verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/members/($username)/")
  let body = {time_zone: $time_zone, user: $user, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete User
#
# POST /api/account/deleteuser/
export def "account-deleteuser post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string # A system-generated string that represents the User object's username
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/deleteuser/")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create the Account Custom Role object
#
# POST /api/account/customroles/
export def "account-customroles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the unique name for Account Custom Role object
  --description: string # A string that represents the description for Account Custom Role object
  permissions: list # An array of account level permissions
]: any -> record<unique_id: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/customroles/")
  let body = {name: $name, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Account Custom Role objects
#
# GET /api/account/customroles/
export def "account-customroles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, description: string, permissions: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/customroles/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Account Custom Role object
#
# GET /api/account/customroles/{custom_role_id}/
export def "account-customroles get" [
  custom_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, description: string, permissions: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/customroles/($custom_role_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Account Custom Role object
#
# PUT /api/account/customroles/{custom_role_id}/
export def "account-customroles put" [
  custom_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the unique name for Account Custom Role object
  --description: string # A string that represents the description for Account Custom Role object
  permissions: list # An array of account level permissions
]: any -> record<unique_id: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/customroles/($custom_role_id)/")
  let body = {name: $name, description: $description, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Account Custom Role object
#
# DELETE /api/account/customroles/{custom_role_id}/
export def "account-customroles delete" [
  custom_role_id: string
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
  let full_url = (build-url $base $"/api/account/customroles/($custom_role_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the User Custom Role object
#
# POST /api/account/users/{username}/customroles/
export def "account-users-customroles post" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  custom_role: string # A system-generated string that represents the User Custom Role object's unique_id
]: any -> record<user: string, custom_role: string, custom_role_details: record<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/customroles/")
  let body = {custom_role: $custom_role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all User Custom Role objects
#
# GET /api/account/users/{username}/customroles/
export def "account-users-customroles get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<user: string, custom_role: string, custom_role_details: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/customroles/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the User Notification Rules object
#
# POST /api/account/users/{username}/notification_rules/
export def "account-users-notification-rules post" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  contact: string # A system-generated string that represents the User Contact Method object's unique_id
  --start-delay: int # An integer that represents the User Notification Rules object's delay field in minutes.
  --urgency: int # An integer that represents the User Notification Rules object's urgency field. 1 is for high urgency incidents and 0 is for low urgency incidents.
]: any -> record<creation_date: string, start_delay: int, type: string, unique_id: string, contact: string, urgency: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/notification_rules/")
  let body = {contact: $contact, start_delay: $start_delay, urgency: $urgency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Users' Notification Rule objects
#
# GET /api/account/users/{username}/notification_rules/
export def "account-users-notification-rules list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<creation_date: string, start_delay: int, type: string, unique_id: string, contact: string, urgency: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/notification_rules/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the User Notification Rule object
#
# GET /api/account/users/{username}/notification_rules/{notification_rule_id}/
export def "account-users-notification-rules get" [
  username: string
  notification_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<creation_date: string, start_delay: int, type: string, unique_id: string, contact: string, urgency: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/notification_rules/($notification_rule_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the User Notification Rules object
#
# DELETE /api/account/users/{username}/notification_rules/{notification_rule_id}/
export def "account-users-notification-rules delete" [
  username: string
  notification_rule_id: string
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
  let full_url = (build-url $base $"/api/account/users/($username)/notification_rules/($notification_rule_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the User Forwarding Rules object
#
# POST /api/account/users/{username}/forwarding_rules/
export def "account-users-forwarding-rules post" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  from_date: string # A formatted string that represents the User Forwarding Rule object's from_date field (format: date-time)
  to_date: string # A formatted string that represents the User Forwarding Rule object's to_date field (format: date-time)
  --time-zone: string # A formatted string that represents the User Forwarding Rule object's time zone. You can check out the time zone list here https://timezonedb.com/time-zones
  to_user: string # A system-generated string that represents the User object's username
]: any -> record<creation_date: string, unique_id: string, time_zone: string, from_date: string, to_date: string, to_user: string, created_by: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/forwarding_rules/")
  let body = {from_date: $from_date, to_date: $to_date, time_zone: $time_zone, to_user: $to_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all User Forwarding Rule objects
#
# GET /api/account/users/{username}/forwarding_rules/
export def "account-users-forwarding-rules list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<creation_date: string, unique_id: string, time_zone: string, from_date: string, to_date: string, to_user: string, created_by: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/forwarding_rules/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the User Forwarding Rules object
#
# GET /api/account/users/{username}/forwarding_rules/{forwarding_rule_id}/
export def "account-users-forwarding-rules get" [
  username: string
  forwarding_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<creation_date: string, unique_id: string, time_zone: string, from_date: string, to_date: string, to_user: string, created_by: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/forwarding_rules/($forwarding_rule_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the User Forwarding Rule object
#
# DELETE /api/account/users/{username}/forwarding_rules/{forwarding_rule_id}/
export def "account-users-forwarding-rules delete" [
  username: string
  forwarding_rule_id: string
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
  let full_url = (build-url $base $"/api/account/users/($username)/forwarding_rules/($forwarding_rule_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the User Contact Methods object
#
# POST /api/account/users/{username}/contacts/
export def "account-users-contacts post" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the User Contact Method object's name field
  value: string # A formatted string that represents the User Contact Method object's value field. value can be Email ID, Phone Number, Slack ID, Microsoft ID, Google Chat ID.
  contact_type: int # An integer that represents the User Contact Method object's contact_type field. 1 is for Email, 2 is for SMS, 3 is for Phone Call, 4 is for Slack, 5 is for MS Teams and 6 is for Google Chat
]: any -> record<name: string, creation_date: string, contact_type: int, value: string, unique_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/contacts/")
  let body = {name: $name, value: $value, contact_type: $contact_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all User Contact Method objects
#
# GET /api/account/users/{username}/contacts/
export def "account-users-contacts list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, creation_date: string, contact_type: int, value: string, unique_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/contacts/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the User Contact Methods object
#
# GET /api/account/users/{username}/contacts/{contact_id}/
export def "account-users-contacts get" [
  username: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, creation_date: string, contact_type: int, value: string, unique_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/users/($username)/contacts/($contact_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the User Contact Methods object
#
# DELETE /api/account/users/{username}/contacts/{contact_id}/
export def "account-users-contacts delete" [
  username: string
  contact_id: string
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
  let full_url = (build-url $base $"/api/account/users/($username)/contacts/($contact_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Team object
#
# POST /api/account/teams/
export def "account-teams post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A that represents the Team object's name
]: any -> record<unique_id: string, name: string, account: string, creation_date: string, members: record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int>, owner: string, roles: record<unique_id: string, team: string, title: string, description: string, creation_date: string, rank: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/teams/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Team objects
#
# GET /api/account/teams/
export def "account-teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, account: string, creation_date: string, members: record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int>, owner: string, roles: record<unique_id: string, team: string, title: string, description: string, creation_date: string, rank: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/teams/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Team object
#
# GET /api/account/teams/{team_id}/
export def "account-teams get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, account: string, creation_date: string, members: record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int>, owner: string, roles: record<unique_id: string, team: string, title: string, description: string, creation_date: string, rank: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Team object
#
# PUT /api/account/teams/{team_id}/
export def "account-teams put" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A that represents the Team object's name
]: any -> record<unique_id: string, name: string, account: string, creation_date: string, members: record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int>, owner: string, roles: record<unique_id: string, team: string, title: string, description: string, creation_date: string, rank: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Team object
#
# DELETE /api/account/teams/{team_id}/
export def "account-teams delete" [
  team_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add user to Team
#
# POST /api/account/teams/{}/members/
export def "account-teams-members post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  user: string # A string that represents the User's username
  --role: int # An integer that represents the Team Member object's role. 1 is manager and 2 is user (default: 2)
]: any -> record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/members/")
  let body = {user: $user, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Team Member objects
#
# GET /api/account/teams/{}/members/
export def "account-teams-members list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/members/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Team Member object
#
# GET /api/account/teams/{team_id}/members/{member_id}/
export def "account-teams-members get" [
  team_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/members/($member_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Team Member object
#
# PUT /api/account/teams/{team_id}/members/{member_id}/
export def "account-teams-members put" [
  team_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  user: string # A string that represents the User's username
  --role: int # An integer that represents the Team Member object's role. 1 is manager and 2 is user (default: 2)
]: any -> record<unique_id: string, team: string, user: record<username: string, first_name: string, last_name: string, email: string>, joining_date: string, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/members/($member_id)/")
  let body = {user: $user, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Team Member object
#
# DELETE /api/account/teams/{team_id}/members/{member_id}/
export def "account-teams-members delete" [
  team_id: string
  member_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/members/($member_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Team Permission object
#
# GET /api/account/teams/{}/permissions/
export def "account-teams-permissions get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, account_permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/permissions/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Team Permission object
#
# PUT /api/account/teams/{}/permissions/
export def "account-teams-permissions put" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_permissions: list # An array of team level permissions
]: any -> record<unique_id: string, account_permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/permissions/")
  let body = {account_permissions: $account_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create the Schedule object
#
# POST /api/account/teams/{}/schedules/
# --layers item shape: {shift_length?: int, restrictions?: list, name?: string, users?: list, rotation_start_time?: string, rotation_end_time?: string, restriction_type?: int}
# --overrides item shape: {name?: string, user?: string, start_time?: string, end_time?: string}
export def "account-teams-schedules post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the Schedule object's name
  --summary: string # A string that represents the Schedule object's summary
  --description: string # A string that represents the Schedule object's description
  --time-zone: string # A formatted string that represents the Schedule object's time zone. You can check out the time zone list here https://timezonedb.com/time-zones
  --layers: list # An array of Schedule Layer objects — item shape: {shift_length?: int, restrictions?: list, name?: string, users?: list, rotation_start_time?: string, rotation_end_time?: string, restriction_type?: int}
  --overrides: list # An array of Schedule Overrides objects — item shape: {name?: string, user?: string, start_time?: string, end_time?: string}
]: any -> record<name: string, summary: string, description: string, time_zone: string, team: string, layers: table<shift_length: int, restrictions: list, name: string, users: list, rotation_start_time: string, rotation_end_time: string, unique_id: string, last_edited: string, restriction_type: int, is_active: bool>, overrides: table<name: string, user: string, start_time: string, end_time: string, unique_id: string>, unique_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/schedules/")
  let body = {name: $name, summary: $summary, description: $description, time_zone: $time_zone, layers: $layers, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Schedule objects
#
# GET /api/account/teams/{}/schedules/
export def "account-teams-schedules list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, summary: string, description: string, time_zone: string, team: string, layers: table<shift_length: int, restrictions: list, name: string, users: list, rotation_start_time: string, rotation_end_time: string, unique_id: string, last_edited: string, restriction_type: int, is_active: bool>, overrides: table<name: string, user: string, start_time: string, end_time: string, unique_id: string>, unique_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/schedules/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Schedule object
#
# GET /api/account/teams/{team_id}/schedules/{schedule_id}/
export def "account-teams-schedules get" [
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, summary: string, description: string, time_zone: string, team: string, layers: table<shift_length: int, restrictions: list, name: string, users: list, rotation_start_time: string, rotation_end_time: string, unique_id: string, last_edited: string, restriction_type: int, is_active: bool>, overrides: table<name: string, user: string, start_time: string, end_time: string, unique_id: string>, unique_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/schedules/($schedule_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Schedule object
#
# PUT /api/account/teams/{team_id}/schedules/{schedule_id}/
# --layers item shape: {shift_length?: int, restrictions?: list, name?: string, users?: list, rotation_start_time?: string, rotation_end_time?: string, restriction_type?: int}
# --overrides item shape: {name?: string, user?: string, start_time?: string, end_time?: string}
export def "account-teams-schedules put" [
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the Schedule object's name
  --summary: string # A string that represents the Schedule object's summary
  --description: string # A string that represents the Schedule object's description
  --time-zone: string # A formatted string that represents the Schedule object's time zone. You can check out the time zone list here https://timezonedb.com/time-zones
  --layers: list # An array of Schedule Layer objects — item shape: {shift_length?: int, restrictions?: list, name?: string, users?: list, rotation_start_time?: string, rotation_end_time?: string, restriction_type?: int}
  --overrides: list # An array of Schedule Overrides objects — item shape: {name?: string, user?: string, start_time?: string, end_time?: string}
]: any -> record<name: string, summary: string, description: string, time_zone: string, team: string, layers: table<shift_length: int, restrictions: list, name: string, users: list, rotation_start_time: string, rotation_end_time: string, unique_id: string, last_edited: string, restriction_type: int, is_active: bool>, overrides: table<name: string, user: string, start_time: string, end_time: string, unique_id: string>, unique_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/schedules/($schedule_id)/")
  let body = {name: $name, summary: $summary, description: $description, time_zone: $time_zone, layers: $layers, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Schedule object
#
# DELETE /api/account/teams/{team_id}/schedules/{schedule_id}/
export def "account-teams-schedules delete" [
  team_id: string
  schedule_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/schedules/($schedule_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Schedule Override object
#
# POST /api/v2/account/teams/{}/schedules/{}/overrides/
export def "account-teams-schedules-overrides post" [
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Schedule Overrides object's name
  --user: string # A string that represents the User object's username
  --start-time: string # A fromatted string that represents the Schedule Overrides object's start_time
  --end-time: string # A fromatted string that represents the Schedule Overrides object's end_time
]: any -> record<name: string, user: string, start_time: string, end_time: string, unique_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/teams/{}/schedules/{}/overrides/")
  let body = {name: $name, user: $user, start_time: $start_time, end_time: $end_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Schedule overrides objects
#
# GET /api/v2/account/teams/{}/schedules/{}/overrides/
export def "account-teams-schedules-overrides get" [
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, user: string, start_time: string, end_time: string, overridden_details: string, unique_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/teams/{}/schedules/{}/overrides/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Escalation Policy object
#
# POST /api/account/teams/{}/escalation_policies/
# --rules shape: {delay: int, target?: record, position?: int}
export def "account-teams-escalation-policies post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the Escalation Policy object's name
  --summary: string # A string that represents the Escalation Policy object's summary
  --description: string # A string that represents the Escalation Policy object's description
  rules: record # Escalation Policy Rule Payload object schema — shape: {delay: int, target?: record, position?: int}
]: any -> record<name: string, summary: string, description: string, rules: record<delay: int, target: record<target_type: int, target_id: string>, position: int, unique_id: string>, unique_id: string, team: string, repeat_policy: int, move_to_next: bool, global_ep: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/escalation_policies/")
  let body = {name: $name, summary: $summary, description: $description, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Escalation Policy objects
#
# GET /api/account/teams/{}/escalation_policies/
export def "account-teams-escalation-policies list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, summary: string, description: string, rules: record<delay: int, target: record<target_type: int, target_id: string>, position: int, unique_id: string>, unique_id: string, team: string, repeat_policy: int, move_to_next: bool, global_ep: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/escalation_policies/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Escalation Policy object
#
# GET /api/account/teams/{team_id}/escalation_policies/{escalation_policy_id}/
export def "account-teams-escalation-policies get" [
  team_id: string
  escalation_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, summary: string, description: string, rules: record<delay: int, target: record<target_type: int, target_id: string>, position: int, unique_id: string>, unique_id: string, team: string, repeat_policy: int, move_to_next: bool, global_ep: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/escalation_policies/($escalation_policy_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Escalation Policy object
#
# PUT /api/account/teams/{team_id}/escalation_policies/{escalation_policy_id}/
# --rules shape: {delay: int, target?: record, position?: int}
export def "account-teams-escalation-policies put" [
  team_id: string
  escalation_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the Escalation Policy object's name
  --summary: string # A string that represents the Escalation Policy object's summary
  --description: string # A string that represents the Escalation Policy object's description
  rules: record # Escalation Policy Rule Payload object schema — shape: {delay: int, target?: record, position?: int}
]: any -> record<name: string, summary: string, description: string, rules: record<delay: int, target: record<target_type: int, target_id: string>, position: int, unique_id: string>, unique_id: string, team: string, repeat_policy: int, move_to_next: bool, global_ep: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/escalation_policies/($escalation_policy_id)/")
  let body = {name: $name, summary: $summary, description: $description, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Escalation Policy object
#
# DELETE /api/account/teams/{team_id}/escalation_policies/{escalation_policy_id}/
export def "account-teams-escalation-policies delete" [
  team_id: string
  escalation_policy_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/escalation_policies/($escalation_policy_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Service object
#
# POST /api/account/teams/{}/services/
export def "account-teams-services post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Service object's name
  --summary: string # A string that represents the Service object's summary
  --description: string # A string that represents the Service object's description
  --auto-resolve-timeout: int # An integer that represents the timeout for automatically resolving an Incident (default: 0)
  team_priority: string # A system-generated string that represents the Priority object's unique_id
  --task-template: string # A system-generated string that represents the Task Template object's unique_id
  --acknowledgement-timeout-enabled: oneof<nothing, bool> # An boolean flag that represents whether a service has acknowledgement timeout is enabled. If true, the "acknowledgement_timeout" field value needs to be set (default: false)
  --acknowledgement-timeout: int # An integer that represents the acknowledgement timeout value in seconds. If an incident is acknowledged and unresolved within this time window, the incident will be retriggered. This value must be above 600 seconds. (default: 600)
  --status: int # An integer that represents the Service object's status 0 is disabled, 1 is active, 2 is a warning, 3 is critical, and 4 is under maintenance (default: 1)
  escalation_policy: string # A system-generated string that represents the Escalation Policy object's unique_id
  sla: string # A system-generated string that represents the SLA object's unique_id
  --under-maintenance: oneof<nothing, bool> # A boolean flag that represents whether the service object is under maintenance or not (default: false)
  --collation: int # An integer that represents the Service object's collation type. 0 is off, 1 is time-based. (default: 0)
  --collation-time: int # An integer that represents the Service object's collation_time. When collation is turned on it needs to be greater than 1 minute & less than 1440 minutes. (default: 0)
]: any -> record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, collation_time: int, collation: int, under_maintenance: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/services/")
  let body = {name: $name, summary: $summary, description: $description, auto_resolve_timeout: $auto_resolve_timeout, team_priority: $team_priority, task_template: $task_template, acknowledgement_timeout_enabled: $acknowledgement_timeout_enabled, acknowledgement_timeout: $acknowledgement_timeout, status: $status, escalation_policy: $escalation_policy, sla: $sla, under_maintenance: $under_maintenance, collation: $collation, collation_time: $collation_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Service objects
#
# GET /api/account/teams/{}/services/
export def "account-teams-services list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, under_maintenance: bool, collation: int, collation_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/services/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Service object
#
# GET /api/account/teams/{team_id}/services/{service_id}/
export def "account-teams-services get" [
  team_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, under_maintenance: bool, collation: int, collation_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Service object
#
# PUT /api/account/teams/{team_id}/services/{service_id}/
export def "account-teams-services put" [
  team_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Service object's name
  --summary: string # A string that represents the Service object's summary
  --description: string # A string that represents the Service object's description
  --auto-resolve-timeout: int # An integer that represents the timeout for automatically resolving an Incident (default: 0)
  team_priority: string # A system-generated string that represents the Priority object's unique_id
  --task-template: string # A system-generated string that represents the Task Template object's unique_id
  --acknowledgement-timeout-enabled: oneof<nothing, bool> # An boolean flag that represents whether a service has acknowledgement timeout is enabled. If true, the "acknowledgement_timeout" field value needs to be set (default: false)
  --acknowledgement-timeout: int # An integer that represents the acknowledgement timeout value in seconds. If an incident is acknowledged and unresolved within this time window, the incident will be retriggered. This value must be above 600 seconds. (default: 600)
  --status: int # An integer that represents the Service object's status 0 is disabled, 1 is active, 2 is a warning, 3 is critical, and 4 is under maintenance (default: 1)
  escalation_policy: string # A system-generated string that represents the Escalation Policy object's unique_id
  sla: string # A system-generated string that represents the SLA object's unique_id
  --under-maintenance: oneof<nothing, bool> # A boolean flag that represents whether the service object is under maintenance or not (default: false)
  --collation: int # An integer that represents the Service object's collation type. 0 is off, 1 is time-based. (default: 0)
  --collation-time: int # An integer that represents the Service object's collation_time. When collation is turned on it needs to be greater than 1 minute & less than 1440 minutes. (default: 0)
]: any -> record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, collation_time: int, collation: int, under_maintenance: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/")
  let body = {name: $name, summary: $summary, description: $description, auto_resolve_timeout: $auto_resolve_timeout, team_priority: $team_priority, task_template: $task_template, acknowledgement_timeout_enabled: $acknowledgement_timeout_enabled, acknowledgement_timeout: $acknowledgement_timeout, status: $status, escalation_policy: $escalation_policy, sla: $sla, under_maintenance: $under_maintenance, collation: $collation, collation_time: $collation_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Service object
#
# DELETE /api/account/teams/{team_id}/services/{service_id}/
export def "account-teams-services delete" [
  team_id: string
  service_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Integration object
#
# POST /api/account/teams/{}/services/{service_id}/integrations/
export def "account-teams-services-integrations post" [
  team_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Integration object's name
  --summary: string # A string that represents the Integration object's summary
  application: string # A system-generated string that represents the Application object's unique_id. To get application id, vist https://www.zenduty.com/api/account/applications/ and get unique_id of the application.
  --is-enabled: oneof<nothing, bool> # A boolean flag that represents whether an Integration is enabled or not (default: true)
  --create-incidents-for: int # An integer that represents the type of the Incidents this Integration object will create. 0 is do not create incidents. 1 is critical, 2 is critical and errors, and 3 is critical, errors and warnings. (default: 1)
  --integration-type: int # An integer that represents the Integration object's integration_type. 0 is alert and 1 is outbound. (default: 0)
  --default-urgency: int # An integer that represents the Integration object's default_urgency. 0 is low and 1 is high. (default: 1)
]: any -> record<name: string, creation_date: string, summary: string, unique_id: string, service: string, application: string, application_reference: record<name: string, icon_url: string, summary: string, description: string, unique_id: string, availability_plan_id: int, setup_instructions: string, extension: string, application_type: int, categories: string, documentation_link: string>, integration_key: string, created_by: string, is_enabled: bool, create_incidents_for: int, integration_type: int, default_urgency: int, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/services/($service_id)/integrations/")
  let body = {name: $name, summary: $summary, application: $application, is_enabled: $is_enabled, create_incidents_for: $create_incidents_for, integration_type: $integration_type, default_urgency: $default_urgency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Integration objects
#
# GET /api/account/teams/{}/services/{service_id}/integrations/
export def "account-teams-services-integrations list" [
  team_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, creation_date: string, summary: string, unique_id: string, service: string, application: string, application_reference: record<name: string, icon_url: string, summary: string, description: string, unique_id: string, availability_plan_id: int, setup_instructions: string, extension: string, application_type: int, categories: string, documentation_link: string>, integration_key: string, created_by: string, is_enabled: bool, create_incidents_for: int, integration_type: int, default_urgency: int, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/services/($service_id)/integrations/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Integration object
#
# GET /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/
export def "account-teams-services-integrations get" [
  team_id: string
  service_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string, creation_date: string, summary: string, unique_id: string, service: string, application: string, application_reference: record<name: string, icon_url: string, summary: string, description: string, unique_id: string, availability_plan_id: int, setup_instructions: string, extension: string, application_type: int, categories: string, documentation_link: string>, integration_key: string, created_by: string, is_enabled: bool, create_incidents_for: int, integration_type: int, default_urgency: int, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Integration object
#
# PUT /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/
export def "account-teams-services-integrations put" [
  team_id: string
  service_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Integration object's name
  --summary: string # A string that represents the Integration object's summary
  application: string # A system-generated string that represents the Application object's unique_id. To get application id, vist https://www.zenduty.com/api/account/applications/ and get unique_id of the application.
  --is-enabled: oneof<nothing, bool> # A boolean flag that represents whether an Integration is enabled or not (default: true)
  --create-incidents-for: int # An integer that represents the type of the Incidents this Integration object will create. 0 is do not create incidents. 1 is critical, 2 is critical and errors, and 3 is critical, errors and warnings. (default: 1)
  --integration-type: int # An integer that represents the Integration object's integration_type. 0 is alert and 1 is outbound. (default: 0)
  --default-urgency: int # An integer that represents the Integration object's default_urgency. 0 is low and 1 is high. (default: 1)
]: any -> record<name: string, creation_date: string, summary: string, unique_id: string, service: string, application: string, application_reference: record<name: string, icon_url: string, summary: string, description: string, unique_id: string, availability_plan_id: int, setup_instructions: string, extension: string, application_type: int, categories: string, documentation_link: string>, integration_key: string, created_by: string, is_enabled: bool, create_incidents_for: int, integration_type: int, default_urgency: int, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/")
  let body = {name: $name, summary: $summary, application: $application, is_enabled: $is_enabled, create_incidents_for: $create_incidents_for, integration_type: $integration_type, default_urgency: $default_urgency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Integration object
#
# DELETE /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/
export def "account-teams-services-integrations delete" [
  team_id: string
  service_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate the Integration key
#
# POST /api/account/regenerate_integration_key/
export def "account-regenerate-integration-key post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --integration-unique-id: string # A string that represents the relevant Integration's unique ID
]: any -> record<name: string, creation_date: string, summary: string, unique_id: string, service: string, application: string, application_reference: record<name: string, icon_url: string, summary: string, description: string, unique_id: string, availability_plan_id: int, setup_instructions: string, extension: string, application_type: int, categories: string, documentation_link: string>, integration_key: string, created_by: string, is_enabled: bool, create_incidents_for: int, integration_type: int, default_urgency: int, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/account/regenerate_integration_key/")
  let body = {integration_unique_id: $integration_unique_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch metadata of the Integration object
#
# GET /api/account/integration-metadata/{integration_key}/
export def "account-integration-metadata get" [
  integration_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<team: record<name: string, unique_id: string>, service: record<name: string, unique_id: string>, integration: record<unique_id: string, name: string, extension: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/integration-metadata/($integration_key)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Incident objects(filtered)
#
# POST /api/incidents/filter/
export def "incidents-filter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # pagination page number. example - `page=1`
  --all-teams: int # This query parameter can be `0` or `1`. To filter incidents based on all teams use `1` and to filter incidents based on the teams the requesting user belongs to, use `0`. example - `all_teams=1` (default: 1)
  --escalation-policy-ids: list # A list of escalation policy unique ids
  --from-date: string # Represents from_date and filters incidents whose creation_date is greater than the specified from_date. example - `from_date="2023-02-01"` (default: [])
  --postmortem-filter: int # An integer that represents weather the postmortem is attached to the incident or not (default: -1)
  --priority-ids: list # A list of Team Priority unique ids
  --priority-name: string # Name of the Team priroty object
  --service-ids: list # A list of Service unique ids
  --sla-ids: list # A list of Team SLA unique ids
  --status: int # Status of the Incident object. For open incidents(triggered and acknowledged) use `-1`, for all incidents(triggered, acknowledged and resolved) use `0`, for triggered incidents use `1`, for acknowledged incidents use `2` and for resolved incidents use `3`. example - `status=1` (default: 1)
  --tag-ids: list # A list of Team Tag unique ids
  --team-ids: list # A list of Team unique ids
  --to-date: string # Represents to_date and filters incidents whose creation_date is lesser than the specified to_date. example - `to_date="2023-02-01"` (default: [])
  --user-ids: list # A list of User usernames
]: any -> record<count: int, next: string, previous: string, results: table<incident_number: int, creation_date: string, status: int, unique_id: string, sla: string, service_object: record, title: string, assigned_to_name: string, tags: list, sla_object: record, team_priority_object: record, is_child_incident: bool, postmortems: list, is_parent_incident: bool, assigned_to: string, acknowledged_date: string, resolved_date: string, snooze_time: string, snoozed_till: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/incidents/filter/" $qp)
  let body = {all_teams: $all_teams, escalation_policy_ids: $escalation_policy_ids, from_date: $from_date, postmortem_filter: $postmortem_filter, priority_ids: $priority_ids, priority_name: $priority_name, service_ids: $service_ids, sla_ids: $sla_ids, status: $status, tag_ids: $tag_ids, team_ids: $team_ids, to_date: $to_date, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create the Incident object
#
# POST /api/incidents/
export def "incidents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --summary: string # A string that represents the Incident object's summary
  --status: int # An integer that represents the Incident object's status. 1 is triggered, 2 is acknowledged and 3 is resolved (default: 1)
  title: string # A string that represents the Incident object's title
  service: string # A system-generated string that represents the Service object's unique_id
  --assigned-to: string # A system-generated string that represents the User object's username
  --escalation-policy: string # A system-generated string that represents the Escalation Policy object's unique_id
  --sla: string # A system-generated string that represents the SLA object's unique_id
  --team-priority: string # A system-generated string that represents the Priority object's unique_id
]: any -> record<summary: string, incident_number: int, creation_date: string, status: int, unique_id: string, service_object: record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, collation_time: int, collation: int, under_maintenance: bool>, title: string, incident_key: string, service: string, urgency: int, merged_with: int, assigned_to: string, escalation_policy: string, escalation_policy_object: record<unique_id: string, name: string>, assigned_to_name: string, resolved_date: string, acknowledged_date: string, context_window_start: string, context_window_end: string, tags: table<unique_id: string, incident: int, creation_date: string, name: string, color: string, tag_id: string, team_tag: string>, sla: string, sla_object: record<unique_id: string, name: string, is_active: bool, acknowledge_time: int, resolve_time: int, creation_date: string>, team_priority: string, team_priority_object: record<unique_id: string, name: string, description: string, color: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/incidents/")
  let body = {summary: $summary, status: $status, title: $title, service: $service, assigned_to: $assigned_to, escalation_policy: $escalation_policy, sla: $sla, team_priority: $team_priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the Incident object
#
# PATCH /api/incidents/{unique_id}/
export def "incidents patch" [
  unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --summary: string # A string that represents the Incident object's summary
  --status: int # An integer that represents the Incident object's status. 1 is triggered, 2 is acknowledged and 3 is resolved (default: 1)
  --title: string # A string that represents the Incident object's title
  --assigned-to: string # A system-generated string that represents the User object's username
  --escalation-policy: string # A system-generated string that represents the Escalation Policy object's unique_id
  --sla: string # A system-generated string that represents the SLA object's unique_id
  --team-priority: string # A system-generated string that represents the Priority object's unique_id
  --urgency: int # An integer that represents the Incident object's urgency field. 1 is for high urgency incidents and 0 is for low urgency incidents.
]: any -> record<summary: string, incident_number: int, creation_date: string, status: int, unique_id: string, service_object: record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, collation_time: int, collation: int, under_maintenance: bool>, title: string, incident_key: string, service: string, urgency: int, merged_with: int, assigned_to: string, escalation_policy: string, escalation_policy_object: record<unique_id: string, name: string>, assigned_to_name: string, resolved_date: string, acknowledged_date: string, context_window_start: string, context_window_end: string, tags: table<unique_id: string, incident: int, creation_date: string, name: string, color: string, tag_id: string, team_tag: string>, sla: string, sla_object: record<unique_id: string, name: string, is_active: bool, acknowledge_time: int, resolve_time: int, creation_date: string>, team_priority: string, team_priority_object: record<unique_id: string, name: string, description: string, color: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($unique_id)/")
  let body = {summary: $summary, status: $status, title: $title, assigned_to: $assigned_to, escalation_policy: $escalation_policy, sla: $sla, team_priority: $team_priority, urgency: $urgency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the Incident object
#
# GET /api/incidents/{incident_number}/
export def "incidents get" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<summary: string, incident_number: int, creation_date: string, status: int, unique_id: string, service_object: record<name: string, creation_date: string, summary: string, description: string, unique_id: string, auto_resolve_timeout: int, created_by: string, team_priority: string, task_template: string, acknowlegement_timeout: int, status: int, escalation_policy: string, team: string, sla: string, collation_time: int, collation: int, under_maintenance: bool>, title: string, incident_key: string, service: string, urgency: int, merged_with: int, assigned_to: string, escalation_policy: string, escalation_policy_object: record<unique_id: string, name: string>, assigned_to_name: string, resolved_date: string, acknowledged_date: string, context_window_start: string, context_window_end: string, tags: table<unique_id: string, incident: int, creation_date: string, name: string, color: string, tag_id: string, team_tag: string>, sla: string, sla_object: record<unique_id: string, name: string, is_active: bool, acknowledge_time: int, resolve_time: int, creation_date: string>, team_priority: string, team_priority_object: record<unique_id: string, name: string, description: string, color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Incident Role object
#
# POST /api/account/teams/{}/roles/
export def "account-teams-roles post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  title: string # An arbitary string that represents the Incident Role object's title
  --description: string # An arbitary string that represents the Incident Role object's description
  --rank: int # An integer that represents the Incident Role object's rank (default: 1)
]: any -> record<unique_id: string, title: string, description: string, creation_date: string, rank: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/roles/")
  let body = {title: $title, description: $description, rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Incident Role objects
#
# GET /api/account/teams/{}/roles/
export def "account-teams-roles list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, title: string, description: string, creation_date: string, rank: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/roles/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Incident Role object
#
# GET /api/account/teams/{team_id}/roles/{incident_role_id}/
export def "account-teams-roles get" [
  team_id: string
  incident_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, title: string, description: string, creation_date: string, rank: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/roles/($incident_role_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Incident Role object
#
# PUT /api/account/teams/{team_id}/roles/{incident_role_id}/
export def "account-teams-roles put" [
  team_id: string
  incident_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  title: string # An arbitary string that represents the Incident Role object's title
  --description: string # An arbitary string that represents the Incident Role object's description
  --rank: int # An integer that represents the Incident Role object's rank (default: 1)
]: any -> record<unique_id: string, title: string, description: string, creation_date: string, rank: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/roles/($incident_role_id)/")
  let body = {title: $title, description: $description, rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Incident Role object
#
# DELETE /api/account/teams/{team_id}/roles/{incident_role_id}/
export def "account-teams-roles delete" [
  team_id: string
  incident_role_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/roles/($incident_role_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Incident Note object
#
# POST /api/incidents/{incident_number}/note/
export def "incidents-note post" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --note: string # A string that represents the Incident Note object's note data
]: any -> record<unique_id: string, incident: int, user: string, note: string, user_name: string, creation_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/note/")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Incident Note objects
#
# GET /api/incidents/{incident_number}/note/
export def "incidents-note list" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, incident: int, user: string, note: string, user_name: string, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/note/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Incident Note object
#
# GET /api/incidents/{incident_number}/note/{note_unique_id}/
export def "incidents-note get" [
  incident_number: string
  note_unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, incident: int, user: string, note: string, user_name: string, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/note/($note_unique_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Incident Note object
#
# PUT /api/incidents/{incident_number}/note/{note_unique_id}/
export def "incidents-note put" [
  incident_number: string
  note_unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --note: string # A string that represents the Incident Note object's note data
]: any -> record<unique_id: string, incident: int, user: string, note: string, user_name: string, creation_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/note/($note_unique_id)/")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Incident Note object
#
# DELETE /api/incidents/{incident_number}/note/{note_unique_id}/
export def "incidents-note delete" [
  incident_number: string
  note_unique_id: string
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
  let full_url = (build-url $base $"/api/incidents/($incident_number)/note/($note_unique_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Incident Tag object
#
# POST /api/incidents/{incident_number}/tags/
export def "incidents-tags post" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-tag: string # A system-generated string that represents the Team Tag object's unique_id
]: any -> record<unique_id: string, incident: int, creation_date: string, name: string, color: string, tag_id: string, team_tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/tags/")
  let body = {team_tag: $team_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Incident Tag objects
#
# GET /api/incidents/{incident_number}/tags/
export def "incidents-tags list" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, incident: int, creation_date: string, name: string, color: string, tag_id: string, team_tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/tags/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Incident Tag object
#
# GET /api/incidents/{incident_number}/tags/{tag_unique_id}/
export def "incidents-tags get" [
  incident_number: string
  tag_unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, incident: int, creation_date: string, name: string, color: string, tag_id: string, team_tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/tags/($tag_unique_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the Incident Tag object
#
# DELETE /api/incidents/{incident_number}/tags/{tag_unique_id}/
export def "incidents-tags delete" [
  incident_number: string
  tag_unique_id: string
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
  let full_url = (build-url $base $"/api/incidents/($incident_number)/tags/($tag_unique_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Event object
#
# POST /api/events/{integration_key}/
# DEPRECATED
@deprecated
export def "events post" [
  integration_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  message: string # A string that represents the Event object's message
  --summary: string # A string that represents the Event object's summary
  alert_type: string # A pre-defined string that represents the Event object's alert_type. Choices - `critical`, `acknowledged`, `resolved`, `error`, `warning`, `info`. (default: info)
  --entity-id: string # A unique id for the alert. If not provided, the Zenduty API will create one.
  --payload: record # A JSON payload containing additional information about the alert.
  --urls: list # An array containing JSON schema of urls related to alerts.
]: any -> record<integration_object: record<name: string, creation_date: string, summary: string, unique_id: string, service: string, team: string, integration_key: string, is_enabled: bool, integration_type: int>, summary: string, incident: int, creation_date: string, message: string, integration: string, suppressed: bool, entity_id: string, payload: record, alert_type: int, unique_id: string, images: table<image_src: string, image_url: string, image_text: string>, urls: table<link_url: string, link_text: string>, notes: table<note_title: string, note_text: string>, incident_created: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/events/($integration_key)/")
  let body = {message: $message, summary: $summary, alert_type: $alert_type, entity_id: $entity_id, payload: $payload, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create the Event object
#
# POST /integration/{account_id}/generic/{integration_key}/
# --stakeholders shape: {users?: list, teams?: list, emails?: list}
# --stakeholders_comms shape: {subject?: string, body?: string, timezone?: string, created_by?: string}
export def "integration-generic post" [
  account_id: string
  integration_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  message: string # A string that represents the Event object's message
  --summary: string # A string that represents the Event object's summary
  alert_type: string # A pre-defined string that represents the Event object's alert_type. Choices - `critical`, `acknowledged`, `resolved`, `error`, `warning`, `info`. (default: info)
  --entity-id: string # A unique id for the alert. If not provided, the Zenduty API will create one.
  --payload: record # A JSON payload containing additional information about the alert.
  --urls: list # An array containing JSON schema of urls related to alerts.
  --sla: string # A unique id for the SLA object. If not provided or provided invalid unique_id, the Zenduty will ignore the provided value.
  --escalation-policy: string # A unique id for the alert. If not provided or provided invalid unique_id, the Zenduty will ignore the provided value.
  --priority: string # A unique id for the alert. If not provided or provided invalid unique_id, the Zenduty will ignore the provided value.
  --tags: list # An array containing unique_id for the tag objects.
  --stakeholders: record # Incident stakeholder object schema — shape: {users?: list, teams?: list, emails?: list}
  --stakeholders-comms: record # Stakeholder message object schema — shape: {subject?: string, body?: string, timezone?: string, created_by?: string}
]: any -> record<message: string, trace_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://events.zenduty.com")
  let full_url = (build-url $base $"/integration/($account_id)/generic/($integration_key)/")
  let body = {message: $message, summary: $summary, alert_type: $alert_type, entity_id: $entity_id, payload: $payload, urls: $urls, sla: $sla, escalation_policy: $escalation_policy, priority: $priority, tags: $tags, stakeholders: $stakeholders, stakeholders_comms: $stakeholders_comms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the status of an Alert
#
# GET /api/alert/status/{trace_id}/
export def "alert-status get" [
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<status: string, alert: string, integration: record<name: string>, incident: record<incident_number: int, unique_id: string>, is_incident_created: bool, suppressed: bool, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://events.zenduty.com")
  let full_url = (build-url $base $"/api/alert/status/($trace_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Incident Alert objects
#
# GET /api/incidents/{incident_number}/alerts/
export def "incidents-alerts get" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<integration_object: record<name: string, creation_date: string, summary: string, unique_id: string, service: string, application: string, application_reference: record<name: string, icon_url: string, summary: string, description: string, unique_id: string, availability_plan_id: int, setup_instructions: string, extension: string, application_type: int, categories: string, documentation_link: string>, integration_key: string, created_by: string, is_enabled: bool, create_incidents_for: int, integration_type: int, default_urgency: int, webhook_url: string>, summary: string, incident: int, creation_date: string, message: string, integration: string, suppressed: bool, entity_id: string, alert_type: int, unique_id: string, images: table<image_src: string, image_url: string, image_text: string>, urls: table<link_url: string, link_text: string>, notes: table<note_title: string, note_text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/alerts/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Tag object
#
# POST /api/account/teams/{}/tags/
export def "account-teams-tags post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Tag object's name
  --color: string # A string that represents the Tag object's color
]: any -> record<unique_id: string, name: string, creation_date: string, color: string, team: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/tags/")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Tag objects
#
# GET /api/account/teams/{}/tags/
export def "account-teams-tags list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, name: string, creation_date: string, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/tags/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Tag object
#
# GET /api/account/teams/{team_id}/tags/{tag_id}/
export def "account-teams-tags get" [
  team_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, name: string, creation_date: string, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/tags/($tag_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Tag object
#
# PUT /api/account/teams/{team_id}/tags/{tag_id}/
export def "account-teams-tags put" [
  team_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Tag object's name
  --color: string # A string that represents the Tag object's color
]: any -> record<unique_id: string, name: string, creation_date: string, color: string, team: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/tags/($tag_id)/")
  let body = {name: $name, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Tag object
#
# DELETE /api/account/teams/{team_id}/tags/{tag_id}/
export def "account-teams-tags delete" [
  team_id: string
  tag_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/tags/($tag_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Task Template object
#
# POST /api/account/teams/{}/task_templates/
export def "account-teams-task-templates post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the Task Template object's name
  --summary: string # A string that represents the Task Template object's summary
  --due-immediately: int # An integer that represents whether the Task Template object is due immediately or not. 0 is false and 1 is true. (default: 0)
]: any -> record<unique_id: string, name: string, creation_date: string, summary: string, due_immediately: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/task_templates/")
  let body = {name: $name, summary: $summary, due_immediately: $due_immediately} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Task Template objects
#
# GET /api/account/teams/{}/task_templates/
export def "account-teams-task-templates list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, name: string, creation_date: string, summary: string, due_immediately: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/task_templates/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Task Template object
#
# GET /api/account/teams/{team_id}/task_templates/{task_template_id}/
export def "account-teams-task-templates get" [
  team_id: string
  task_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, name: string, creation_date: string, summary: string, due_immediately: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/task_templates/($task_template_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Task Template object
#
# PUT /api/account/teams/{team_id}/task_templates/{task_template_id}/
export def "account-teams-task-templates put" [
  team_id: string
  task_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A string that represents the Task Template object's name
  --summary: string # A string that represents the Task Template object's summary
  --due-immediately: int # An integer that represents whether the Task Template object is due immediately or not. 0 is false and 1 is true. (default: 0)
]: any -> record<unique_id: string, name: string, creation_date: string, summary: string, due_immediately: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/task_templates/($task_template_id)/")
  let body = {name: $name, summary: $summary, due_immediately: $due_immediately} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Task Template object
#
# DELETE /api/account/teams/{team_id}/task_templates/{task_template_id}/
export def "account-teams-task-templates delete" [
  team_id: string
  task_template_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/task_templates/($task_template_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Priority object
#
# POST /api/account/teams/{}/priority/
export def "account-teams-priority post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Priority object's name
  --description: string # A string that represents the Priority object's description
  --color: string # A string that represents the Priority object's color
]: any -> record<unique_id: string, description: string, name: string, creation_date: string, color: string, team: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/priority/")
  let body = {name: $name, description: $description, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Priority objects
#
# GET /api/account/teams/{}/priority/
export def "account-teams-priority list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, description: string, name: string, creation_date: string, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/priority/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Priority object
#
# GET /api/account/teams/{team_id}/priority/{priority_id}/
export def "account-teams-priority get" [
  team_id: string
  priority_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, team: string, description: string, name: string, creation_date: string, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/priority/($priority_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Priority object
#
# PUT /api/account/teams/{team_id}/priority/{priority_id}/
export def "account-teams-priority put" [
  team_id: string
  priority_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Priority object's name
  --description: string # A string that represents the Priority object's description
  --color: string # A string that represents the Priority object's color
]: any -> record<unique_id: string, description: string, name: string, creation_date: string, color: string, team: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/priority/($priority_id)/")
  let body = {name: $name, description: $description, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Priority object
#
# DELETE /api/account/teams/{team_id}/priority/{priority_id}/
export def "account-teams-priority delete" [
  team_id: string
  priority_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/priority/($priority_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the SLA object
#
# POST /api/account/teams/{}/sla/
# --escalations item shape: {responder?: list, unique_id?: string, time?: int, type?: int}
export def "account-teams-sla post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # An arbitary string that represents the SLA object's name
  escalations: list # An array of SLA Escalation objects — item shape: {responder?: list, unique_id?: string, time?: int, type?: int}
  --is-active: oneof<nothing, bool> # A boolean flag that represents whether the SLA object is active or not (default: true)
  --acknowledge-time: int # An integer that represents the SLA object's acknowledge_time
  --resolve-time: int # An integer that represents the SLA object's resolve_time
]: any -> record<escalations: table<responder: list, unique_id: string, time: int, type: int>, unique_id: string, name: string, description: string, is_active: bool, conditions: record, acknowledge_time: int, resolve_time: int, team: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/sla/")
  let body = {name: $name, escalations: $escalations, is_active: $is_active, acknowledge_time: $acknowledge_time, resolve_time: $resolve_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all SLA objects
#
# GET /api/account/teams/{}/sla/
export def "account-teams-sla list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, is_active: bool, acknowledge_time: int, resolve_time: int, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/sla/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the SLA object
#
# GET /api/account/teams/{team_id}/sla/{sla_id}/
export def "account-teams-sla get" [
  team_id: string
  sla_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, is_active: bool, acknowledge_time: int, resolve_time: int, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/sla/($sla_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the SLA object
#
# PUT /api/account/teams/{team_id}/sla/{sla_id}/
# --escalations item shape: {responder?: list, unique_id?: string, time?: int, type?: int}
export def "account-teams-sla put" [
  team_id: string
  sla_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # An arbitary string that represents the SLA object's name
  escalations: list # An array of SLA Escalation objects — item shape: {responder?: list, unique_id?: string, time?: int, type?: int}
  --is-active: oneof<nothing, bool> # A boolean flag that represents whether the SLA object is active or not (default: true)
  --acknowledge-time: int # An integer that represents the SLA object's acknowledge_time
  --resolve-time: int # An integer that represents the SLA object's resolve_time
]: any -> record<escalations: table<responder: list, unique_id: string, time: int, type: int>, unique_id: string, name: string, description: string, is_active: bool, conditions: record, acknowledge_time: int, resolve_time: int, team: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/sla/($sla_id)/")
  let body = {name: $name, escalations: $escalations, is_active: $is_active, acknowledge_time: $acknowledge_time, resolve_time: $resolve_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the SLA object
#
# DELETE /api/account/teams/{team_id}/sla/{sla_id}/
export def "account-teams-sla delete" [
  team_id: string
  sla_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/sla/($sla_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Team Maintenance Mode object
#
# POST /api/account/teams/{}/maintenance/
# --services item shape: {service?: string}
export def "account-teams-maintenance post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  start_time: string # A formatted string that represents the Team Maintenance Mode object's start_time (format: date-time)
  end_time: string # A formatted string that represents the Team Maintenance Mode object's end_time (format: date-time)
  --repeat-interval: int # An integer that represents the Team Maintenance Mode object's repeat_interval (default: 0)
  services: list # Array of Service objects — item shape: {service?: string}
  --name: string # A string that represents the Team Maintenance Mode object's name
  --time-zone: string # A formatted string that represents the Team Maintenance Mode object's time_zone. You can check out the time zone list here https://timezonedb.com/time-zones (default: UTC)
  --repeat-until: string # A formatted string that represents the Team Maintenance Mode object's repeat_until (format: date-time)
]: any -> record<unique_id: string, start_time: string, end_time: string, repeat_interval: int, services: table<unique_id: string, service: string>, creation_date: string, name: string, time_zone: string, repeat_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/maintenance/")
  let body = {start_time: $start_time, end_time: $end_time, repeat_interval: $repeat_interval, services: $services, name: $name, time_zone: $time_zone, repeat_until: $repeat_until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Team Maintenance Mode objects
#
# GET /api/account/teams/{}/maintenance/
export def "account-teams-maintenance list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, start_time: string, end_time: string, repeat_interval: int, services: table<unique_id: string, service: string>, creation_date: string, name: string, time_zone: string, repeat_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/maintenance/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Team Maintenance Mode object
#
# GET /api/account/teams/{team_id}/maintenance/{maintenance_id}/
export def "account-teams-maintenance get" [
  team_id: string
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, start_time: string, end_time: string, repeat_interval: int, services: table<unique_id: string, service: string>, creation_date: string, name: string, time_zone: string, repeat_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/maintenance/($maintenance_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Team Maintenance Mode object
#
# PUT /api/account/teams/{team_id}/maintenance/{maintenance_id}/
# --services item shape: {service?: string}
export def "account-teams-maintenance put" [
  team_id: string
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  start_time: string # A formatted string that represents the Team Maintenance Mode object's start_time (format: date-time)
  end_time: string # A formatted string that represents the Team Maintenance Mode object's end_time (format: date-time)
  --repeat-interval: int # An integer that represents the Team Maintenance Mode object's repeat_interval (default: 0)
  services: list # Array of Service objects — item shape: {service?: string}
  --name: string # A string that represents the Team Maintenance Mode object's name
  --time-zone: string # A formatted string that represents the Team Maintenance Mode object's time_zone. You can check out the time zone list here https://timezonedb.com/time-zones (default: UTC)
  --repeat-until: string # A formatted string that represents the Team Maintenance Mode object's repeat_until (format: date-time)
]: any -> record<unique_id: string, start_time: string, end_time: string, repeat_interval: int, services: table<unique_id: string, service: string>, creation_date: string, name: string, time_zone: string, repeat_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/maintenance/($maintenance_id)/")
  let body = {start_time: $start_time, end_time: $end_time, repeat_interval: $repeat_interval, services: $services, name: $name, time_zone: $time_zone, repeat_until: $repeat_until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Team Maintenance Mode object
#
# DELETE /api/account/teams/{team_id}/maintenance/{maintenance_id}/
export def "account-teams-maintenance delete" [
  team_id: string
  maintenance_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/maintenance/($maintenance_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Postmortem object
#
# POST /api/account/teams/{}/postmortem/
# --incidents item shape: {incident?: record}
export def "account-teams-postmortem post" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  author: string # A system-generated string that represents the User object's username
  --status: string # A string that represents the Postmortem object's status
  --postmortem-data: string # A string that represents the Postmortem object's postmortem_data
  incidents: list # An array of Postmortem Incident objects — item shape: {incident?: record}
  --title: string # A string that represents the Postmortem object's title
  --download-status: int # An integer that represents the Postmortem object's download_status. 1 is uninitiated, 2 is initiated, 3 is finished and 4 is error (default: 0)
]: any -> record<unique_id: string, author: string, status: string, incidents: table<unique_id: string, incident: string>, author_name: string, title: string, postmortem_data: string, download_status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/postmortem/")
  let body = {author: $author, status: $status, postmortem_data: $postmortem_data, incidents: $incidents, title: $title, download_status: $download_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Postmortem objects
#
# GET /api/account/teams/{}/postmortem/
export def "account-teams-postmortem list" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, author: string, status: string, postmortem_data: string, incidents: table<unique_id: string, incident: record>, author_name: string, title: string, download_status: int, amazon_link: string, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/{}/postmortem/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Postmortem object
#
# GET /api/account/teams/{team_id}/postmortem/{postmortem_id}/
export def "account-teams-postmortem get" [
  team_id: string
  postmortem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, author: string, status: string, postmortem_data: string, incidents: table<unique_id: string, incident: record>, author_name: string, title: string, download_status: int, amazon_link: string, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/postmortem/($postmortem_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Postmortem data
#
# PUT /api/account/teams/{team_id}/postmortem/{postmortem_id}/
# --incidents item shape: {incident?: record}
export def "account-teams-postmortem put" [
  team_id: string
  postmortem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  author: string # A system-generated string that represents the User object's username
  --status: string # A string that represents the Postmortem object's status
  --postmortem-data: string # A string that represents the Postmortem object's postmortem_data
  incidents: list # An array of Postmortem Incident objects — item shape: {incident?: record}
  --title: string # A string that represents the Postmortem object's title
  --download-status: int # An integer that represents the Postmortem object's download_status. 1 is uninitiated, 2 is initiated, 3 is finished and 4 is error (default: 0)
]: any -> record<unique_id: string, author: string, status: string, incidents: table<unique_id: string, incident: string>, author_name: string, title: string, postmortem_data: string, download_status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/postmortem/($postmortem_id)/")
  let body = {author: $author, status: $status, postmortem_data: $postmortem_data, incidents: $incidents, title: $title, download_status: $download_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Postmortem data
#
# DELETE /api/account/teams/{team_id}/postmortem/{postmortem_id}/
export def "account-teams-postmortem delete" [
  team_id: string
  postmortem_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/postmortem/($postmortem_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Escalation Policy OnCall object's in a Team V1
#
# GET /api/account/teams/{team_id}/oncall/
export def "account-teams-oncall get-by-team_id" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<escalation_policy: record<name: string, summary: string, description: string, unique_id: string, repeat_policy: int, move_to_next: bool>, team: record<unique_id: string, name: string>, user: record<username: string, first_name: string, last_name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/oncall/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Escalation Policy OnCall object's in a Team V2
#
# GET /api/v2/account/teams/{team_id}/oncall/
export def "account-teams-oncall get-by-team_id-1" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, oncalls: table<ep_rule: string, position: int, delay: int, oncalls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/teams/($team_id)/oncall/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Escalation Policy OnCall object in an Escalation Policy
#
# GET /api/v2/account/teams/{team_id}/escalation_policies/{ep_id}/oncall/
export def "account-teams-escalation-policies-oncall get" [
  team_id: string
  ep_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, oncalls: table<ep_rule: string, position: int, delay: int, oncalls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/teams/($team_id)/escalation_policies/($ep_id)/oncall/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Escalation Policy OnCall object in a Service
#
# GET /api/v2/account/teams/{team_id}/services/{service_id}/oncall/
export def "account-teams-services-oncall get" [
  team_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, oncalls: table<ep_rule: string, position: int, delay: int, oncalls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/teams/($team_id)/services/($service_id)/oncall/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Global Router object
#
# POST /api/v2/account/events/router/
export def "account-events-router post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Global Router object's name
  --description: string # A string that represents the Global Router object's description
]: any -> record<unique_id: string, name: string, description: string, account: string, is_enabled: bool, integration_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/events/router/")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Global Router objects
#
# GET /api/v2/account/events/router/
export def "account-events-router list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, description: string, account: string, is_enabled: bool, integration_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/events/router/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Global Router object
#
# GET /api/v2/account/events/router/{router_id}/
export def "account-events-router get" [
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, description: string, account: string, is_enabled: bool, integration_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Global Router data
#
# PUT /api/v2/account/events/router/{router_id}/
export def "account-events-router put" [
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Global Router object's name
  --description: string # A string that represents the Global Router object's description
]: any -> record<unique_id: string, name: string, description: string, account: string, is_enabled: bool, integration_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Global Router  data
#
# DELETE /api/v2/account/events/router/{router_id}/
export def "account-events-router delete" [
  router_id: string
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
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Global Router Rule object
#
# POST /api/v2/account/events/router/{router_id}/rulesets/
# --actions item shape: {action_type?: int, integration?: string}
export def "account-events-router-rulesets post" [
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Global Router Rule object's name
  --rule-json: string # A string that represents the rule json of Global Router Rule object
  --actions: list # An array of Global Router Rule Action objects — item shape: {action_type?: int, integration?: string}
]: any -> record<unique_id: string, name: string, position: int, rule_json: string, actions: table<unique_id: string, action_type: int, service: record, team: record, integration_obj: record>, router: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/rulesets/")
  let body = {name: $name, rule_json: $rule_json, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Global Router Rule objects
#
# GET /api/v2/account/events/router/{router_id}/rulesets/
export def "account-events-router-rulesets list" [
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, position: int, rule_json: string, actions: table<unique_id: string, action_type: int, service: record, team: record, integration_obj: record>, router: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/rulesets/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Global Router Rule object
#
# PUT /api/v2/account/events/router/{router_id}/rulesets/
export def "account-events-router-rulesets put-by-router_id" [
  router_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --rule: string # A system generated string that represents the unique id of the Global Router Rule object
  --position: int # An integer that represents that position of the Global Router Rule object
]: any -> record<unique_id: string, name: string, position: int, rule_json: string, actions: table<unique_id: string, action_type: int, service: record, team: record, integration_obj: record>, router: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/rulesets/")
  let body = {rule: $rule, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the Global Router Rule object
#
# GET /api/v2/account/events/router/{router_id}/rulesets/{ruleset_id}/
export def "account-events-router-rulesets get" [
  router_id: string
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, name: string, position: int, rule_json: string, actions: table<unique_id: string, action_type: int, service: record, team: record, integration_obj: record>, router: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/rulesets/($ruleset_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Global Router Rule data
#
# PUT /api/v2/account/events/router/{router_id}/rulesets/{ruleset_id}/
# --actions item shape: {action_type?: int, integration?: string}
export def "account-events-router-rulesets put-by-router_id-ruleset_id" [
  router_id: string
  ruleset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # A string that represents the Global Router Rule object's name
  --rule-json: string # A string that represents the rule json of Global Router Rule object
  --actions: list # An array of Global Router Rule Action objects — item shape: {action_type?: int, integration?: string}
]: any -> record<unique_id: string, name: string, position: int, rule_json: string, actions: table<unique_id: string, action_type: int, service: record, team: record, integration_obj: record>, router: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/rulesets/($ruleset_id)/")
  let body = {name: $name, rule_json: $rule_json, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Global Router Rule data
#
# DELETE /api/v2/account/events/router/{router_id}/rulesets/{ruleset_id}/
export def "account-events-router-rulesets delete" [
  router_id: string
  ruleset_id: string
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
  let full_url = (build-url $base $"/api/v2/account/events/router/($router_id)/rulesets/($ruleset_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the Alert Rule object
#
# POST /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/transformers/
# --actions item shape: {action_type?: int, key?: string, value?: string, value_reference_name?: string, escalation_policy?: string, escalation_policy_name?: string, assign_to?: string, assign_to_name?: string, schedule?: string, sla?: string, team_priority?: string, task_template?: string}
export def "account-teams-services-integrations-transformers post" [
  team_id: string
  service_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # A string that represents the Alert Transformer object's description
  --actions: list # An array of Alert Transformer Action objects — item shape: {action_type?: int, key?: string, value?: string, value_reference_name?: string, escalation_policy?: string, escalation_policy_name?: string, assign_to?: string, assign_to_name?: string, schedule?: string, sla?: string, team_priority?: string, task_template?: string}
  --rule-json: string # A string that represents the all the conditions of the alert rule
]: any -> record<unique_id: string, description: string, actions: table<unique_id: string, action_type: int, key: string, value: string, value_reference_name: string, escalation_policy: string, escalation_policy_name: string, assign_to: string, assign_to_name: string, schedule: string, sla: string, team_priority: string, task_template: string>, rule_json: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/transformers/")
  let body = {description: $description, actions: $actions, rule_json: $rule_json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Alert Rules objects
#
# GET /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/transformers/
export def "account-teams-services-integrations-transformers list" [
  team_id: string
  service_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, description: string, actions: table<unique_id: string, action_type: int, key: string, value: string, value_reference_name: string, escalation_policy: string, escalation_policy_name: string, assign_to: string, assign_to_name: string, schedule: string, sla: string, team_priority: string, task_template: string>, rule_json: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/transformers/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Alert Rule object
#
# GET /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/transformers/{transformers_id}/
export def "account-teams-services-integrations-transformers get" [
  team_id: string
  service_id: string
  integration_id: string
  transformers_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, description: string, actions: table<unique_id: string, action_type: int, key: string, value: string, value_reference_name: string, escalation_policy: string, escalation_policy_name: string, assign_to: string, assign_to_name: string, schedule: string, sla: string, team_priority: string, task_template: string>, rule_json: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/transformers/($transformers_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Alert Rule data
#
# PATCH /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/transformers/{transformers_id}/
# --actions item shape: {action_type?: int, key?: string, value?: string, value_reference_name?: string, escalation_policy?: string, escalation_policy_name?: string, assign_to?: string, assign_to_name?: string, schedule?: string, sla?: string, team_priority?: string, task_template?: string}
export def "account-teams-services-integrations-transformers patch" [
  team_id: string
  service_id: string
  integration_id: string
  transformers_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # A string that represents the Alert Transformer object's description
  --actions: list # An array of Alert Transformer Action objects — item shape: {action_type?: int, key?: string, value?: string, value_reference_name?: string, escalation_policy?: string, escalation_policy_name?: string, assign_to?: string, assign_to_name?: string, schedule?: string, sla?: string, team_priority?: string, task_template?: string}
  --rule-json: string # A string that represents the all the conditions of the alert rule
]: any -> record<unique_id: string, description: string, actions: table<unique_id: string, action_type: int, key: string, value: string, value_reference_name: string, escalation_policy: string, escalation_policy_name: string, assign_to: string, assign_to_name: string, schedule: string, sla: string, team_priority: string, task_template: string>, rule_json: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/transformers/($transformers_id)/")
  let body = {description: $description, actions: $actions, rule_json: $rule_json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Alert Rule object
#
# DELETE /api/account/teams/{team_id}/services/{service_id}/integrations/{integration_id}/transformers/{transformers_id}/
export def "account-teams-services-integrations-transformers delete" [
  team_id: string
  service_id: string
  integration_id: string
  transformers_id: string
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
  let full_url = (build-url $base $"/api/account/teams/($team_id)/services/($service_id)/integrations/($integration_id)/transformers/($transformers_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Incident Responders objects
#
# GET /api/v2/incidents/{incident_number}/responders/
export def "incidents-responders list" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<count: int, next: string, previous: string, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/incidents/($incident_number)/responders/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an Incident Responder
#
# POST /api/v2/incidents/{incident_number}/responders/
export def "incidents-responders post" [
  incident_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user: string # Unique identifier of the User object
  --escalation-policy: string # Unique identifier of the Escalation Policy object
]: any -> record<unique_id: string, incident: int, user: string, user_name: string, escalation_policy: string, escalation_policy_name: string, subject: string, message: string, response_status: int, creation_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/incidents/($incident_number)/responders/")
  let body = {user: $user, escalation_policy: $escalation_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Incident Responder
#
# GET /api/incidents/{incident_number}/responders/{unique_id}/
export def "incidents-responders get" [
  incident_number: string
  unique_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<unique_id: string, incident: int, user: string, user_name: string, escalation_policy: string, escalation_policy_name: string, subject: string, message: string, response_status: int, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/incidents/($incident_number)/responders/($unique_id)/")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Incident Responder
#
# DELETE /api/incidents/{incident_number}/responders/{unique_id}/
export def "incidents-responders delete" [
  incident_number: string
  unique_id: string
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
  let full_url = (build-url $base $"/api/incidents/($incident_number)/responders/($unique_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Incident Stats
#
# POST /api/v2/account/analytics/incident_stats/
export def "account-analytics-incident-stats post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Start date in YYYY-MM-DD format (format: date, e.g. 2025-09-24)
  --to-date: string # End date in YYYY-MM-DD format (format: date, e.g. 2025-12-23)
  --team-ids: list # List of team unique_id UUIDs. Empty array means all accessible teams.
  --service-ids: list # List of service unique_id UUIDs.
  --user-ids: list # List of usernames. Use "Unassigned" to filter unassigned incidents.
  --priority-ids: list # List of team priority unique_id UUIDs.
  --sla-ids: list # List of SLA unique_id UUIDs.
  --escalation-policy-ids: list # List of escalation policy unique_id UUIDs.
  --tag-ids: list # List of team tag unique_id UUIDs.
  --urgency: any # 0 for low, 1 for high. (e.g. 1)
  --child-incident: string # Set to "exclude" to exclude merged child incidents. Any other value has no effect. (e.g. include)
  --tta: float # Time-to-acknowledge threshold in seconds. Requires tta_comparator.
  --tta-comparator: string@tta-comparator-completer # Required if tta is set.
  --ttr: float # Time-to-resolve threshold in seconds. Requires ttr_comparator. Must be >= tta if both are set.
  --ttr-comparator: string@ttr-comparator-completer # Required if ttr is set.
]: any -> record<total_incidents: int, total_triggered_incidents: int, total_acknowledged_incidents: int, total_resolved_incidents: int, user_total_incidents: int, user_triggered_incidents: int, user_acknowledged_incidents: int, user_resolved_incidents: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/analytics/incident_stats/")
  let body = {from_date: $from_date, to_date: $to_date, team_ids: $team_ids, service_ids: $service_ids, user_ids: $user_ids, priority_ids: $priority_ids, sla_ids: $sla_ids, escalation_policy_ids: $escalation_policy_ids, tag_ids: $tag_ids, urgency: $urgency, child_incident: $child_incident, tta: $tta, tta_comparator: $tta_comparator, ttr: $ttr, ttr_comparator: $ttr_comparator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Team Analytics
#
# POST /api/v2/account/analytics/team_analytics/
export def "account-analytics-team-analytics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Start date in YYYY-MM-DD format (format: date, e.g. 2025-09-24)
  --to-date: string # End date in YYYY-MM-DD format (format: date, e.g. 2025-12-23)
  --team-ids: list # List of team unique_id UUIDs. Empty array means all accessible teams.
  --service-ids: list # List of service unique_id UUIDs.
  --user-ids: list # List of usernames. Use "Unassigned" to filter unassigned incidents.
  --priority-ids: list # List of team priority unique_id UUIDs.
  --sla-ids: list # List of SLA unique_id UUIDs.
  --escalation-policy-ids: list # List of escalation policy unique_id UUIDs.
  --tag-ids: list # List of team tag unique_id UUIDs.
  --urgency: any # 0 for low, 1 for high. (e.g. 1)
  --child-incident: string # Set to "exclude" to exclude merged child incidents. Any other value has no effect. (e.g. include)
  --tta: float # Time-to-acknowledge threshold in seconds. Requires tta_comparator.
  --tta-comparator: string@tta-comparator-completer # Required if tta is set.
  --ttr: float # Time-to-resolve threshold in seconds. Requires ttr_comparator. Must be >= tta if both are set.
  --ttr-comparator: string@ttr-comparator-completer # Required if ttr is set.
]: any -> record<all_teams: record<total_incidents: int, total_acknowledged: int, total_resolved: int, mtta_seconds: float, mttr_seconds: float>, team_records: table<team: record, total_incidents: int, total_acknowledged: int, total_resolved: int, mtta_seconds: float, mttr_seconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/analytics/team_analytics/")
  let body = {from_date: $from_date, to_date: $to_date, team_ids: $team_ids, service_ids: $service_ids, user_ids: $user_ids, priority_ids: $priority_ids, sla_ids: $sla_ids, escalation_policy_ids: $escalation_policy_ids, tag_ids: $tag_ids, urgency: $urgency, child_incident: $child_incident, tta: $tta, tta_comparator: $tta_comparator, ttr: $ttr, ttr_comparator: $ttr_comparator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Service Analytics
#
# POST /api/v2/account/analytics/service_analytics/
export def "account-analytics-service-analytics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Start date in YYYY-MM-DD format (format: date, e.g. 2025-09-24)
  --to-date: string # End date in YYYY-MM-DD format (format: date, e.g. 2025-12-23)
  --team-ids: list # List of team unique_id UUIDs. Empty array means all accessible teams.
  --service-ids: list # List of service unique_id UUIDs.
  --user-ids: list # List of usernames. Use "Unassigned" to filter unassigned incidents.
  --priority-ids: list # List of team priority unique_id UUIDs.
  --sla-ids: list # List of SLA unique_id UUIDs.
  --escalation-policy-ids: list # List of escalation policy unique_id UUIDs.
  --tag-ids: list # List of team tag unique_id UUIDs.
  --urgency: any # 0 for low, 1 for high. (e.g. 1)
  --child-incident: string # Set to "exclude" to exclude merged child incidents. Any other value has no effect. (e.g. include)
  --tta: float # Time-to-acknowledge threshold in seconds. Requires tta_comparator.
  --tta-comparator: string@tta-comparator-completer # Required if tta is set.
  --ttr: float # Time-to-resolve threshold in seconds. Requires ttr_comparator. Must be >= tta if both are set.
  --ttr-comparator: string@ttr-comparator-completer # Required if ttr is set.
]: any -> record<all_services: record<total_incidents: int, total_acknowledged: int, total_resolved: int, mtta_seconds: float, mttr_seconds: float>, service_records: table<team: record, service: record, total_incidents: int, total_acknowledged: int, total_resolved: int, mtta_seconds: float, mttr_seconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/analytics/service_analytics/")
  let body = {from_date: $from_date, to_date: $to_date, team_ids: $team_ids, service_ids: $service_ids, user_ids: $user_ids, priority_ids: $priority_ids, sla_ids: $sla_ids, escalation_policy_ids: $escalation_policy_ids, tag_ids: $tag_ids, urgency: $urgency, child_incident: $child_incident, tta: $tta, tta_comparator: $tta_comparator, ttr: $ttr, ttr_comparator: $ttr_comparator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get User Analytics
#
# POST /api/v2/account/analytics/user_analytics/
export def "account-analytics-user-analytics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Start date in YYYY-MM-DD format (format: date, e.g. 2025-09-24)
  --to-date: string # End date in YYYY-MM-DD format (format: date, e.g. 2025-12-23)
  --team-ids: list # List of team unique_id UUIDs. Empty array means all accessible teams.
  --service-ids: list # List of service unique_id UUIDs.
  --user-ids: list # List of usernames. Use "Unassigned" to filter unassigned incidents.
  --priority-ids: list # List of team priority unique_id UUIDs.
  --sla-ids: list # List of SLA unique_id UUIDs.
  --escalation-policy-ids: list # List of escalation policy unique_id UUIDs.
  --tag-ids: list # List of team tag unique_id UUIDs.
  --urgency: any # 0 for low, 1 for high. (e.g. 1)
  --child-incident: string # Set to "exclude" to exclude merged child incidents. Any other value has no effect. (e.g. include)
  --tta: float # Time-to-acknowledge threshold in seconds. Requires tta_comparator.
  --tta-comparator: string@tta-comparator-completer # Required if tta is set.
  --ttr: float # Time-to-resolve threshold in seconds. Requires ttr_comparator. Must be >= tta if both are set.
  --ttr-comparator: string@ttr-comparator-completer # Required if ttr is set.
]: any -> record<all_users: record<total_incidents: int, total_acknowledged: int, total_resolved: int, mtta_seconds: float, mttr_seconds: float>, user_records: table<user: record, total_incidents: int, total_acknowledged: int, total_resolved: int, mtta_seconds: float, mttr_seconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/account/analytics/user_analytics/")
  let body = {from_date: $from_date, to_date: $to_date, team_ids: $team_ids, service_ids: $service_ids, user_ids: $user_ids, priority_ids: $priority_ids, sla_ids: $sla_ids, escalation_policy_ids: $escalation_policy_ids, tag_ids: $tag_ids, urgency: $urgency, child_incident: $child_incident, tta: $tta, tta_comparator: $tta_comparator, ttr: $ttr, ttr_comparator: $ttr_comparator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
