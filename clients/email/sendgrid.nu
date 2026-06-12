# Auto-generated client for Email Activity (beta) v1.0.0
# Source: https://api.apis.guru/v2/specs/sendgrid.com/1.0.0/openapi.json
# Auth: --token flag or $env.EMAIL_ACTIVITY_BETA_TOKEN

const BASE_URL = "http://api.sendgrid.com/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EMAIL_ACTIVITY_BETA_TOKEN | default "" }
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

def base-url-completer [] { ["http://api.sendgrid.com/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["stats_notification" "usage_limit"] }
def aggregated-by-completer [] { ["day" "month" "week"] }
def editor-completer [] { ["code" "design"] }
def sort-by-direction-completer [] { ["asc" "desc"] }
def delete-contacts-completer [] { ["false" "true"] }
def country-completer [] { ["CA" "US"] }
def file-type-completer [] { ["csv" "json"] }
def file-type-completer-1 [] { ["csv"] }
def field-type-completer [] { ["Date" "Number" "Text"] }
def send-at-completer [] { ["now"] }
def aggregated-by-completer-1 [] { ["day" "total"] }
def ab-phase-id-completer [] { ["send" "test"] }
def sort-by-metric-completer [] { ["blocks" "bounces" "clicks" "delivered" "opens" "requests" "unique_clicks" "unique_opens" "unsubscribes"] }
def generations-completer [] { ["dynamic" "legacy" "legacy,dynamic"] }
def generation-completer [] { ["dynamic" "legacy"] }
def active-completer [] { ["0" "1"] }
def status-completer [] { ["cancel" "pause"] }
def default-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-settings-activity settings-activity" } } | get name | first)
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

# Retrieve all recent access attempts
#
# GET /access_settings/activity
# operationId: GET_access_settings-activity
export def "access-settings-activity settings-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limits the number of IPs to return. (default: 20)
  --on-behalf-of: string
]: nothing -> record<result: table<allowed: bool, auth_method: string, first_at: int, ip: string, last_at: int, location: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/access_settings/activity" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove one or more IPs from the allow list
#
# DELETE /access_settings/whitelist
# operationId: DELETE_access_settings-whitelist
export def "access-settings-whitelist settings-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --ids: list # An array of the IDs of the IP address that you want to remove from your allow list.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access_settings/whitelist")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of currently allowed IPs
#
# GET /access_settings/whitelist
# operationId: GET_access_settings-whitelist
export def "access-settings-whitelist settings-whitelist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<created_at: int, id: int, ip: string, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access_settings/whitelist")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add one or more IPs to the allow list
#
# POST /access_settings/whitelist
# operationId: POST_access_settings-whitelist
# --ips item shape: {ip: string}
export def "access-settings-whitelist settings-whitelist-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  ips: list # An array containing the IP(s) you want to allow. — item shape: {ip: string}
]: any -> record<result: table<created_at: int, id: int, ip: string, updated_at: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access_settings/whitelist")
  let body = {ips: $ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a specific IP from the allowed list
#
# DELETE /access_settings/whitelist/{rule_id}
# operationId: DELETE_access_settings-whitelist-rule_id
export def "access-settings-whitelist id-by-rule_id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access_settings/whitelist/($rule_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific allowed IP
#
# GET /access_settings/whitelist/{rule_id}
# operationId: GET_access_settings-whitelist-rule_id
export def "access-settings-whitelist id-by-rule_id-1" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<created_at: int, id: int, ip: string, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access_settings/whitelist/($rule_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all alerts
#
# GET /alerts
# operationId: GET_alerts
export def "alerts alerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string
  --on-behalf-of: string
]: nothing -> table<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts")
  let extra_headers = {"Authorization": $Authorization, "on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Alert
#
# POST /alerts
# operationId: POST_alerts
export def "alerts alerts-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string
  --on-behalf-of: string
  --email-to: string # The email address the alert will be sent to. Example: test@example.com (nullable, format: email)
  --frequency: string # Required for stats_notification. How frequently the alert will be sent. Example: daily
  --percentage: int # Required for usage_alert. When this usage threshold is reached, the alert will be sent. Example: 90
  type: string@type-completer # The type of alert you want to create. Can be either usage_limit or stats_notification. Example: usage_limit
]: any -> record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts")
  let body = {email_to: $email_to, frequency: $frequency, percentage: $percentage, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an alert
#
# DELETE /alerts/{alert_id}
# operationId: DELETE_alerts-alert_id
export def "alerts id-by-alert_id" [
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($alert_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific alert
#
# GET /alerts/{alert_id}
# operationId: GET_alerts-alert_id
export def "alerts id-by-alert_id-1" [
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string
  --on-behalf-of: string
]: nothing -> record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($alert_id)")
  let extra_headers = {"Authorization": $Authorization, "on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an alert
#
# PATCH /alerts/{alert_id}
# operationId: PATCH_alerts-alert_id
export def "alerts id-by-alert_id-2" [
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --email-to: string # The new email address you want your alert to be sent to. Example: test@example.com
  --frequency: string # The new frequency at which to send the stats_notification alert. Example: monthly
  --percentage: int # The new percentage threshold at which the usage_limit alert will be sent. Example: 90
]: any -> record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($alert_id)")
  let body = {email_to: $email_to, frequency: $frequency, percentage: $percentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all API Keys belonging to the authenticated user
#
# GET /api_keys
# operationId: GET_api_keys
export def "api-keys keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
  --on-behalf-of: string
]: nothing -> record<result: table<api_key_id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api_keys" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create API keys
#
# POST /api_keys
# operationId: create-api-keys
export def "api-keys create-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  name: string # The name you will use to describe this API Key.
  --scopes: list # The individual permissions that you are giving to this API Key.
]: any -> record<api_key: string, api_key_id: string, name: string, scopes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys")
  let body = {name: $name, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete API keys
#
# DELETE /api_keys/{api_key_id}
# operationId: DELETE_api_keys-api_key_id
export def "api-keys id-by-api_key_id" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($api_key_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an existing API Key
#
# GET /api_keys/{api_key_id}
# operationId: GET_api_keys-api_key_id
export def "api-keys id-by-api_key_id-1" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<scopes: list, api_key_id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($api_key_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update API key name
#
# PATCH /api_keys/{api_key_id}
# operationId: PATCH_api_keys-api_key_id
export def "api-keys id-by-api_key_id-2" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  name: string # The new name of the API Key.
]: any -> record<api_key_id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($api_key_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update API key name and scopes
#
# PUT /api_keys/{api_key_id}
# operationId: PUT_api_keys-api_key_id
export def "api-keys id-by-api_key_id-3" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  name: string
  --scopes: list
]: any -> record<scopes: list<string>, api_key_id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($api_key_id)")
  let body = {name: $name, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all suppression groups associated with the user.
#
# GET /asm/groups
# operationId: GET_asm-groups
export def "asm-groups asm-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int
  --on-behalf-of: string
]: nothing -> table<description: string, id: float, is_default: bool, last_email_sent_at: any, name: string, unsubscribes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/asm/groups" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new suppression group
#
# POST /asm/groups
# operationId: POST_asm-groups
export def "asm-groups asm-groups-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --description: string # A brief description of your suppression group. Required when creating a group.
  --is-default: oneof<nothing, bool> # Indicates if you would like this to be your default suppression group.
  --name: string # The name of your suppression group. Required when creating a group.
]: any -> record<description: string, id: int, is_default: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asm/groups")
  let body = {description: $description, is_default: $is_default, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Suppression Group
#
# DELETE /asm/groups/{group_id}
# operationId: DELETE_asm-groups-group_id
export def "asm-groups id-by-group_id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information on a single suppression group.
#
# GET /asm/groups/{group_id}
# operationId: GET_asm-groups-group_id
export def "asm-groups id-by-group_id-1" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<description: string, is_default: bool, name: string, id: int, last_email_sent_at: string, unsubscribes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a suppression group.
#
# PATCH /asm/groups/{group_id}
# operationId: PATCH_asm-groups-group_id
export def "asm-groups id-by-group_id-2" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --description: string # A brief description of your suppression group. Required when creating a group.
  --is-default: oneof<nothing, bool> # Indicates if you would like this to be your default suppression group.
  --name: string # The name of your suppression group. Required when creating a group.
]: any -> record<description: string, id: float, is_default: bool, last_email_sent_at: any, name: string, unsubscribes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)")
  let body = {description: $description, is_default: $is_default, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all suppressions for a suppression group
#
# GET /asm/groups/{group_id}/suppressions
# operationId: GET_asm-groups-group_id-suppressions
export def "asm-groups-suppressions id-suppressions-by-group_id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)/suppressions")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add suppressions to a suppression group
#
# POST /asm/groups/{group_id}/suppressions
# operationId: POST_asm-groups-group_id-suppressions
export def "asm-groups-suppressions id-suppressions-by-group_id-1" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  recipient_emails: list # The array of email addresses to add or find.
]: any -> record<recipient_emails: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)/suppressions")
  let body = {recipient_emails: $recipient_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for suppressions within a group
#
# POST /asm/groups/{group_id}/suppressions/search
# operationId: POST_asm-groups-group_id-suppressions-search
export def "asm-groups-suppressions-search id-suppressions-search" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  recipient_emails: list # The array of email addresses to add or find.
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)/suppressions/search")
  let body = {recipient_emails: $recipient_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a suppression from a suppression group
#
# DELETE /asm/groups/{group_id}/suppressions/{email}
# operationId: DELETE_asm-groups-group_id-suppressions-email
export def "asm-groups-suppressions id-suppressions-email" [
  group_id: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/groups/($group_id)/suppressions/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all suppressions
#
# GET /asm/suppressions
# operationId: GET_asm-suppressions
export def "asm-suppressions asm-suppressions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<created_at: int, email: string, group_id: int, group_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asm/suppressions")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add recipient addresses to the global suppression group.
#
# POST /asm/suppressions/global
# operationId: POST_asm-suppressions-global
export def "asm-suppressions-global asm-suppressions-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  recipient_emails: list # The array of email addresses to add or find.
]: any -> record<recipient_emails: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asm/suppressions/global")
  let body = {recipient_emails: $recipient_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Global Suppression
#
# DELETE /asm/suppressions/global/{email}
# operationId: DELETE_asm-suppressions-global-email
export def "asm-suppressions-global asm-suppressions-global-email-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/suppressions/global/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Global Suppression
#
# GET /asm/suppressions/global/{email}
# operationId: GET_asm-suppressions-global-email
export def "asm-suppressions-global asm-suppressions-global-email-by-email-1" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<recipient_email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/suppressions/global/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all suppression groups for an email address
#
# GET /asm/suppressions/{email}
# operationId: GET_asm-suppressions-email
export def "asm-suppressions asm-suppressions-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<suppressions: table<description: string, id: int, is_default: bool, name: string, suppressed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/asm/suppressions/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve email statistics by browser.
#
# GET /browsers/stats
# operationId: GET_browsers-stats
export def "browsers-stats browsers-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --browsers: string # The browsers to get statistics for. You can include up to 10 different browsers by including this parameter multiple times.
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "browsers" $browsers "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browsers/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all Campaigns
#
# GET /campaigns
# operationId: GET_campaigns
export def "campaigns campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results you would like to receive at a time. (default: 10)
  --offset: int # The index of the first campaign to return, where 0 is the first campaign. (default: 0)
  --on-behalf-of: string
]: nothing -> record<result: table<categories: list, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list, plain_content: string, segment_ids: list, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Campaign
#
# POST /campaigns
# operationId: POST_campaigns
export def "campaigns campaigns-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --categories: list # The categories you would like associated to this campaign. (nullable)
  --custom-unsubscribe-url: string # This is the url of the custom unsubscribe page that you provide for customers to unsubscribe from your suppression groups. (nullable)
  --editor: string@editor-completer # The editor used in the UI.
  --html-content: string # The HTML of your marketing email. (nullable)
  --ip-pool: string # The pool of IPs that you would like to send this email from. (nullable)
  --list-ids: list # The IDs of the lists you are sending this campaign to. You can have both segment IDs and list IDs (nullable)
  --plain-content: string # The plain text content of your emails. (nullable)
  --segment-ids: list # The segment IDs that you are sending this list to. You can have both segment IDs and list IDs. Segments are limited to 10 segment IDs. (nullable)
  --sender-id: int # The ID of the "sender" identity that you have created. Your recipients will see this as the "from" on your marketing emails. (nullable)
  --subject: string # The subject of your campaign that your recipients will see. (nullable)
  --suppression-group-id: int # The suppression group that this marketing email belongs to, allowing recipients to opt-out of emails of this type. (nullable)
  title: string # The display title of your campaign. This will be viewable by you in the Marketing Campaigns UI.
]: any -> record<categories: list<string>, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/campaigns")
  let body = {categories: $categories, custom_unsubscribe_url: $custom_unsubscribe_url, editor: $editor, html_content: $html_content, ip_pool: $ip_pool, list_ids: $list_ids, plain_content: $plain_content, segment_ids: $segment_ids, sender_id: $sender_id, subject: $subject, suppression_group_id: $suppression_group_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Campaign
#
# DELETE /campaigns/{campaign_id}
# operationId: DELETE_campaigns-campaign_id
export def "campaigns id-by-campaign_id" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a single campaign
#
# GET /campaigns/{campaign_id}
# operationId: GET_campaigns-campaign_id
export def "campaigns id-by-campaign_id-1" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<categories: list<string>, custom_unsubscribe_url: string, html_content: string, id: int, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, status: string, subject: string, suppression_group_id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Campaign
#
# PATCH /campaigns/{campaign_id}
# operationId: PATCH_campaigns-campaign_id
export def "campaigns id-by-campaign_id-2" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  categories: list # The categories you want to tag on this campaign.
  html_content: string # The HTML content of this campaign.
  plain_content: string # The plain content of this campaign.
  subject: string # The subject line for your campaign.
  title: string # The title of the campaign.
]: any -> record<categories: list<string>, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let body = {categories: $categories, html_content: $html_content, plain_content: $plain_content, subject: $subject, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unschedule a Scheduled Campaign
#
# DELETE /campaigns/{campaign_id}/schedules
# operationId: DELETE_campaigns-campaign_id-schedules
export def "campaigns-schedules id-schedules-by-campaign_id" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/schedules")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View Scheduled Time of a Campaign
#
# GET /campaigns/{campaign_id}/schedules
# operationId: GET_campaigns-campaign_id-schedules
export def "campaigns-schedules id-schedules-by-campaign_id-1" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<send_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/schedules")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Scheduled Campaign
#
# PATCH /campaigns/{campaign_id}/schedules
# operationId: PATCH_campaigns-campaign_id-schedules
export def "campaigns-schedules id-schedules-by-campaign_id-2" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  send_at: int # format: int64
]: any -> record<id: int, send_at: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/schedules")
  let body = {send_at: $send_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule a Campaign
#
# POST /campaigns/{campaign_id}/schedules
# operationId: POST_campaigns-campaign_id-schedules
export def "campaigns-schedules id-schedules-by-campaign_id-3" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  send_at: int # The unix timestamp for the date and time you would like your campaign to be sent out.
]: any -> record<id: int, send_at: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/schedules")
  let body = {send_at: $send_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a Campaign
#
# POST /campaigns/{campaign_id}/schedules/now
# operationId: POST_campaigns-campaign_id-schedules-now
export def "campaigns-schedules-now id-schedules-now" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/schedules/now")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a Test Campaign
#
# POST /campaigns/{campaign_id}/schedules/test
# operationId: POST_campaigns-campaign_id-schedules-test
export def "campaigns-schedules-test id-schedules-test" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body-to: string # The email address that should receive the test campaign. (format: email)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)/schedules/test")
  let body = {to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all categories
#
# GET /categories
# operationId: GET_categories
export def "categories categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of categories to display per page. (default: 50)
  --category: string # Allows you to perform a prefix search on this particular category.
  --offset: int # The point in the list that you would like to begin displaying results. (default: 0)
  --on-behalf-of: string
]: nothing -> table<category: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Email Statistics for Categories
#
# GET /categories/stats
# operationId: GET_categories-stats
export def "categories-stats categories-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --categories: string # The individual categories that you want to retrieve statistics for. You may include up to 10 different categories.
  --limit: int # The number of results to include. (default: 500)
  --offset: int # The number of results to skip.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve sums of email stats for each category [Needs: Stats object defined, has category ID?]
#
# GET /categories/stats/sums
# operationId: GET_categories-stats-sums
export def "categories-stats-sums categories-stats-sums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by-metric: string # The metric that you want to sort by.  Must be a single metric. (default: delivered)
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --limit: int # Limits the number of results returned. (default: 5)
  --offset: int # The point in the list to begin retrieving results. (default: 0)
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string
]: nothing -> record<date: string, stats: table<metrics: record, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by_metric" $sort_by_metric "scalar") (serialize-qp "sort_by_direction" $sort_by_direction "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories/stats/sums" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve email statistics by client type.
#
# GET /clients/stats
# operationId: GET_clients-stats
export def "clients-stats clients-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clients/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve stats by a specific client type.
#
# GET /clients/{client_type}/stats
# operationId: GET_clients-client_type-stats
export def "clients-stats type-stats" [
  client_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/clients/($client_type)/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all custom fields
#
# GET /contactdb/custom_fields
# operationId: GET_contactdb-custom_fields
export def "contactdb-custom-fields fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<custom_fields: table<name: string, type: string, id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/custom_fields")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Custom Field
#
# POST /contactdb/custom_fields
# operationId: POST_contactdb-custom_fields
export def "contactdb-custom-fields fields-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --name: string
  --type: string
]: any -> record<name: string, type: string, id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/custom_fields")
  let body = {name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Field
#
# DELETE /contactdb/custom_fields/{custom_field_id}
# operationId: DELETE_contactdb-custom_fields-custom_field_id
export def "contactdb-custom-fields id-by-custom_field_id" [
  custom_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<errors: table<field: string, help: record, message: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/custom_fields/($custom_field_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Custom Field
#
# GET /contactdb/custom_fields/{custom_field_id}
# operationId: GET_contactdb-custom_fields-custom_field_id
export def "contactdb-custom-fields id-by-custom_field_id-1" [
  custom_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<name: string, type: string, id: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/custom_fields/($custom_field_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Multiple lists
#
# DELETE /contactdb/lists
# operationId: DELETE_contactdb-lists
export def "contactdb-lists contactdb-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/lists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all lists
#
# GET /contactdb/lists
# operationId: GET_contactdb-lists
export def "contactdb-lists contactdb-lists-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<lists: table<id: int, name: string, recipient_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/lists")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a List
#
# POST /contactdb/lists
# operationId: POST_contactdb-lists
export def "contactdb-lists contactdb-lists-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  name: string
]: any -> record<id: int, name: string, recipient_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/lists")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a List
#
# DELETE /contactdb/lists/{list_id}
# operationId: DELETE_contactdb-lists-list_id
export def "contactdb-lists id-by-list_id" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-contacts: oneof<nothing, bool> # Adds the ability to delete all contacts on the list in addition to deleting the list.
  --on-behalf-of: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_contacts" $delete_contacts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/lists/($list_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single list
#
# GET /contactdb/lists/{list_id}
# operationId: GET_contactdb-lists-list_id
export def "contactdb-lists id-by-list_id-1" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: int # The ID of the list to retrieve.
  --on-behalf-of: string
]: nothing -> record<id: int, name: string, recipient_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/lists/($list_id)" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a List
#
# PATCH /contactdb/lists/{list_id}
# operationId: PATCH_contactdb-lists-list_id
export def "contactdb-lists id-by-list_id-2" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: int # The ID of the list you are updating.
  --on-behalf-of: string
  name: string # The new name for your list. 
]: any -> record<id: int, name: string, recipient_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/lists/($list_id)" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all recipients on a List
#
# GET /contactdb/lists/{list_id}/recipients
# operationId: GET_contactdb-lists-list_id-recipients
export def "contactdb-lists-recipients id-recipients-by-list_id" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of first recipient to return (must be a positive integer)
  --page-size: int # Number of recipients to return at a time (must be a positive integer between 1 and 1000)
  --list-id: int # The ID of the list whose recipients you are requesting.
  --on-behalf-of: string
]: nothing -> record<recipients: table<recipients: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "list_id" $list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/lists/($list_id)/recipients" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Multiple Recipients to a List
#
# POST /contactdb/lists/{list_id}/recipients
# operationId: POST_contactdb-lists-list_id-recipients
export def "contactdb-lists-recipients id-recipients-by-list_id-1" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/lists/($list_id)/recipients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Single Recipient from a Single List
#
# DELETE /contactdb/lists/{list_id}/recipients/{recipient_id}
# operationId: DELETE_contactdb-lists-list_id-recipients-recipient_id
export def "contactdb-lists-recipients id-by-list_id-recipient_id" [
  list_id: int
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list-id: int # The ID of the list you are taking this recipient away from.
  --recipient-id: int # The ID of the recipient to take off the list.
  --on-behalf-of: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list_id" $list_id "scalar") (serialize-qp "recipient_id" $recipient_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/lists/($list_id)/recipients/($recipient_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a Single Recipient to a List
#
# POST /contactdb/lists/{list_id}/recipients/{recipient_id}
# operationId: POST_contactdb-lists-list_id-recipients-recipient_id
export def "contactdb-lists-recipients id-by-list_id-recipient_id-1" [
  list_id: int
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/lists/($list_id)/recipients/($recipient_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Recipients
#
# DELETE /contactdb/recipients
# operationId: DELETE_contactdb-recipients
export def "contactdb-recipients contactdb-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/recipients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve recipients
#
# GET /contactdb/recipients
# operationId: GET_contactdb-recipients
export def "contactdb-recipients contactdb-recipients-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page index of first recipients to return (must be a positive integer)
  --page-size: int # Number of recipients to return at a time (must be a positive integer between 1 and 1000)
  --on-behalf-of: string
]: nothing -> record<recipients: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contactdb/recipients" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Recipient
#
# PATCH /contactdb/recipients
# operationId: PATCH_contactdb-recipients
export def "contactdb-recipients contactdb-recipients-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body: record
]: any -> record<error_count: float, error_indices: list<float>, errors: table<error_indices: list, message: string>, new_count: float, persisted_recipients: list<string>, updated_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/recipients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add recipients
#
# POST /contactdb/recipients
# operationId: POST_contactdb-recipients
export def "contactdb-recipients contactdb-recipients-3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body: record
]: any -> record<error_count: float, error_indices: list<float>, errors: table<error_indices: list, message: string>, new_count: float, persisted_recipients: list<string>, updated_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/recipients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the count of billable recipients
#
# GET /contactdb/recipients/billable_count
# operationId: GET_contactdb-recipients-billable_count
export def "contactdb-recipients-billable-count count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<recipient_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/recipients/billable_count")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Count of Recipients
#
# GET /contactdb/recipients/count
# operationId: GET_contactdb-recipients-count
export def "contactdb-recipients-count contactdb-recipients-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<recipient_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/recipients/count")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search recipients
#
# GET /contactdb/recipients/search
# operationId: GET_contactdb-recipients-search
export def "contactdb-recipients-search contactdb-recipients-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --{field-name}: string
  --on-behalf-of: string
]: nothing -> record<recipients: table<recipients: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "{field_name}" ${field_name} "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contactdb/recipients/search" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search recipients
#
# POST /contactdb/recipients/search
# operationId: POST_contactdb-recipients-search
export def "contactdb-recipients-search contactdb-recipients-search-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  conditions: list
  list_id: int # format: int32
]: any -> record<recipient_count: int, recipients: table<created_at: int, custom_fields: list, email: string, first_name: string, id: string, last_clicked: int, last_emailed: int, last_opened: int, updated_at: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/recipients/search")
  let body = {conditions: $conditions, list_id: $list_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Recipient
#
# DELETE /contactdb/recipients/{recipient_id}
# operationId: DELETE_contactdb-recipients-recipient_id
export def "contactdb-recipients id-by-recipient_id" [
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/recipients/($recipient_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a single recipient
#
# GET /contactdb/recipients/{recipient_id}
# operationId: GET_contactdb-recipients-recipient_id
export def "contactdb-recipients id-by-recipient_id-1" [
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<recipients: table<created_at: float, custom_fields: list, email: string, first_name: string, id: string, last_clicked: float, last_emailed: float, last_name: string, last_opened: float, updated_at: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/recipients/($recipient_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the lists that a recipient is on
#
# GET /contactdb/recipients/{recipient_id}/lists
# operationId: GET_contactdb-recipients-recipient_id-lists
export def "contactdb-recipients-lists id-lists" [
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<lists: table<id: int, name: string, recipient_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contactdb/recipients/($recipient_id)/lists")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve reserved fields
#
# GET /contactdb/reserved_fields
# operationId: GET_contactdb-reserved_fields
export def "contactdb-reserved-fields fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<reserved_fields: table<name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/reserved_fields")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all segments
#
# GET /contactdb/segments
# operationId: GET_contactdb-segments
export def "contactdb-segments contactdb-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<segments: table<conditions: list, list_id: int, name: string, recipient_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/segments")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Segment
#
# POST /contactdb/segments
# operationId: POST_contactdb-segments
# --conditions item shape: {and_or?: "and"|"or"|"", field: string, operator: "eq"|"ne"|"lt"|"gt"|"contains", value: string}
export def "contactdb-segments contactdb-segments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  conditions: list # The conditions for a recipient to be included in this segment. — item shape: {and_or?: "and"|"or"|"", field: string, operator: "eq"|"ne"|"lt"|"gt"|"contains", value: string}
  --list-id: int # The list id from which to make this segment. Not including this ID will mean your segment is created from the main contactdb rather than a list.
  name: string # The name of this segment.
  --recipient-count: float # The count of recipients in this list. This is not included on creation of segments.
]: any -> record<id: float, conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/segments")
  let body = {conditions: $conditions, list_id: $list_id, name: $name, recipient_count: $recipient_count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a segment
#
# DELETE /contactdb/segments/{segment_id}
# operationId: DELETE_contactdb-segments-segment_id
export def "contactdb-segments id-by-segment_id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-contacts: oneof<nothing, bool> # True to delete all contacts matching the segment in addition to deleting the segment
  --on-behalf-of: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_contacts" $delete_contacts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/segments/($segment_id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a segment
#
# GET /contactdb/segments/{segment_id}
# operationId: GET_contactdb-segments-segment_id
export def "contactdb-segments id-by-segment_id-1" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --segment-id: int # The ID of the segment you want to request.
  --on-behalf-of: string
]: nothing -> record<conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/segments/($segment_id)" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a segment
#
# PATCH /contactdb/segments/{segment_id}
# operationId: PATCH_contactdb-segments-segment_id
# --conditions item shape: {and_or?: "and"|"or"|"", field: string, operator: "eq"|"ne"|"lt"|"gt"|"contains", value: string}
export def "contactdb-segments id-by-segment_id-2" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --segment-id: string # The ID of the segment you are updating.
  --on-behalf-of: string
  --conditions: list # The conditions by which this segment should be created. — item shape: {and_or?: "and"|"or"|"", field: string, operator: "eq"|"ne"|"lt"|"gt"|"contains", value: string}
  --list-id: float # The list ID you would like this segment to be built from.
  name: string
]: any -> record<conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/segments/($segment_id)" $qp)
  let body = {conditions: $conditions, list_id: $list_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve recipients on a segment
#
# GET /contactdb/segments/{segment_id}/recipients
# operationId: GET_contactdb-segments-segment_id-recipients
export def "contactdb-segments-recipients id-recipients" [
  segment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int
  --page-size: int
  --on-behalf-of: string
]: nothing -> record<recipients: table<recipients: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contactdb/segments/($segment_id)/recipients" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Recipient Upload Status
#
# GET /contactdb/status
# operationId: GET_contactdb-status
export def "contactdb-status contactdb-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<status: table<: string, id: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contactdb/status")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Designs
#
# GET /designs
# operationId: LIST-designs
export def "designs LIST-designs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # number of results to return (default: 100)
  --page-token: string # token corresponding to a specific page of results, as provided by metadata
  --summary: oneof<nothing, bool> # set to false to return all fields (default: true)
]: nothing -> record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "summary" $summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/designs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Design
#
# POST /designs
export def "designs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --editor: string@editor-completer # The editor used in the UI.
  --name: string # The name of the new design. (default: Duplicate: <original design name>)
  html_content: string # The HTML content of the Design.
  --plain-content: string # Plain text content of the Design. (default: <generated from html_content if left empty>)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/designs")
  let body = {editor: $editor, name: $name, html_content: $html_content, plain_content: $plain_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List SendGrid Pre-built Designs
#
# GET /designs/pre-builts
# operationId: LIST-Sendgrid-Pre-built-designs
export def "designs-pre-builts LIST-Sendgrid-Pre-built-designs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # number of results to return (default: 100)
  --page-token: string # token corresponding to a specific page of results, as provided by metadata
  --summary: oneof<nothing, bool> # set to false to return all fields (default: true)
]: nothing -> record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "summary" $summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/designs/pre-builts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SendGrid Pre-built Design
#
# GET /designs/pre-builts/{id}
# operationId: GET-sendgrid-pre-built-design
export def "designs-pre-builts GET-sendgrid-pre-built-design" [
  id: string
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
  let full_url = (build-url $base $"/designs/pre-builts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate SendGrid Pre-built Design
#
# POST /designs/pre-builts/{id}
# operationId: POST-sendgrid-pre-built-design
export def "designs-pre-builts POST-sendgrid-pre-built-design" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --editor: string@editor-completer # The editor used in the UI.
  --name: string # The name of the new design. (default: Duplicate: <original design name>)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/designs/pre-builts/($id)")
  let body = {editor: $editor, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Design
#
# DELETE /designs/{id}
# operationId: DELETE-design
export def "designs DELETE-design" [
  id: string
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
  let full_url = (build-url $base $"/designs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Design
#
# GET /designs/{id}
# operationId: GET-design
export def "designs GET-design" [
  id: string
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
  let full_url = (build-url $base $"/designs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Design
#
# PATCH /designs/{id}
# operationId: PUT-design
export def "designs PUT-design" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --categories: list # The list of categories applied to the design
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --html-content: string # The HTML content of the Design.
  --name: string # Name of the Design. (default: My Design)
  --plain-content: string # Plain text content of the Design. (default: <generated from html_content if left empty>)
  --subject: string # Subject of the Design.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/designs/($id)")
  let body = {categories: $categories, generate_plain_content: $generate_plain_content, html_content: $html_content, name: $name, plain_content: $plain_content, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate Design
#
# POST /designs/{id}
# operationId: POST-design
export def "designs POST-design" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --editor: string@editor-completer # The editor used in the UI.
  --name: string # The name of the new design. (default: Duplicate: <original design name>)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/designs/($id)")
  let body = {editor: $editor, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve email statistics by device type.
#
# GET /devices/stats
# operationId: GET_devices-stats
export def "devices-stats devices-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devices/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve email statistics by country and state/province.
#
# GET /geo/stats
# operationId: GET_geo-stats
export def "geo-stats geo-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string@country-completer # The country you would like to see statistics for. Currently only supported for US and CA.
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all IP addresses
#
# GET /ips
# operationId: GET_ips
export def "ips ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # The IP address to get
  --exclude-whitelabels: oneof<nothing, bool> # Should we exclude reverse DNS records (whitelabels)?
  --limit: int # The number of IPs you want returned at the same time. (default: 10)
  --offset: int # The offset for the number of IPs that you are requesting. (default: 0)
  --subuser: string # The subuser you are requesting for.
  --sort-by-direction: string@sort-by-direction-completer # The direction to sort the results.
]: nothing -> table<assigned_at: int, ip: string, pools: list<string>, rdns: string, start_date: float, subusers: list<string>, warmup: bool, whitelabeled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "exclude_whitelabels" $exclude_whitelabels "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "subuser" $subuser "scalar") (serialize-qp "sort_by_direction" $sort_by_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add IPs
#
# POST /ips
# operationId: POST_ips
export def "ips ips-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  count: int # The amount of IPs to add to the account.
  --subusers: list # Array of usernames to be assigned a send IP.
  --warmup: oneof<nothing, bool> # Whether or not to warmup the IPs being added. (default: false)
]: any -> record<ips: table<ip: string, subusers: list>, remaining_ips: int, warmup: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips")
  let body = {count: $count, subusers: $subusers, warmup: $warmup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all assigned IPs
#
# GET /ips/assigned
# operationId: GET_ips-assigned
export def "ips-assigned ips-assigned" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<ip: string, pools: list<string>, start_date: int, warmup: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips/assigned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all IP pools
#
# GET /ips/pools
# operationId: GET_ips-pools
export def "ips-pools ips-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips/pools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an IP pool
#
# POST /ips/pools
# operationId: POST_ips-pools
export def "ips-pools ips-pools-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of your new IP pool.
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips/pools")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an IP pool
#
# DELETE /ips/pools/{pool_name}
# operationId: DELETE_ips-pools-pool_name
export def "ips-pools name-by-pool_name" [
  pool_name: string
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
  let full_url = (build-url $base $"/ips/pools/($pool_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all the IPs in a specified pool
#
# GET /ips/pools/{pool_name}
# operationId: GET_ips-pools-pool_name
export def "ips-pools name-by-pool_name-1" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ips: list<string>, pool_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ips/pools/($pool_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename an IP pool
#
# PUT /ips/pools/{pool_name}
# operationId: PUT_ips-pools-pool_name
export def "ips-pools name-by-pool_name-2" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name for your IP pool.
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ips/pools/($pool_name)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add an IP address to a pool
#
# POST /ips/pools/{pool_name}/ips
# operationId: POST_ips-pools-pool_name-ips
export def "ips-pools-ips name-ips" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # The IP address that you want to add to the named pool.
]: any -> record<ip: string, pools: list<string>, start_date: int, warmup: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ips/pools/($pool_name)/ips")
  let body = {ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an IP address from a pool
#
# DELETE /ips/pools/{pool_name}/ips/{ip}
# operationId: DELETE_ips-pools-pool_name-ips-ip
export def "ips-pools-ips name-ips-ip" [
  pool_name: string
  ip: string
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
  let full_url = (build-url $base $"/ips/pools/($pool_name)/ips/($ip)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get remaining IPs count
#
# GET /ips/remaining
# operationId: GET_ips-remaining
export def "ips-remaining ips-remaining" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: table<period: string, price_per_ip: float, remaining: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips/remaining")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all IPs currently in warmup
#
# GET /ips/warmup
# operationId: GET_ips-warmup
export def "ips-warmup ips-warmup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<ip: string, start_date: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips/warmup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start warming up an IP address
#
# POST /ips/warmup
# operationId: POST_ips-warmup
export def "ips-warmup ips-warmup-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # The IP address that you want to begin warming up.
]: any -> table<ip: string, start_date: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips/warmup")
  let body = {ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop warming up an IP address
#
# DELETE /ips/warmup/{ip_address}
# operationId: DELETE_ips-warmup-ip_address
export def "ips-warmup address-by-ip_address" [
  ip_address: string
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
  let full_url = (build-url $base $"/ips/warmup/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the warmup status for a specific IP address
#
# GET /ips/warmup/{ip_address}
# operationId: GET_ips-warmup-ip_address
export def "ips-warmup address-by-ip_address-1" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<ip: string, start_date: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ips/warmup/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all IP pools an IP address belongs to
#
# GET /ips/{ip_address}
# operationId: GET_ips-ip_address
export def "ips address" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ip: string, pools: list<string>, rdns: string, start_date: int, subusers: list<string>, warmup: bool, whitelabeled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ips/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a batch ID
#
# POST /mail/batch
# operationId: POST_mail-batch
export def "mail-batch mail-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<batch_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail/batch")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate batch ID
#
# GET /mail/batch/{batch_id}
# operationId: GET_mail-batch-batch_id
export def "mail-batch id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<batch_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mail/batch/($batch_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# v3 Mail Send
#
# POST /mail/send
# operationId: POST_mail-send
# --asm shape: {group_id: int, groups_to_display?: list}
# --attachments item shape: {content: string, content_id?: string, disposition?: "inline"|"attachment", filename: string, type?: string}
# --content item shape: {type: string, value: string}
# --from shape: {email: string, name?: string}
# --mail_settings shape: {bypass_bounce_management?: record, bypass_list_management?: record, bypass_spam_management?: record, bypass_unsubscribe_management?: record, footer?: record, sandbox_mode?: record}
# --personalizations item shape: {bcc?: list, cc?: list, custom_args?: record, dynamic_template_data?: record, from?: record, headers?: record, send_at?: int, subject?: string, substitutions?: record, to: list}
# --reply_to shape: {email: string, name?: string}
# --reply_to_list item shape: {email: string, name?: string}
# --tracking_settings shape: {click_tracking?: record, ganalytics?: record, open_tracking?: record, subscription_tracking?: record}
export def "mail-send mail-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asm: record # An object allowing you to specify how to handle unsubscribes. — shape: {group_id: int, groups_to_display?: list}
  --attachments: list # An array of objects where you can specify any attachments you want to include. — item shape: {content: string, content_id?: string, disposition?: "inline"|"attachment", filename: string, type?: string}
  --batch-id: string # An ID representing a batch of emails to be sent at the same time. Including a `batch_id` in your request allows you include this email in that batch. It also enables you to cancel or pause the delivery of that batch. For more information, see the [Cancel Scheduled Sends API](https://sendgrid.com/docs/api-reference/).
  --categories: list # An array of category names for this message. Each category name may not exceed 255 characters. 
  content: list # An array where you can specify the content of your email. You can include multiple [MIME types](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types) of content, but you must specify at least one MIME type. To include more than one MIME type, add another object to the array containing the `type` and `value` parameters. — item shape: {type: string, value: string}
  --custom-args: string # Values that are specific to the entire send that will be carried along with the email and its activity data.  Key/value pairs must be strings. Substitutions will not be made on custom arguments, so any string that is entered into this parameter will be assumed to be the custom argument that you would like to be used. This parameter is overridden by `custom_args` set at the personalizations level. Total `custom_args` size may not exceed 10,000 bytes.
  --body-from: record # e.g. {email: jane_doe@example.com, name: Jane Doe} — shape: {email: string, name?: string}
  --headers: record # An object containing key/value pairs of header names and the value to substitute for them. The key/value pairs must be strings. You must ensure these are properly encoded if they contain unicode characters. These headers cannot be one of the reserved headers.
  --ip-pool-name: string # The IP Pool that you would like to send this email from.
  --mail-settings: record # A collection of different mail settings that you can use to specify how you would like this email to be handled. — shape: {bypass_bounce_management?: record, bypass_list_management?: record, bypass_spam_management?: record, bypass_unsubscribe_management?: record, footer?: record, sandbox_mode?: record}
  personalizations: list # An array of messages and their metadata. Each object within personalizations can be thought of as an envelope - it defines who should receive an individual message and how that message should be handled. See our [Personalizations documentation](https://sendgrid.com/docs/for-developers/sending-email/personalizations/) for examples. — item shape: {bcc?: list, cc?: list, custom_args?: record, dynamic_template_data?: record, from?: record, headers?: record, send_at?: int, subject?: string, substitutions?: record, to: list}
  --reply-to: record # e.g. {email: jane_doe@example.com, name: Jane Doe} — shape: {email: string, name?: string}
  --reply-to-list: list # An array of recipients who will receive replies and/or bounces. Each object in this array must contain the recipient's email address. Each object in the array may optionally contain the recipient's name. You can either choose to use “reply_to” field or “reply_to_list” but not both. — item shape: {email: string, name?: string}
  --send-at: int # A unix timestamp allowing you to specify when you want your email to be delivered. This may be overridden by the `send_at` parameter set at the personalizations level. Delivery cannot be scheduled more than 72 hours in advance. If you have the flexibility, it's better to schedule mail for off-peak times. Most emails are scheduled and sent at the top of the hour or half hour. Scheduling email to avoid peak times — for example, scheduling at 10:53 — can result in lower deferral rates due to the reduced traffic during off-peak times.
  subject: string # The global or 'message level' subject of your email. This may be overridden by subject lines set in personalizations.
  --template-id: string # An email template ID. A template that contains a subject and content — either text or html — will override any subject and content values specified at the personalizations or message level.
  --tracking-settings: record # Settings to determine how you would like to track the metrics of how your recipients interact with your email. — shape: {click_tracking?: record, ganalytics?: record, open_tracking?: record, subscription_tracking?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail/send")
  let body = {asm: $asm, attachments: $attachments, batch_id: $batch_id, categories: $categories, content: $content, custom_args: $custom_args, from: $body_from, headers: $headers, ip_pool_name: $ip_pool_name, mail_settings: $mail_settings, personalizations: $personalizations, reply_to: $reply_to, reply_to_list: $reply_to_list, send_at: $send_at, subject: $subject, template_id: $template_id, tracking_settings: $tracking_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all mail settings
#
# GET /mail_settings
# operationId: GET_mail_settings
export def "mail-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of settings to return.
  --offset: int # Where in the list of results to begin displaying settings.
  --on-behalf-of: string
]: nothing -> record<result: table<description: string, enabled: bool, name: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mail_settings" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve address whitelist mail settings
#
# GET /mail_settings/address_whitelist
# operationId: GET_mail_settings-address_whitelist
export def "mail-settings-address-whitelist whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool, list: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/address_whitelist")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update address whitelist mail settings
#
# PATCH /mail_settings/address_whitelist
# operationId: PATCH_mail_settings-address_whitelist
export def "mail-settings-address-whitelist whitelist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # Indicates if your email address whitelist is enabled.
  --list: list # Either a single email address that you want whitelisted or a domain, for which all email addresses belonging to this domain will be whitelisted.
]: any -> record<enabled: bool, list: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/address_whitelist")
  let body = {enabled: $enabled, list: $list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve bounce purge mail settings
#
# GET /mail_settings/bounce_purge
# operationId: GET_mail_settings-bounce_purge
export def "mail-settings-bounce-purge purge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool, hard_bounces: int, soft_bounces: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/bounce_purge")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bounce purge mail settings
#
# PATCH /mail_settings/bounce_purge
# operationId: PATCH_mail_settings-bounce_purge
export def "mail-settings-bounce-purge purge-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # Indicates if the bounce purge mail setting is enabled.
  --hard-bounces: int # The number of days after which SendGrid will purge all contacts from your hard bounces suppression lists. (nullable)
  --soft-bounces: int # The number of days after which SendGrid will purge all contacts from your soft bounces suppression lists. (nullable)
]: any -> record<enabled: bool, hard_bounces: int, soft_bounces: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/bounce_purge")
  let body = {enabled: $enabled, hard_bounces: $hard_bounces, soft_bounces: $soft_bounces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve footer mail settings
#
# GET /mail_settings/footer
# operationId: GET_mail_settings-footer
export def "mail-settings-footer settings-footer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool, html_content: string, plain_content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/footer")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update footer mail settings
#
# PATCH /mail_settings/footer
# operationId: PATCH_mail_settings-footer
export def "mail-settings-footer settings-footer-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # Indicates if the Footer mail setting is currently enabled.
  --html-content: string # The custom HTML content of your email footer.
  --plain-content: string # The plain text content of your email footer.
]: any -> record<enabled: bool, html_content: string, plain_content: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/footer")
  let body = {enabled: $enabled, html_content: $html_content, plain_content: $plain_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve forward bounce mail settings
#
# GET /mail_settings/forward_bounce
# operationId: GET_mail_settings-forward_bounce
export def "mail-settings-forward-bounce bounce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<email: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/forward_bounce")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update forward bounce mail settings
#
# PATCH /mail_settings/forward_bounce
# operationId: PATCH_mail_settings-forward_bounce
export def "mail-settings-forward-bounce bounce-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --email: string # The email address that you would like your bounce reports forwarded to. (nullable)
  --enabled: oneof<nothing, bool> # Indicates if the bounce forwarding mail setting is enabled.
]: any -> record<email: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/forward_bounce")
  let body = {email: $email, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve forward spam mail settings
#
# GET /mail_settings/forward_spam
# operationId: GET_mail_settings-forward_spam
export def "mail-settings-forward-spam spam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<email: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/forward_spam")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update forward spam mail settings
#
# PATCH /mail_settings/forward_spam
# operationId: PATCH_mail_settings-forward_spam
export def "mail-settings-forward-spam spam-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --email: string # The email address where you would like the spam reports to be forwarded.
  --enabled: oneof<nothing, bool> # Indicates if the Forward Spam setting is enabled.
]: any -> record<email: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/forward_spam")
  let body = {email: $email, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve legacy template mail settings
#
# GET /mail_settings/template
# operationId: GET_mail_settings-template
export def "mail-settings-template settings-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool, html_content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/template")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template mail settings
#
# PATCH /mail_settings/template
# operationId: PATCH_mail_settings-template
export def "mail-settings-template settings-template-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # Indicates if you want to enable the legacy email template mail setting.
  --html-content: string # The new HTML content for your legacy email template.
]: any -> record<enabled: bool, html_content: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mail_settings/template")
  let body = {enabled: $enabled, html_content: $html_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve email statistics by mailbox provider.
#
# GET /mailbox_providers/stats
# operationId: GET_mailbox_providers-stats
export def "mailbox-providers-stats providers-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mailbox-providers: string # The mail box providers to get statistics for. You can include up to 10 by including this parameter multiple times.
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mailbox_providers" $mailbox_providers "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mailbox_providers/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Contacts
#
# DELETE /marketing/contacts
# operationId: DELETE_mc-contacts
export def "marketing-contacts mc-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-all-contacts: string # Must be set to `"true"` to delete all contacts.
  --ids: string # A comma-separated list of contact IDs.
]: nothing -> record<job_id: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_all_contacts" $delete_all_contacts "scalar") (serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sample Contacts
#
# GET /marketing/contacts
# operationId: GET_mc-contats
export def "marketing-contacts mc-contats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_metadata: record<self: string>, contact_count: int, result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or Update a Contact
#
# PUT /marketing/contacts
# operationId: PUT_mc-contacts
# --contacts item shape: {address_line_1?: string, address_line_2?: string, alternate_emails?: list, city?: string, country?: string, custom_fields?: record, email: string, first_name?: string, last_name?: string, postal_code?: string, state_province_region?: string}
export def "marketing-contacts mc-contacts-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  contacts: list # One or more contacts objects that you intend to upsert. The available fields for a contact, including the required `email` field are described below. — item shape: {address_line_1?: string, address_line_2?: string, alternate_emails?: list, city?: string, country?: string, custom_fields?: record, email: string, first_name?: string, last_name?: string, postal_code?: string, state_province_region?: string}
  --list-ids: list # An array of List ID strings that this contact will be added to.
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts")
  let body = {contacts: $contacts, list_ids: $list_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Batched Contacts by IDs
#
# POST /marketing/contacts/batch
# operationId: POST_marketing-contacts-batch
export def "marketing-contacts-batch marketing-contacts-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ids: list
]: any -> record<result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/batch")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Total Contact Count
#
# GET /marketing/contacts/count
# operationId: GET_mc-contacts-count
export def "marketing-contacts-count mc-contacts-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billable_breakdown: record<breakdown: record, total: int>, billable_count: int, contact_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Existing Exports
#
# GET /marketing/contacts/exports
# operationId: GET_marketing-contacts-exports
export def "marketing-contacts-exports marketing-contacts-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_metadata: record<next: string, prev: string, self: string>, result: table<_metadata: record, completed_at: string, created_at: string, expires_at: string, export_type: string, id: string, lists: list, segments: list, status: string, urls: list, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/exports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Contacts
#
# POST /marketing/contacts/exports
# operationId: POST_mc-contacts-exports
# --notifications shape: {email?: bool}
export def "marketing-contacts-exports mc-contacts-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file-type: string@file-type-completer # File type for export file. Choose from `json` or `csv`. (default: csv)
  --list-ids: list # IDs of the contact lists you want to export.
  --max-file-size: int # The maximum size of an export file in MB. Note that when this option is specified, multiple output files may be returned from the export. (default: 5000)
  --notifications: record # shape: {email?: bool}
  --segment-ids: list # IDs of the contact segments you want to export.
]: any -> record<_metadata: record<count: float, next: string, prev: string, self: string>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/exports")
  let body = {file_type: $file_type, list_ids: $list_ids, max_file_size: $max_file_size, notifications: $notifications, segment_ids: $segment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export Contacts Status
#
# GET /marketing/contacts/exports/{id}
# operationId: GET_mc-contacts-exports-id
export def "marketing-contacts-exports mc-contacts-exports-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, completed_at: string, contact_count: int, created_at: string, expires_at: string, id: string, message: string, status: string, updated_at: string, urls: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/contacts/exports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import Contacts
#
# PUT /marketing/contacts/imports
# operationId: PUT_mc-contacts-imports
export def "marketing-contacts-imports mc-contacts-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  field_mappings: list # Import file header to reserved/custom field mapping.
  file_type: string@file-type-completer-1 # Upload file type.
  --list-ids: list # All contacts will be added to each of the specified lists.
]: any -> record<job_id: string, upload_headers: table<header: string, value: string>, upload_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/imports")
  let body = {field_mappings: $field_mappings, file_type: $file_type, list_ids: $list_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import Contacts Status
#
# GET /marketing/contacts/imports/{id}
# operationId: GET_marketing-contacts-imports-id
export def "marketing-contacts-imports marketing-contacts-imports-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<finished_at: string, id: string, job_type: string, results: record<created_count: float, deleted_count: float, errored_count: float, errors_url: string, requested_count: float, updated_count: float>, started_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/contacts/imports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Contacts
#
# POST /marketing/contacts/search
# operationId: POST_mc-contacts-search
export def "marketing-contacts-search mc-contacts-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string
]: any -> record<_metadata: record<self: string>, contact_count: float, result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/search")
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Contacts by Emails
#
# POST /marketing/contacts/search/emails
# operationId: POST_marketing-contacts-search-emails
export def "marketing-contacts-search-emails marketing-contacts-search-emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  emails: list # One or more primary emails and/or alternate emails to search through your contacts for.
]: any -> record<result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/contacts/search/emails")
  let body = {emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Contact by ID
#
# GET /marketing/contacts/{id}
# operationId: GET_mc-contacts-id
export def "marketing-contacts mc-contacts-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_metadata: record<self: string>, address_line_1: string, address_line_2: string, alternate_emails: list<string>, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list<string>, phone_number: string, postal_code: string, segment_ids: list<string>, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Field Definitions
#
# GET /marketing/field_definitions
# operationId: GET_mc-field_definitions
export def "marketing-field-definitions definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_metadata: record<count: int, next: string, prev: string, self: string>, custom_fields: table<field_type: string, id: string, name: string>, reserved_fields: table<field_type: string, name: string, read_only: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/field_definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Field Definition
#
# POST /marketing/field_definitions
# operationId: POST_mc-field_definitions
export def "marketing-field-definitions definitions-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  field_type: string@field-type-completer
  name: string
]: any -> record<field_type: string, id: string, name: string, _metadata: record<count: int, next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/field_definitions")
  let body = {field_type: $field_type, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Field Definition
#
# DELETE /marketing/field_definitions/{custom_field_id}
# operationId: DELETE_mc-field_definitions-custom_field_id
export def "marketing-field-definitions id-by-custom_field_id" [
  custom_field_id: string
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
  let full_url = (build-url $base $"/marketing/field_definitions/($custom_field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Custom Field Definition
#
# PATCH /marketing/field_definitions/{custom_field_id}
# operationId: PATCH_mc-field_definitions-custom_field_id
export def "marketing-field-definitions id-by-custom_field_id-1" [
  custom_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<field_type: string, id: string, name: string, _metadata: record<count: int, next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/field_definitions/($custom_field_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Lists
#
# GET /marketing/lists
# operationId: GET_mc-lists
export def "marketing-lists mc-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: float # Maximum number of elements to return. Defaults to 100, returns 1000 max (default: 100)
  --page-token: string
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, result: table<_metadata: record, contact_count: int, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create List
#
# POST /marketing/lists
# operationId: POST_mc-lists
export def "marketing-lists mc-lists-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your name for your list
]: any -> record<_metadata: record<self: string>, contact_count: int, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/lists")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a list
#
# DELETE /marketing/lists/{id}
# operationId: DELETE_lists-id
export def "marketing-lists lists-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-contacts: oneof<nothing, bool> # Flag indicates that all contacts on the list are also to be deleted. (default: false)
]: nothing -> record<job_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_contacts" $delete_contacts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/lists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a List by ID
#
# GET /marketing/lists/{id}
# operationId: GET_mc-lists-id
export def "marketing-lists mc-lists-id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact-sample: oneof<nothing, bool> # Setting this parameter to the true  will cause the contact_sample to be returned (default: false)
]: nothing -> record<_metadata: record<self: string>, contact_count: int, id: string, name: string, contact_sample: record<_metadata: record<self: string>, address_line_1: string, address_line_2: string, alternate_emails: list<string>, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list<string>, phone_number: string, postal_code: string, segment_ids: list<string>, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_sample" $contact_sample "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/lists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update List
#
# PATCH /marketing/lists/{id}
# operationId: PATCH_mc-lists-id
export def "marketing-lists mc-lists-id-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Your name for your list.
]: any -> record<_metadata: record<self: string>, contact_count: int, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/lists/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Contacts from a List
#
# DELETE /marketing/lists/{id}/contacts
# operationId: DELETE_mc-lists-id-contacts
export def "marketing-lists-contacts mc-lists-id-contacts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact-ids: string # comma separated list of contact ids
]: nothing -> record<job_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_ids" $contact_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/lists/($id)/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get List Contact Count
#
# GET /marketing/lists/{id}/contacts/count
# operationId: GET_mc-lists-id-contacts-count
export def "marketing-lists-contacts-count mc-lists-id-contacts-count" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<billable_count: int, contact_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/lists/($id)/contacts/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get List of Segments
#
# GET /marketing/segments
# operationId: GET_marketing-segments
export def "marketing-segments marketing-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-list-ids: string # A comma separated list of list ids to be used when searching for segments with the specified parent_list_id, no more than 50 is allowed
  --no-parent-list-id: oneof<nothing, bool> # If set to `true` segments with an empty value of `parent_list_id` will be returned in the filter.  If the value is not present it defaults to 'false'. (default: false)
]: nothing -> record<results: table<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_list_ids" $parent_list_ids "scalar") (serialize-qp "no_parent_list_id" $no_parent_list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Segment
#
# POST /marketing/segments
# operationId: POST_marketing-segments
export def "marketing-segments marketing-segments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the segment.
  --parent-list-ids: list # The array of list ids to filter contacts on when building this segment. It allows only one such list id for now. We will support more in future
  query_dsl: string # SQL query which will filter contacts based on the conditions provided
  --parent-list-id: string # The id of the list if this segment is a child of a list.  This implies the query is rewritten as `(${query_dsl}) AND CONTAINS(list_ids, ${parent_list_id})` (format: uuid)
]: any -> record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/segments")
  let body = {name: $name, parent_list_ids: $parent_list_ids, query_dsl: $query_dsl, parent_list_id: $parent_list_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get List of Segments
#
# GET /marketing/segments/2.0
# operationId: GET_segments
export def "marketing-segments-20 segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-list-ids: string # A comma separated list up to 50 in size, to filter segments on.  Only segments that have any of these list ids as the parent list will be retrieved. This is different from the parameter of the same name used when creating a segment.
  --no-parent-list-id: oneof<nothing, bool> # If set to `true` segments with an empty value of `parent_list_id` will be returned in the filter.  If the value is not present it defaults to 'false'. (default: false)
]: nothing -> record<_metadata: record<count: int, next: string, prev: string, self: string>, contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_list_ids" $parent_list_ids "scalar") (serialize-qp "no_parent_list_id" $no_parent_list_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/segments/2.0" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Segment
#
# POST /marketing/segments/2.0
# operationId: POST_segments
export def "marketing-segments-20 segments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the segment.
  --parent-list-ids: list # The array of list ids to filter contacts on when building this segment. It allows only one such list id for now. We will support more in future
  query_dsl: string # SQL query which will filter contacts based on the conditions provided
]: any -> record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/segments/2.0")
  let body = {name: $name, parent_list_ids: $parent_list_ids, query_dsl: $query_dsl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete segment
#
# DELETE /marketing/segments/2.0/{segment_id}
# operationId: DELETE_segments-segment_id
export def "marketing-segments-20 id-by-segment_id" [
  segment_id: string
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
  let full_url = (build-url $base $"/marketing/segments/2.0/($segment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Segment by ID
#
# GET /marketing/segments/2.0/{segment_id}
# operationId: GET_segments-segment_id
export def "marketing-segments-20 id-by-segment_id-1" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contacts-sample: oneof<nothing, bool> # Defaults to `true`. Set to `false` to exclude the contacts_sample in the response.
]: nothing -> record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contacts_sample" $contacts_sample "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/segments/2.0/($segment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Segment
#
# PATCH /marketing/segments/2.0/{segment_id}
# operationId: PATCH_segments-segment_id
export def "marketing-segments-20 id-by-segment_id-2" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the segment.
  --query-dsl: string # SQL query which will filter contacts based on the conditions provided
]: any -> record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/segments/2.0/($segment_id)")
  let body = {name: $name, query_dsl: $query_dsl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Segments
#
# POST /marketing/segments/delete
# operationId: POST_marketing-segments-delete
export def "marketing-segments-delete marketing-segments-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: any -> record<errors: table<error: string, id: string, resources: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/segments/delete")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Segment
#
# DELETE /marketing/segments/{segment_id}
# operationId: DELETE_marketing-segments-segment_id
export def "marketing-segments id-by-segment_id" [
  segment_id: string
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
  let full_url = (build-url $base $"/marketing/segments/($segment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Segment by ID
#
# GET /marketing/segments/{segment_id}
# operationId: GET_marketing-segments-segment_id
export def "marketing-segments id-by-segment_id-1" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --query-json: oneof<nothing, bool> # Defaults to `false`.  Set to `true` to return the parsed SQL AST as a JSON object in the field `query_json`
]: nothing -> record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query_json" $query_json "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/segments/($segment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Segment
#
# PATCH /marketing/segments/{segment_id}
# operationId: PATCH_marketing-segments-segment_id
export def "marketing-segments id-by-segment_id-2" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the segment.
  --parent-list-ids: list # The array of list ids to filter contacts on when building this segment. It allows only one such list id for now. We will support more in future
  query_dsl: string # SQL query which will filter contacts based on the conditions provided
]: any -> record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/segments/($segment_id)")
  let body = {name: $name, parent_list_ids: $parent_list_ids, query_dsl: $query_dsl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Sender Identity
#
# POST /marketing/senders
# operationId: POST_marketing-senders
# --from shape: {email: string, name: string}
# --reply_to shape: {email: string, name?: string}
export def "marketing-senders marketing-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  address: string # The physical address of the sender identity.
  --address-2: string # Additional sender identity address information.
  city: string # The city of the sender identity.
  country: string # The country of the sender identity.
  --body-from: record # shape: {email: string, name: string}
  nickname: string # A nickname for the sender identity. Not used for sending.
  --reply-to: record # shape: {email: string, name?: string}
  --state: string # The state of the sender identity.
  --zip: string # The zipcode of the sender identity.
]: any -> record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/senders")
  let body = {address: $address, address_2: $address_2, city: $city, country: $country, from: $body_from, nickname: $nickname, reply_to: $reply_to, state: $state, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Single Sends
#
# DELETE /marketing/singlesends
# operationId: DELETE_marketing-singlesends
export def "marketing-singlesends marketing-singlesends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # Single Send IDs to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/singlesends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Single Sends
#
# GET /marketing/singlesends
# operationId: GET_marketing-singlesends
export def "marketing-singlesends marketing-singlesends-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int
  --page-token: string
]: nothing -> record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<abtest: record, categories: list, created_at: string, id: string, is_abtest: bool, name: string, send_at: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/singlesends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Single Send
#
# POST /marketing/singlesends
# operationId: POST_marketing-singlesends
# --email_config shape: {custom_unsubscribe_url?: string, design_id?: string, editor?: "code"|"design", generate_plain_content?: bool, html_content?: string, ip_pool?: string, plain_content?: string, sender_id?: int, subject?: string, suppression_group_id?: int}
# --send_to shape: {all?: bool, list_ids?: list, segment_ids?: list}
export def "marketing-singlesends marketing-singlesends-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --categories: list # The categories to associate with this Single Send.
  --email-config: record # shape: {custom_unsubscribe_url?: string, design_id?: string, editor?: "code"|"design", generate_plain_content?: bool, html_content?: string, ip_pool?: string, plain_content?: string, sender_id?: int, subject?: string, suppression_group_id?: int}
  name: string # The name of the Single Send.
  --send-at: string # The ISO 8601 time at which to send the Single Send — this must be set for a future time. (format: date-time)
  --send-to: record # shape: {all?: bool, list_ids?: list, segment_ids?: list}
]: any -> record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/singlesends")
  let body = {categories: $categories, email_config: $email_config, name: $name, send_at: $send_at, send_to: $send_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Categories
#
# GET /marketing/singlesends/categories
# operationId: GET_marketing-singlesends-categories
export def "marketing-singlesends-categories marketing-singlesends-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/singlesends/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Single Sends Search
#
# POST /marketing/singlesends/search
# operationId: POST_marketing-singlesends-search
export def "marketing-singlesends-search marketing-singlesends-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int
  --page-token: string
  --categories: list # categories to associate with this Single Send, match any single send that has at least one of the categories
  --name: string # leading and trailing wildcard search on name of the Single Send
  --status: list # current status of the Single Send
]: any -> record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<abtest: record, categories: list, created_at: string, id: string, is_abtest: bool, name: string, send_at: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/singlesends/search" $qp)
  let body = {categories: $categories, name: $name, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Single Send by ID
#
# DELETE /marketing/singlesends/{id}
# operationId: DELETE_marketing-singlesends-id
export def "marketing-singlesends marketing-singlesends-id-by-id" [
  id: string
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
  let full_url = (build-url $base $"/marketing/singlesends/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Single Send by ID
#
# GET /marketing/singlesends/{id}
# operationId: GET_marketing-singlesends-id
export def "marketing-singlesends marketing-singlesends-id-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/singlesends/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Single Send
#
# PATCH /marketing/singlesends/{id}
# operationId: PATCH_marketing-singlesends-id
# --email_config shape: {custom_unsubscribe_url?: string, design_id?: string, editor?: "code"|"design", generate_plain_content?: bool, html_content?: string, ip_pool?: string, plain_content?: string, sender_id?: int, subject?: string, suppression_group_id?: int}
# --send_to shape: {all?: bool, list_ids?: list, segment_ids?: list}
export def "marketing-singlesends marketing-singlesends-id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --categories: list # The categories to associate with this Single Send.
  --email-config: record # shape: {custom_unsubscribe_url?: string, design_id?: string, editor?: "code"|"design", generate_plain_content?: bool, html_content?: string, ip_pool?: string, plain_content?: string, sender_id?: int, subject?: string, suppression_group_id?: int}
  name: string # The name of the Single Send.
  --send-at: string # The ISO 8601 time at which to send the Single Send — this must be set for a future time. (format: date-time)
  --send-to: record # shape: {all?: bool, list_ids?: list, segment_ids?: list}
]: any -> record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/singlesends/($id)")
  let body = {categories: $categories, email_config: $email_config, name: $name, send_at: $send_at, send_to: $send_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate Single Send
#
# POST /marketing/singlesends/{id}
# operationId: POST_marketing-singlesends-id
export def "marketing-singlesends marketing-singlesends-id-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the duplicate Single Send. If you choose to leave the name field blank, your duplicate will be assigned the name of the Single Send it was copied from with the text 'Copy of ' prepended to it. The end of the new Single Send name, including 'Copy of ', will be trimmed if the name exceeds the character limit.
]: any -> record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/singlesends/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Single Send Schedule
#
# DELETE /marketing/singlesends/{id}/schedule
# operationId: DELETE_marketing-singlesends-id-schedule
export def "marketing-singlesends-schedule marketing-singlesends-id-schedule-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<send_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/singlesends/($id)/schedule")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule Single Send
#
# PUT /marketing/singlesends/{id}/schedule
# operationId: PUT_marketing-singlesends-id-schedule
export def "marketing-singlesends-schedule marketing-singlesends-id-schedule-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  send_at: string@send-at-completer # This is the ISO 8601 time at which to send the Single Send; must be in future, or the string "now" (format: date-time)
]: any -> record<send_at: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/marketing/singlesends/($id)/schedule")
  let body = {send_at: $send_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Automation Stats
#
# GET /marketing/stats/automations
# operationId: getall-automation-stats
export def "marketing-stats-automations getall-automation-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automation-ids: list # This endpoint returns all automation IDs if no `automation_ids` are specified.
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<aggregation: string, id: string, stats: record, step_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "automation_ids" $automation_ids "csv") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/stats/automations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Automation Stats
#
# GET /marketing/stats/automations/export
# operationId: get-automations-stats-export
export def "marketing-stats-automations-export get-automations-stats-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The IDs of Automations for which to export stats.
  --timezone: string # The [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented; i.e. `"America/Chicago"`. This parameter changes the timezone format only; it does not alter which stats are returned. (default: UTC)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/stats/automations/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Automation Stats by ID
#
# GET /marketing/stats/automations/{id}
# operationId: get-automation-stat
export def "marketing-stats-automations get-automation-stat" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-by: list # Automations can have multiple steps. Including `step_id` as a `group_by` metric allows further granularity of stats.
  --step-ids: list # Comma-separated list of `step_ids` that you want the link stats for.
  --aggregated-by: string@aggregated-by-completer-1 # Dictates how the stats are time-sliced. Currently, `"total"` and `"day"` are supported. (default: total)
  --start-date: string # Format: `YYYY-MM-DD`. If this parameter is included, the stats' start date is included in the search. (format: date, default: )
  --end-date: string # Format: `YYYY-MM-DD`.If this parameter is included, the stats' end date is included in the search. (format: date, default: )
  --timezone: string # [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented, e.g., "America/Chicago". (default: UTC)
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<aggregation: string, id: string, stats: record, step_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "csv") (serialize-qp "step_ids" $step_ids "csv") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/stats/automations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Automation Click Tracking Stats by ID
#
# GET /marketing/stats/automations/{id}/links
# operationId: get-automation-link-stat
export def "marketing-stats-automations-links get-automation-link-stat" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-by: list # Automations can have multiple steps. Including `step_id` as a `group_by` metric allows further granularity of stats.
  --step-ids: list # Comma-separated list of `step_ids` that you want the link stats for.
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<clicks: int, step_id: string, url: string, url_location: int>, total_clicks: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "csv") (serialize-qp "step_ids" $step_ids "csv") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/stats/automations/($id)/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Single Sends Stats
#
# GET /marketing/stats/singlesends
# operationId: getall-singlesend-stats
export def "marketing-stats-singlesends getall-singlesend-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --singlesend-ids: list # This endpoint returns all Single Send IDs if no IDs are included in `singlesend_ids`.
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, aggregation: string, id: string, stats: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "singlesend_ids" $singlesend_ids "csv") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/stats/singlesends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Single Send Stats
#
# GET /marketing/stats/singlesends/export
# operationId: get-singlesend-stats-export
export def "marketing-stats-singlesends-export get-singlesend-stats-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The IDs of Single Sends for which to export stats.
  --timezone: string # The [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented; i.e. `"America/Chicago"`. This parameter changes the timezone format only; it does not alter which stats are returned. (default: UTC)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketing/stats/singlesends/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Single Send Stats by ID
#
# GET /marketing/stats/singlesends/{id}
# operationId: get-singlesend-stat
export def "marketing-stats-singlesends get-singlesend-stat" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aggregated-by: string@aggregated-by-completer-1 # Dictates how the stats are time-sliced. Currently, `"total"` and `"day"` are supported. (default: total)
  --start-date: string # Format: `YYYY-MM-DD`. If this parameter is included, the stats' start date is included in the search. (format: date, default: )
  --end-date: string # Format: `YYYY-MM-DD`.If this parameter is included, the stats' end date is included in the search. (format: date, default: )
  --timezone: string # [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented, e.g., "America/Chicago". (default: UTC)
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
  --group-by: list # A/B Single Sends have multiple variation IDs and phase IDs. Including these additional fields allows further granularity of stats by these fields.
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, aggregation: string, id: string, stats: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "group_by" $group_by "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/stats/singlesends/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Single Send Click Tracking Stats by ID
#
# GET /marketing/stats/singlesends/{id}/links
# operationId: get-singlesend-link-stat
export def "marketing-stats-singlesends-links get-singlesend-link-stat" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
  --group-by: list # A/B Single Sends have multiple variation IDs and phase IDs. Including these additional fields allows further granularity of stats by these fields.
  --ab-variation-id: string # format: uuid
  --ab-phase-id: string@ab-phase-id-completer
]: nothing -> record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, clicks: int, url: string, url_location: int>, total_clicks: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "group_by" $group_by "csv") (serialize-qp "ab_variation_id" $ab_variation_id "scalar") (serialize-qp "ab_phase_id" $ab_phase_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/marketing/stats/singlesends/($id)/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a Test Marketing Email
#
# POST /marketing/test/send_email
# operationId: POST_marketing-test-send_email
export def "marketing-test-send-email email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-unsubscribe-url: string # A custom unsubscribe URL.
  emails: list # An array of email addresses you want to send the test message to.
  --from-address: string # You can either specify this address or specify a verified sender ID. (format: email)
  --sender-id: int # This ID must belong to a verified sender. Alternatively, you may supply a `from_address` email.
  --suppression-group-id: int
  template_id: string # The ID of the template that you would like to use. If you use a template that contains a subject and content (either text or HTML), then those values specified at the personalizations or message level will not be used. (format: uuid)
  --version-id-override: string #  You can override the active template with an alternative template version by passing the version ID in this field. If this field is blank, the active template version will be used. (format: uuid)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketing/test/send_email")
  let body = {custom_unsubscribe_url: $custom_unsubscribe_url, emails: $emails, from_address: $from_address, sender_id: $sender_id, suppression_group_id: $suppression_group_id, template_id: $template_id, version_id_override: $version_id_override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter all messages
#
# GET /messages
# operationId: GET-messages
export def "messages GET-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Use the query syntax  to filter your email activity.
  --limit: float # The number of messages returned. This parameter must be greater than 0 and less than or equal to 1000 (default: 10)
  --X-Query-Id: string
  --X-Cursor: string
  --Authorization: string
]: nothing -> record<messages: table<clicks_count: int, from_email: string, last_event_time: string, msg_id: string, opens_count: int, status: string, subject: string, to_email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let extra_headers = {"X-Query-Id": $X_Query_Id, "X-Cursor": $X_Cursor, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request CSV
#
# POST /messages/download
# operationId: POST_v3-messages-download
export def "messages-download v3-messages-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Uses a SQL like syntax to indicate which messages to include in the CSV
  --Authorization: string
]: nothing -> record<message: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/download" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download CSV
#
# GET /messages/download/{download_uuid}
# operationId: GET_v3-messages-download-download_uuid
export def "messages-download uuid" [
  download_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string
]: nothing -> record<csv: string, presigned_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/download/($download_uuid)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filter messages by message ID
#
# GET /messages/{msg_id}
# operationId: GET-v3-messages-msg_id
export def "messages id" [
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string
]: nothing -> record<api_key_id: string, asm_group_id: int, categories: list<string>, events: table<attempt_num: int, bounce_type: string, event_name: string, http_user_agent: string, mx_server: string, processed: string, reason: string, url: string>, from_email: string, msg_id: string, originating_ip: string, outbound_ip: string, outbound_ip_type: string, status: string, subject: string, teammate: string, template_id: string, to_email: string, unique_args: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($msg_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all partner settings.
#
# GET /partner_settings
# operationId: GET_partner_settings
export def "partner-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of settings to return per page.
  --offset: int # The paging offset.
  --on-behalf-of: string
]: nothing -> record<result: table<description: string, enabled: bool, name: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/partner_settings" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all New Relic partner settings.
#
# GET /partner_settings/new_relic
# operationId: GET_partner_settings-new_relic
export def "partner-settings-new-relic relic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enable_subuser_statistics: bool, enabled: bool, license_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner_settings/new_relic")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates New Relic partner settings.
#
# PATCH /partner_settings/new_relic
# operationId: PATCH_partner_settings-new_relic
export def "partner-settings-new-relic relic-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enable-subuser-statistics: oneof<nothing, bool> # Indicates if your subuser statistics will be sent to your New Relic Dashboard.
  --enabled: oneof<nothing, bool> # Indicates if this partner setting is enabled.
  --license-key: string # The license key for your New Relic account.
]: any -> record<enable_subuser_statistics: bool, enabled: bool, license_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner_settings/new_relic")
  let body = {enable_subuser_statistics: $enable_subuser_statistics, enabled: $enabled, license_key: $license_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of scopes for which this user has access.
#
# GET /scopes
# operationId: GET_scopes
export def "scopes scopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scopes")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve access requests
#
# GET /scopes/requests
# operationId: GET_v3-scopes-requests
export def "scopes-requests v3-scopes-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Optional field to limit the number of results returned. (default: 50)
  --offset: int # Optional beginning point in the list to retrieve from. (default: 0)
]: nothing -> table<email: string, first_name: string, id: int, last_name: string, scope_group_name: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scopes/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deny access request
#
# DELETE /scopes/requests/{request_id}
# operationId: DELETE_v3-scopes-requests-request_id
export def "scopes-requests id" [
  request_id: string
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
  let full_url = (build-url $base $"/scopes/requests/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve access request
#
# PATCH /scopes/requests/{request_id}/approve
# operationId: PATCH_v3-scopes-requests-approve-id
export def "scopes-requests-approve v3-scopes-requests-approve-id" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scope_group_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scopes/requests/($request_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Sender Identities
#
# GET /senders
# operationId: GET_v3-senders
export def "senders v3-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<address: string, address_2: string, city: string, country: string, from: record, nickname: string, reply_to: record, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Sender Identity
#
# POST /senders
# operationId: POST_senders
export def "senders senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  address: string # The physical address of the sender identity.
  --address-2: string # Additional sender identity address information.
  city: string # The city of the sender identity.
  country: string # The country of the sender identity.
  --body-from: record
  nickname: string # A nickname for the sender identity. Not used for sending.
  --reply-to: record
  --state: string # The state of the sender identity.
  --zip: string # The zipcode of the sender identity.
]: any -> record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders")
  let body = {address: $address, address_2: $address_2, city: $city, country: $country, from: $body_from, nickname: $nickname, reply_to: $reply_to, state: $state, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Sender Identity
#
# DELETE /senders/{sender_id}
# operationId: DELETE_v3-senders-sender_id
export def "senders id-by-sender_id" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($sender_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View a Sender Identity
#
# GET /senders/{sender_id}
# operationId: GET_v3-senders-sender_id
export def "senders id-by-sender_id-1" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($sender_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Sender Identity
#
# PATCH /senders/{sender_id}
# operationId: PATCH_v3-senders-sender_id
# --from shape: {email?: string, name?: string}
# --reply_to shape: {email?: string, name?: string}
export def "senders id-by-sender_id-2" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --address: string # The physical address of the sender identity.
  --address-2: string # Additional sender identity address information.
  --city: string # The city of the sender identity.
  --country: string # The country of the sender identity.
  --body-from: record # shape: {email?: string, name?: string}
  --nickname: string # A nickname for the sender identity. Not used for sending.
  --reply-to: record # shape: {email?: string, name?: string}
  --state: string # The state of the sender identity.
  --zip: string # The zipcode of the sender identity.
]: any -> record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($sender_id)")
  let body = {address: $address, address_2: $address_2, city: $city, country: $country, from: $body_from, nickname: $nickname, reply_to: $reply_to, state: $state, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resend Sender Identity Verification
#
# POST /senders/{sender_id}/resend_verification
# operationId: POST_v3-senders-sender_id-resend_verification
export def "senders-resend-verification verification" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($sender_id)/resend_verification")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SSO Certificate
#
# POST /sso/certificates
# operationId: POST_sso-certificates
export def "sso-certificates sso-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Indicates if the certificate is enabled.
  integration_id: string # An ID that matches a certificate to a specific IdP integration. This is the `id` returned by the "Get All SSO Integrations" endpoint.
  public_certificate: string # This public certificate allows SendGrid to verify that SAML requests it receives are signed by an IdP that it recognizes.
]: any -> record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/certificates")
  let body = {enabled: $enabled, integration_id: $integration_id, public_certificate: $public_certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SSO Certificate
#
# DELETE /sso/certificates/{cert_id}
# operationId: DELETE_sso-certificates-cert_id
export def "sso-certificates id-by-cert_id" [
  cert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sso/certificates/($cert_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SSO Certificate
#
# GET /sso/certificates/{cert_id}
# operationId: GET_sso-certificates-cert_id
export def "sso-certificates id-by-cert_id-1" [
  cert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sso/certificates/($cert_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SSO Certificate
#
# PATCH /sso/certificates/{cert_id}
# operationId: PATCH_sso-certificates-cert_id
export def "sso-certificates id-by-cert_id-2" [
  cert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Indicates whether or not the certificate is enabled.
  --integration-id: string # An ID that matches a certificate to a specific IdP integration.
  --public-certificate: string # This public certificate allows SendGrid to verify that SAML requests it receives are signed by an IdP that it recognizes.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sso/certificates/($cert_id)")
  let body = {enabled: $enabled, integration_id: $integration_id, public_certificate: $public_certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All SSO Integrations
#
# GET /sso/integrations
# operationId: GET_sso-integrations
export def "sso-integrations sso-integrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --si: oneof<nothing, bool> # If this parameter is set to `true`, the response will include the `completed_integration` field.
]: nothing -> table<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "si" $si "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sso/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SSO Integration
#
# POST /sso/integrations
# operationId: POST_sso-integrations
export def "sso-integrations sso-integrations-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --completed-integration: oneof<nothing, bool> # Indicates if the integration is complete.
  --enabled: oneof<nothing, bool> # Indicates if the integration is enabled.
  entity_id: string # An identifier provided by your IdP to identify Twilio SendGrid in the SAML interaction. This is called the "SAML Issuer ID" in the Twilio SendGrid UI.
  name: string # The name of your integration. This name can be anything that makes sense for your organization (eg. Twilio SendGrid)
  signin_url: string # The IdP's SAML POST endpoint. This endpoint should receive requests and initiate an SSO login flow. This is called the "Embed Link" in the Twilio SendGrid UI.
  signout_url: string # This URL is relevant only for an IdP-initiated authentication flow. If a user authenticates from their IdP, this URL will return them to their IdP when logging out.
]: any -> record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/integrations")
  let body = {completed_integration: $completed_integration, enabled: $enabled, entity_id: $entity_id, name: $name, signin_url: $signin_url, signout_url: $signout_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SSO Integration
#
# DELETE /sso/integrations/{id}
# operationId: DELETE_sso-integrations-id
export def "sso-integrations sso-integrations-id-by-id" [
  id: string
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
  let full_url = (build-url $base $"/sso/integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SSO Integration
#
# GET /sso/integrations/{id}
# operationId: GET_sso-integrations-id
export def "sso-integrations sso-integrations-id-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --si: oneof<nothing, bool> # If this parameter is set to `true`, the response will include the `completed_integration` field.
]: nothing -> record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "si" $si "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sso/integrations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SSO Integration
#
# PATCH /sso/integrations/{id}
# operationId: PATCH_sso-integrations-id
export def "sso-integrations sso-integrations-id-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --si: oneof<nothing, bool> # If this parameter is set to `true`, the response will include the `completed_integration` field.
  --completed-integration: oneof<nothing, bool> # Indicates if the integration is complete.
  --enabled: oneof<nothing, bool> # Indicates if the integration is enabled.
  entity_id: string # An identifier provided by your IdP to identify Twilio SendGrid in the SAML interaction. This is called the "SAML Issuer ID" in the Twilio SendGrid UI.
  name: string # The name of your integration. This name can be anything that makes sense for your organization (eg. Twilio SendGrid)
  signin_url: string # The IdP's SAML POST endpoint. This endpoint should receive requests and initiate an SSO login flow. This is called the "Embed Link" in the Twilio SendGrid UI.
  signout_url: string # This URL is relevant only for an IdP-initiated authentication flow. If a user authenticates from their IdP, this URL will return them to their IdP when logging out.
]: any -> record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "si" $si "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sso/integrations/($id)" $qp)
  let body = {completed_integration: $completed_integration, enabled: $enabled, entity_id: $entity_id, name: $name, signin_url: $signin_url, signout_url: $signout_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All SSO Certificates by Integration
#
# GET /sso/integrations/{integration_id}/certificates
# operationId: GET_sso-integrations-integration_id-certificates
export def "sso-integrations-certificates id-certificates" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sso/integrations/($integration_id)/certificates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create SSO Teammate
#
# POST /sso/teammates
# operationId: POST_sso-teammates
export def "sso-teammates sso-teammates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The Teammate’s email address. This email address will also function as the Teammate’s username and must match the address assigned to the user in your IdP. This address cannot be changed after the Teammate is created. (format: email)
  first_name: string # The Teammate’s first name.
  --is-admin: oneof<nothing, bool> # Indicates if the Teammate has admin permissions.
  --is-read-only: oneof<nothing, bool> # Indicates if the Teammate has read_only permissions.
  last_name: string # The Teammate’s last name.
  scopes: list # The permission scopes assigned to the Teammate.
]: any -> record<email: string, first_name: string, is_admin: bool, is_read_only: bool, last_name: string, is_sso: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/teammates")
  let body = {email: $email, first_name: $first_name, is_admin: $is_admin, is_read_only: $is_read_only, last_name: $last_name, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit an SSO Teammate
#
# PATCH /sso/teammates/{username}
# operationId: PATCH_sso-teammates-username
export def "sso-teammates sso-teammates-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --first-name: string
  --is-admin: oneof<nothing, bool>
  --last-name: string
  --scopes: list
]: any -> record<address: string, address2: string, city: string, company: string, country: string, email: string, phone: string, scopes: list<string>, state: string, user_type: string, website: string, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sso/teammates/($username)")
  let body = {first_name: $first_name, is_admin: $is_admin, last_name: $last_name, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve global email statistics
#
# GET /stats
# operationId: GET_stats
export def "stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Subusers
#
# GET /subusers
# operationId: GET_subusers
export def "subusers subusers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # The username of this subuser.
  --limit: int # The number of results you would like to get in each request.
  --offset: int # The number of subusers to skip.
]: nothing -> table<disabled: bool, email: string, id: float, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subusers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Subuser
#
# POST /subusers
# operationId: POST_subusers
export def "subusers subusers-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the subuser. (format: email)
  ips: list # The IP addresses that should be assigned to this subuser.
  password: string # The password this subuser will use when logging into SendGrid.
  username: string # The username for this subuser.
]: any -> record<authorization_token: string, credit_allocation: record<type: string>, email: string, signup_session_token: string, user_id: float, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subusers")
  let body = {email: $email, ips: $ips, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Subuser Reputations
#
# GET /subusers/reputations
# operationId: GET_subusers-reputations
export def "subusers-reputations subusers-reputations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --usernames: string
]: nothing -> table<reputation: float, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "usernames" $usernames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subusers/reputations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve email statistics for your subusers.
#
# GET /subusers/stats
# operationId: GET_subusers-stats
export def "subusers-stats subusers-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limits the number of results returned per page.
  --offset: int # The point in the list to begin retrieving results from.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --subusers: string # The subuser you want to retrieve statistics for. You may include this parameter up to 10 times to retrieve statistics for multiple subusers.
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today.
]: nothing -> record<date: string, stats: table<metrics: record, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "subusers" $subusers "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subusers/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve monthly stats for all subusers
#
# GET /subusers/stats/monthly
# operationId: GET_subusers-stats-monthly
export def "subusers-stats-monthly subusers-stats-monthly" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # The date of the month to retrieve statistics for. Must be formatted YYYY-MM-DD
  --subuser: string # A substring search of your subusers.
  --sort-by-metric: string@sort-by-metric-completer # The metric that you want to sort by. Metrics that you can sort by are: `blocks`, `bounces`, `clicks`, `delivered`, `opens`, `requests`, `unique_clicks`, `unique_opens`, and `unsubscribes`.' (default: delivered)
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --limit: int # Optional field to limit the number of results returned. (default: 5)
  --offset: int # Optional beginning point in the list to retrieve from. (default: 0)
]: nothing -> record<date: string, stats: table<first_name: string, last_name: string, metrics: record, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "subuser" $subuser "scalar") (serialize-qp "sort_by_metric" $sort_by_metric "scalar") (serialize-qp "sort_by_direction" $sort_by_direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subusers/stats/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the totals for each email statistic metric for all subusers.
#
# GET /subusers/stats/sums
# operationId: GET_subusers-stats-sums
export def "subusers-stats-sums subusers-stats-sums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort.  (default: desc)
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD.
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --limit: int # Limits the number of results returned per page. (default: 5)
  --offset: int # The point in the list to begin retrieving results from. (default: 0)
  --aggregated-by: string # How to group the statistics. Defaults to today. Must follow format YYYY-MM-DD.
  --sort-by-metric: string # The metric that you want to sort by.  Must be a single metric. (default: delivered)
]: nothing -> record<date: string, stats: table<metrics: record, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by_direction" $sort_by_direction "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "sort_by_metric" $sort_by_metric "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subusers/stats/sums" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a subuser
#
# DELETE /subusers/{subuser_name}
# operationId: DELETE_subusers-subuser_name
export def "subusers name-by-subuser_name" [
  subuser_name: string
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
  let full_url = (build-url $base $"/subusers/($subuser_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable/disable a subuser
#
# PATCH /subusers/{subuser_name}
# operationId: PATCH_subusers-subuser_name
export def "subusers name-by-subuser_name-1" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # Whether or not this subuser is disabled. True means disabled, False means enabled.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subusers/($subuser_name)")
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update IPs assigned to a subuser
#
# PUT /subusers/{subuser_name}/ips
# operationId: PUT_subusers-subuser_name-ips
export def "subusers-ips name-ips" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<ips: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subusers/($subuser_name)/ips")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete monitor settings
#
# DELETE /subusers/{subuser_name}/monitor
# operationId: DELETE_subusers-subuser_name-monitor
export def "subusers-monitor name-monitor-by-subuser_name" [
  subuser_name: string
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
  let full_url = (build-url $base $"/subusers/($subuser_name)/monitor")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve monitor settings for a subuser
#
# GET /subusers/{subuser_name}/monitor
# operationId: GET_subusers-subuser_name-monitor
export def "subusers-monitor name-monitor-by-subuser_name-1" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, frequency: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subusers/($subuser_name)/monitor")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create monitor settings
#
# POST /subusers/{subuser_name}/monitor
# operationId: POST_subusers-subuser_name-monitor
export def "subusers-monitor name-monitor-by-subuser_name-2" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address to which Sendgrid should send emails for monitoring. (format: email)
  frequency: float # The frequency at which to forward monitoring emails. An email will be sent when your subuser sends this many (e.g., 1,000) emails.
]: any -> record<email: string, frequency: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subusers/($subuser_name)/monitor")
  let body = {email: $email, frequency: $frequency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Monitor Settings for a subuser
#
# PUT /subusers/{subuser_name}/monitor
# operationId: PUT_subusers-subuser_name-monitor
export def "subusers-monitor name-monitor-by-subuser_name-3" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address to which Sendgrid should send emails for monitoring. (format: email)
  frequency: float # The frequency at which to forward monitoring emails. An email will be sent when your subuser sends this many (e.g., 1,000) emails.
]: any -> record<email: string, frequency: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subusers/($subuser_name)/monitor")
  let body = {email: $email, frequency: $frequency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the monthly email statistics for a single subuser
#
# GET /subusers/{subuser_name}/stats/monthly
# operationId: GET_subusers-subuser_name-stats-monthly
export def "subusers-stats-monthly name-stats-monthly" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # The date of the month to retrieve statistics for. Must be formatted YYYY-MM-DD
  --sort-by-metric: string # The metric that you want to sort by. Metrics that you can sort by are: `blocks`, `bounces`, `clicks`, `delivered`, `opens`, `requests`, `unique_clicks`, `unique_opens`, and `unsubscribes`.' (default: delivered)
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --limit: int # Optional field to limit the number of results returned. (default: 5)
  --offset: int # Optional beginning point in the list to retrieve from. (default: 0)
]: nothing -> record<date: string, stats: table<first_name: string, last_name: string, metrics: record, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "sort_by_metric" $sort_by_metric "scalar") (serialize-qp "sort_by_direction" $sort_by_direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subusers/($subuser_name)/stats/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete blocks
#
# DELETE /suppression/blocks
# operationId: DELETE_suppression-blocks
export def "suppression-blocks suppression-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --delete-all: oneof<nothing, bool> # Indicates if you want to delete all blocked email addresses.
  --emails: list # The specific blocked email addresses that you want to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppression/blocks")
  let body = {delete_all: $delete_all, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all blocks
#
# GET /suppression/blocks
# operationId: GET_suppression-blocks
export def "suppression-blocks suppression-blocks-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The start of the time range when a blocked email was created (inclusive). This is a unix timestamp.
  --end-time: int # The end of the time range when a blocked email was created (inclusive). This is a unix timestamp.
  --limit: int # Limit the number of results to be displayed per page.
  --offset: int # The point in the list to begin displaying results.
  --on-behalf-of: string
]: nothing -> table<created: int, email: string, reason: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppression/blocks" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific block
#
# DELETE /suppression/blocks/{email}
# operationId: DELETE_suppression-blocks-email
export def "suppression-blocks suppression-blocks-email-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/blocks/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific block
#
# GET /suppression/blocks/{email}
# operationId: GET_suppression-blocks-email
export def "suppression-blocks suppression-blocks-email-by-email-1" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<created: int, email: string, reason: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/blocks/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete bounces
#
# DELETE /suppression/bounces
# operationId: DELETE_suppression-bounces
export def "suppression-bounces suppression-bounces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --delete-all: oneof<nothing, bool> # This parameter allows you to delete **every** email in your bounce list. This should not be used with the emails parameter.
  --emails: list # Delete multiple emails from your bounce list at the same time. This should not be used with the delete_all parameter.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppression/bounces")
  let body = {delete_all: $delete_all, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all bounces
#
# GET /suppression/bounces
# operationId: GET_suppression-bounces
export def "suppression-bounces suppression-bounces-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Refers start of the time range in unix timestamp when a bounce was created (inclusive).
  --end-time: int # Refers end of the time range in unix timestamp when a bounce was created (inclusive).
  --Accept: string
  --on-behalf-of: string
]: nothing -> table<created: float, email: string, reason: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppression/bounces" $qp)
  let extra_headers = {"Accept": $Accept, "on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a bounce
#
# DELETE /suppression/bounces/{email}
# operationId: DELETE_suppression-bounces-email
export def "suppression-bounces suppression-bounces-email-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-address: string # The email address you would like to remove from the bounce list. (format: email)
  --on-behalf-of: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/suppression/bounces/($email)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Bounce
#
# GET /suppression/bounces/{email}
# operationId: GET_suppression-bounces-email
export def "suppression-bounces suppression-bounces-email-by-email-1" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<created: float, email: string, reason: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/bounces/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete invalid emails
#
# DELETE /suppression/invalid_emails
# operationId: DELETE_suppression-invalid_emails
export def "suppression-invalid-emails emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --delete-all: oneof<nothing, bool> # Indicates if you want to remove all email address from the invalid emails list.
  --emails: list # The list of specific email addresses that you want to remove.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppression/invalid_emails")
  let body = {delete_all: $delete_all, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all invalid emails
#
# GET /suppression/invalid_emails
# operationId: GET_suppression-invalid_emails
export def "suppression-invalid-emails emails-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Refers start of the time range in unix timestamp when an invalid email was created (inclusive).
  --end-time: int # Refers end of the time range in unix timestamp when an invalid email was created (inclusive).
  --limit: int # Limit the number of results to be displayed per page.
  --offset: int # Paging offset. The point in the list to begin displaying results.
  --on-behalf-of: string
]: nothing -> table<created: int, email: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppression/invalid_emails" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific invalid email
#
# DELETE /suppression/invalid_emails/{email}
# operationId: DELETE_suppression-invalid_emails-email
export def "suppression-invalid-emails emails-email-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/invalid_emails/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific invalid email
#
# GET /suppression/invalid_emails/{email}
# operationId: GET_suppression-invalid_emails-email
export def "suppression-invalid-emails emails-email-by-email-1" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<created: int, email: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/invalid_emails/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete spam reports
#
# DELETE /suppression/spam_reports
# operationId: DELETE_suppression-spam_reports
export def "suppression-spam-reports reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --delete-all: oneof<nothing, bool> # Indicates if you want to delete all email addresses on the spam report list.
  --emails: list # A list of specific email addresses that you want to remove from the spam report list.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppression/spam_reports")
  let body = {delete_all: $delete_all, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all spam reports
#
# GET /suppression/spam_reports
# operationId: GET_suppression-spam_reports
export def "suppression-spam-reports reports-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # The start of the time range when a spam report was created (inclusive). This is a unix timestamp.
  --end-time: int # The end of the time range when a spam report was created (inclusive). This is a unix timestamp.
  --limit: int # Limit the number of results to be displayed per page.
  --offset: int # Paging offset. The point in the list to begin displaying results.
  --on-behalf-of: string
]: nothing -> table<created: int, email: string, ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppression/spam_reports" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific spam report
#
# DELETE /suppression/spam_reports/{email}
# operationId: DELETE_suppression-spam_reports-email
export def "suppression-spam-reports reports-email-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/spam_reports/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific spam report
#
# GET /suppression/spam_reports/{email}
# operationId: GET_suppression-spam_reports-email
export def "suppression-spam-reports reports-email-by-email-1" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<created: int, email: string, ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppression/spam_reports/($email)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all global suppressions
#
# GET /suppression/unsubscribes
# operationId: GET_suppression-unsubscribes
export def "suppression-unsubscribes suppression-unsubscribes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Refers start of the time range in unix timestamp when an unsubscribe email was created (inclusive).
  --end-time: int # Refers end of the time range in unix timestamp when an unsubscribe email was created (inclusive).
  --limit: int # The number of results to display on each page.
  --offset: int # The point in the list of results to begin displaying global suppressions.
  --on-behalf-of: string
]: nothing -> table<created: int, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppression/unsubscribes" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all teammates
#
# GET /teammates
# operationId: GET_v3-teammates
export def "teammates v3-teammates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of items to return (default: 500)
  --offset: int # Paging offset (default: 0)
  --on-behalf-of: string
]: nothing -> record<result: table<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, state: string, user_type: string, username: string, website: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teammates" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite teammate
#
# POST /teammates
# operationId: POST_v3-teammates
export def "teammates v3-teammates-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  email: string # New teammate's email
  --is-admin: oneof<nothing, bool> # Set to true if teammate should be an admin user (default: false)
  scopes: list # Set to specify list of scopes that teammate should have. Should be empty if teammate is an admin.
]: any -> record<email: string, is_admin: bool, scopes: list<any>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teammates")
  let body = {email: $email, is_admin: $is_admin, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all pending teammates
#
# GET /teammates/pending
# operationId: GET_v3-teammates-pending
export def "teammates-pending v3-teammates-pending" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<email: string, expiration_date: int, is_admin: bool, scopes: list, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teammates/pending")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete pending teammate
#
# DELETE /teammates/pending/{token}
# operationId: DELETE_v3-teammates-pending-token
export def "teammates-pending v3-teammates-pending-token" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teammates/pending/($token)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend teammate invite
#
# POST /teammates/pending/{token}/resend
# operationId: POST_v3-teammates-pending-token-resend
export def "teammates-pending-resend v3-teammates-pending-token-resend" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<email: string, is_admin: bool, scopes: list<string>, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teammates/pending/($token)/resend")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete teammate
#
# DELETE /teammates/{username}
# operationId: DELETE_v3-teammates-username
export def "teammates v3-teammates-username-by-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teammates/($username)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve specific teammate
#
# GET /teammates/{username}
# operationId: GET_v3-teammates-username
export def "teammates v3-teammates-username-by-username-1" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, scopes: list<any>, state: string, user_type: string, username: string, website: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teammates/($username)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update teammate's permissions
#
# PATCH /teammates/{username}
# operationId: PATCH_v3-teammates-username
export def "teammates v3-teammates-username-by-username-2" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --is-admin: oneof<nothing, bool> # Set to True if this teammate should be promoted to an admin user. If True, scopes should be an empty array.
  scopes: list # Provide list of scopes that should be given to teammate. If specifying list of scopes, is_admin should be set to False.
]: any -> record<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, scopes: list<string>, state: string, user_type: string, username: string, website: string, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teammates/($username)")
  let body = {is_admin: $is_admin, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve paged transactional templates.
#
# GET /templates
# operationId: GET_templates
export def "templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --generations: string@generations-completer # Comma-delimited list specifying which generations of templates to return. Options are `legacy`, `dynamic` or `legacy,dynamic`. (default: legacy)
  --page-size: float # The number of templates to be returned in each page of results
  --page-token: string # A token corresponding to a specific page of results, as provided by metadata
  --on-behalf-of: string
]: nothing -> record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<generation: string, id: string, name: string, updated_at_: string, versions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generations" $generations "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a transactional template.
#
# POST /templates
# operationId: POST_templates
export def "templates templates-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --generation: string@generation-completer # Defines whether the template supports dynamic replacement. (default: legacy)
  name: string # The name for the new transactional template.
]: any -> record<generation: string, id: string, name: string, updated_at_: string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {generation: $generation, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template.
#
# DELETE /templates/{template_id}
# operationId: DELETE_templates-template_id
export def "templates id-by-template_id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a single transactional template.
#
# GET /templates/{template_id}
# operationId: GET_templates-template_id
export def "templates id-by-template_id-1" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<generation: string, id: string, name: string, updated_at_: string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a transactional template.
#
# PATCH /templates/{template_id}
# operationId: PATCH_templates-template_id
export def "templates id-by-template_id-2" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --name: string # The name of the transactional template.
]: any -> record<generation: string, id: string, name: string, updated_at_: string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate a transactional template.
#
# POST /templates/{template_id}
# operationId: POST_templates-template_id
export def "templates id-by-template_id-3" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --name: string # The name for the new transactional template.
]: any -> record<generation: string, id: string, name: string, updated_at_: string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new transactional template version.
#
# POST /templates/{template_id}/versions
# operationId: POST_templates-template_id-versions
export def "templates-versions id-versions" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --active: int@active-completer # Set the version as the active version associated with the template (0 is inactive, 1 is active). Only one version of a template can be active. The first version created for a template will automatically be set to Active.
  --editor: string@editor-completer # The editor used in the UI.
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --html-content: string # The HTML content of the version. Maximum of 1048576 bytes allowed.
  name: string # Name of the transactional template version.
  --plain-content: string # Text/plain content of the transactional template version. Maximum of 1048576 bytes allowed. (default: <generated from html_content if left empty>)
  subject: string # Subject of the new transactional template version.
  --test-data: string # For dynamic templates only, the mock json data that will be used for template preview and test sends.
]: any -> record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/versions")
  let body = {active: $active, editor: $editor, generate_plain_content: $generate_plain_content, html_content: $html_content, name: $name, plain_content: $plain_content, subject: $subject, test_data: $test_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a transactional template version.
#
# DELETE /templates/{template_id}/versions/{version_id}
# operationId: DELETE_templates-template_id-versions-version_id
export def "templates-versions id-by-template_id-version_id" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/versions/($version_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific transactional template version.
#
# GET /templates/{template_id}/versions/{version_id}
# operationId: GET_templates-template_id-versions-version_id
export def "templates-versions id-by-template_id-version_id-1" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/versions/($version_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a transactional template version.
#
# PATCH /templates/{template_id}/versions/{version_id}
# operationId: PATCH_templates-template_id-versions-version_id
export def "templates-versions id-by-template_id-version_id-2" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --active: int@active-completer # Set the version as the active version associated with the template (0 is inactive, 1 is active). Only one version of a template can be active. The first version created for a template will automatically be set to Active.
  --editor: string@editor-completer # The editor used in the UI.
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --html-content: string # The HTML content of the version. Maximum of 1048576 bytes allowed.
  name: string # Name of the transactional template version.
  --plain-content: string # Text/plain content of the transactional template version. Maximum of 1048576 bytes allowed. (default: <generated from html_content if left empty>)
  subject: string # Subject of the new transactional template version.
  --test-data: string # For dynamic templates only, the mock json data that will be used for template preview and test sends.
]: any -> record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/versions/($version_id)")
  let body = {active: $active, editor: $editor, generate_plain_content: $generate_plain_content, html_content: $html_content, name: $name, plain_content: $plain_content, subject: $subject, test_data: $test_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate a transactional template version.
#
# POST /templates/{template_id}/versions/{version_id}/activate
# operationId: POST_templates-template_id-versions-version_id-activate
export def "templates-versions-activate id-activate" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($template_id)/versions/($version_id)/activate")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Tracking Settings
#
# GET /tracking_settings
# operationId: GET_tracking_settings
export def "tracking-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<description: string, enabled: bool, name: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Click Track Settings
#
# GET /tracking_settings/click
# operationId: GET_tracking_settings-click
export def "tracking-settings-click settings-click" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enable_text: bool, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/click")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Click Tracking Settings
#
# PATCH /tracking_settings/click
# operationId: PATCH_tracking_settings-click
export def "tracking-settings-click settings-click-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # The setting you want to use for click tracking.
]: any -> record<enable_text: bool, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/click")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Google Analytics Settings
#
# GET /tracking_settings/google_analytics
# operationId: GET_tracking_settings-google_analytics
export def "tracking-settings-google-analytics analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/google_analytics")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Google Analytics Settings
#
# PATCH /tracking_settings/google_analytics
# operationId: PATCH_tracking_settings-google_analytics
export def "tracking-settings-google-analytics analytics-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # Indicates if Google Analytics is enabled.
  --utm-campaign: string # The name of the campaign.
  --utm-content: string # Used to differentiate ads
  --utm-medium: string # Name of the marketing medium (e.g. "Email").
  --utm-source: string # Name of the referrer source. 
  --utm-term: string # Any paid keywords.
]: any -> record<enabled: bool, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/google_analytics")
  let body = {enabled: $enabled, utm_campaign: $utm_campaign, utm_content: $utm_content, utm_medium: $utm_medium, utm_source: $utm_source, utm_term: $utm_term} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Open Tracking Settings
#
# GET /tracking_settings/open
# operationId: GET_tracking_settings-open
export def "tracking-settings-open settings-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/open")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Open Tracking Settings
#
# PATCH /tracking_settings/open
# operationId: PATCH_tracking_settings-open
export def "tracking-settings-open settings-open-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # The new status that you want to set for open tracking.
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/open")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Subscription Tracking Settings
#
# GET /tracking_settings/subscription
# operationId: GET_tracking_settings-subscription
export def "tracking-settings-subscription settings-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<enabled: bool, html_content: string, landing: string, plain_content: string, replace: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/subscription")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Subscription Tracking Settings
#
# PATCH /tracking_settings/subscription
# operationId: PATCH_tracking_settings-subscription
export def "tracking-settings-subscription settings-subscription-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool> # Indicates if subscription tracking is enabled.
  --html-content: string # The information and HTML for your unsubscribe link. 
  --landing: string # The HTML that will be displayed on the page that your customers will see after clicking unsubscribe, hosted on SendGrid’s server.
  --plain-content: string # The information in plain text for your unsubscribe link. You should have the “<% %>” tag in your content, otherwise the user will have no URL for unsubscribing.
  --replace: string # Your custom defined replacement tag for your templates. Use this tag to place your unsubscribe content anywhere in your emailtemplate.
  --body-url: string # The URL where you would like your users sent to unsubscribe. (format: uri)
]: any -> record<enabled: bool, html_content: string, landing: string, plain_content: string, replace: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking_settings/subscription")
  let body = {enabled: $enabled, html_content: $html_content, landing: $landing, plain_content: $plain_content, replace: $replace, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's account information.
#
# GET /user/account
# operationId: GET_user-account
export def "user-account user-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<reputation: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/account")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve your credit balance
#
# GET /user/credits
# operationId: GET_user-credits
export def "user-credits user-credits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<last_reset: string, next_reset: string, overage: int, remain: int, reset_frequency: string, total: int, used: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/credits")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve your account email address
#
# GET /user/email
# operationId: GET_user-email
export def "user-email user-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/email")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update your account email address
#
# PUT /user/email
# operationId: PUT_user-email
export def "user-email user-email-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --email: string # The new email address that you would like to use for your account.
]: any -> record<email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update your password
#
# PUT /user/password
# operationId: PUT_user-password
export def "user-password user-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  new_password: string # The new password you would like to use for your account.
  old_password: string # The old password for your account.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/password")
  let body = {new_password: $new_password, old_password: $old_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user's profile
#
# GET /user/profile
# operationId: GET_user-profile
export def "user-profile user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<address: string, address2: string, city: string, company: string, country: string, first_name: string, last_name: string, phone: string, state: string, website: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/profile")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user's profile
#
# PATCH /user/profile
# operationId: PATCH_user-profile
export def "user-profile user-profile-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --address: string # The street address for this user profile.
  --address2: string # An optional second line for the street address of this user profile.
  --city: string # The city for the user profile.
  --company: string # That company that this user profile is associated with.
  --country: string # Th country of this user profile.
  --first-name: string # The first name of the user.
  --last-name: string # The last name of the user.
  --phone: string # The phone number for the user.
  --state: string # The state for this user.
  --website: string # The website associated with this user.
  --zip: string # The zip code for this user.
]: any -> record<address: string, address2: string, city: string, company: string, country: string, first_name: string, last_name: string, phone: string, state: string, website: string, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/profile")
  let body = {address: $address, address2: $address2, city: $city, company: $company, country: $country, first_name: $first_name, last_name: $last_name, phone: $phone, state: $state, website: $website, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all scheduled sends
#
# GET /user/scheduled_sends
# operationId: GET_user-scheduled_sends
export def "user-scheduled-sends sends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<batch_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/scheduled_sends")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel or pause a scheduled send
#
# POST /user/scheduled_sends
# operationId: POST_user-scheduled_sends
export def "user-scheduled-sends sends-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  batch_id: string # The batch ID is the identifier that your scheduled mail sends share.
  status: string@status-completer # The status of the send you would like to implement. This can be pause or cancel. To delete a pause or cancel status see DELETE /v3/user/scheduled_sends/{batch_id} (default: pause)
]: any -> record<batch_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/scheduled_sends")
  let body = {batch_id: $batch_id, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a cancellation or pause from a scheduled send
#
# DELETE /user/scheduled_sends/{batch_id}
# operationId: DELETE_user-scheduled_sends-batch_id
export def "user-scheduled-sends id-by-batch_id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/scheduled_sends/($batch_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve scheduled send
#
# GET /user/scheduled_sends/{batch_id}
# operationId: GET_user-scheduled_sends-batch_id
export def "user-scheduled-sends id-by-batch_id-1" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> table<batch_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/scheduled_sends/($batch_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a scheduled send
#
# PATCH /user/scheduled_sends/{batch_id}
# operationId: PATCH_user-scheduled_sends-batch_id
export def "user-scheduled-sends id-by-batch_id-2" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  status: string@status-completer # The status you would like the scheduled send to have.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/scheduled_sends/($batch_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve current Enforced TLS settings.
#
# GET /user/settings/enforced_tls
# operationId: GET_user-settings-enforced_tls
export def "user-settings-enforced-tls tls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<require_tls: bool, require_valid_cert: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/settings/enforced_tls")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Enforced TLS settings
#
# PATCH /user/settings/enforced_tls
# operationId: PATCH_user-settings-enforced_tls
export def "user-settings-enforced-tls tls-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --require-tls: oneof<nothing, bool> # Indicates if you want to require your recipients to support TLS. 
  --require-valid-cert: oneof<nothing, bool> # Indicates if you want to require your recipients to have a valid certificate.
]: any -> record<require_tls: bool, require_valid_cert: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/settings/enforced_tls")
  let body = {require_tls: $require_tls, require_valid_cert: $require_valid_cert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve your username
#
# GET /user/username
# operationId: GET_user-username
export def "user-username user-username" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/username")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update your username
#
# PUT /user/username
# operationId: PUT_user-username
export def "user-username user-username-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --username: string # The new username you would like to use for your account.
]: any -> record<username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/username")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Event Webhook settings
#
# GET /user/webhooks/event/settings
# operationId: GET_user-webhooks-event-settings
export def "user-webhooks-event-settings user-webhooks-event-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<bounce: bool, click: bool, deferred: bool, delivered: bool, dropped: bool, enabled: bool, group_resubscribe: bool, group_unsubscribe: bool, oauth_client_id: string, oauth_token_url: string, open: bool, processed: bool, spam_report: bool, unsubscribe: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/event/settings")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Event Notification Settings
#
# PATCH /user/webhooks/event/settings
# operationId: PATCH_user-webhooks-event-settings
export def "user-webhooks-event-settings user-webhooks-event-settings-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --bounce: oneof<nothing, bool> # Receiving server could not or would not accept message.
  --click: oneof<nothing, bool> # Recipient clicked on a link within the message. You need to enable Click Tracking for getting this type of event.
  --deferred: oneof<nothing, bool> # Recipient's email server temporarily rejected message.
  --delivered: oneof<nothing, bool> # Message has been successfully delivered to the receiving server.
  --dropped: oneof<nothing, bool> # You may see the following drop reasons: Invalid SMTPAPI header, Spam Content (if spam checker app enabled), Unsubscribed Address, Bounced Address, Spam Reporting Address, Invalid, Recipient List over Package Quota
  --enabled: oneof<nothing, bool> # Indicates if the event webhook is enabled.
  --group-resubscribe: oneof<nothing, bool> # Recipient resubscribes to specific group by updating preferences. You need to enable Subscription Tracking for getting this type of event.
  --group-unsubscribe: oneof<nothing, bool> # Recipient unsubscribe from specific group, by either direct link or updating preferences. You need to enable Subscription Tracking for getting this type of event.
  --oauth-client-id: string # The client ID Twilio SendGrid sends to your OAuth server or service provider to generate an OAuth access token. When passing data in this field, you must also include the oauth_token_url field.
  --oauth-client-secret: string # This secret is needed only once to create an access token. SendGrid will store this secret, allowing you to update your Client ID and Token URL without passing the secret to SendGrid again.  When passing data in this field, you must also include the oauth_client_id and oauth_token_url fields.
  --oauth-token-url: string # The URL where Twilio SendGrid sends the Client ID and Client Secret to generate an access token. This should be your OAuth server or service provider. When passing data in this field, you must also include the oauth_client_id field.
  --body-open: oneof<nothing, bool> # Recipient has opened the HTML message. You need to enable Open Tracking for getting this type of event.
  --processed: oneof<nothing, bool> # Message has been received and is ready to be delivered.
  --spam-report: oneof<nothing, bool> # Recipient marked a message as spam.
  --unsubscribe: oneof<nothing, bool> # Recipient clicked on message's subscription management link. You need to enable Subscription Tracking for getting this type of event.
  --body-url: string # The URL that you want the event webhook to POST to.
]: any -> record<bounce: bool, click: bool, deferred: bool, delivered: bool, dropped: bool, enabled: bool, group_resubscribe: bool, group_unsubscribe: bool, oauth_client_id: string, oauth_token_url: string, open: bool, processed: bool, spam_report: bool, unsubscribe: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/event/settings")
  let body = {bounce: $bounce, click: $click, deferred: $deferred, delivered: $delivered, dropped: $dropped, enabled: $enabled, group_resubscribe: $group_resubscribe, group_unsubscribe: $group_unsubscribe, oauth_client_id: $oauth_client_id, oauth_client_secret: $oauth_client_secret, oauth_token_url: $oauth_token_url, open: $body_open, processed: $processed, spam_report: $spam_report, unsubscribe: $unsubscribe, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Signed Webhook Public Key
#
# GET /user/webhooks/event/settings/signed
# operationId: GET_user-webhooks-event-settings-signed
export def "user-webhooks-event-settings-signed user-webhooks-event-settings-signed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/event/settings/signed")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable/Disable Signed Webhook
#
# PATCH /user/webhooks/event/settings/signed
# operationId: PATCH_user-webhooks-event-settings-signed
export def "user-webhooks-event-settings-signed user-webhooks-event-settings-signed-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --enabled: oneof<nothing, bool>
]: any -> record<public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/event/settings/signed")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test Event Notification Settings
#
# POST /user/webhooks/event/test
# operationId: POST_user-webhooks-event-test
export def "user-webhooks-event-test user-webhooks-event-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --oauth-client-id: string # The client ID Twilio SendGrid sends to your OAuth server or service provider to generate an OAuth access token. When passing data in this field, you must also include the oauth_client_secret and oauth_token_url fields.
  --oauth-client-secret: string # This secret is needed only once to create an access token. SendGrid will store this secret, allowing you to update your Client ID and Token URL without passing the secret to SendGrid again.  When passing data in this field, you must also include the oauth_client_id and oauth_token_url fields.
  --oauth-token-url: string # The URL where Twilio SendGrid sends the Client ID and Client Secret to generate an access token. This should be your OAuth server or service provider.  When passing data in this field, you must also include the oauth_client_id and oauth_client_secret fields.
  --body-url: string # The URL where you would like the test notification to be sent.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/event/test")
  let body = {oauth_client_id: $oauth_client_id, oauth_client_secret: $oauth_client_secret, oauth_token_url: $oauth_token_url, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all parse settings
#
# GET /user/webhooks/parse/settings
# operationId: GET_user-webhooks-parse-settings
export def "user-webhooks-parse-settings user-webhooks-parse-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<result: table<hostname: string, send_raw: bool, spam_check: bool, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/parse/settings")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a parse setting
#
# POST /user/webhooks/parse/settings
# operationId: POST_user-webhooks-parse-settings
export def "user-webhooks-parse-settings user-webhooks-parse-settings-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --hostname: string # A specific and unique domain or subdomain that you have created to use exclusively to parse your incoming email. For example, `parse.yourdomain.com`.
  --send-raw: oneof<nothing, bool> # Indicates if you would like SendGrid to post the original MIME-type content of your parsed email. When this parameter is set to `true`, SendGrid will send a JSON payload of the content of your email.
  --spam-check: oneof<nothing, bool> # Indicates if you would like SendGrid to check the content parsed from your emails for spam before POSTing them to your domain.
  --body-url: string # The public URL where you would like SendGrid to POST the data parsed from your email. Any emails sent with the given hostname provided (whose MX records have been updated to point to SendGrid) will be parsed and POSTed to this URL.
]: any -> record<hostname: string, send_raw: bool, spam_check: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/webhooks/parse/settings")
  let body = {hostname: $hostname, send_raw: $send_raw, spam_check: $spam_check, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a parse setting
#
# DELETE /user/webhooks/parse/settings/{hostname}
# operationId: DELETE_user-webhooks-parse-settings-hostname
export def "user-webhooks-parse-settings user-webhooks-parse-settings-hostname-by-hostname" [
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/webhooks/parse/settings/($hostname)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific parse setting
#
# GET /user/webhooks/parse/settings/{hostname}
# operationId: GET_user-webhooks-parse-settings-hostname
export def "user-webhooks-parse-settings user-webhooks-parse-settings-hostname-by-hostname-1" [
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<hostname: string, send_raw: bool, spam_check: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/webhooks/parse/settings/($hostname)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a parse setting
#
# PATCH /user/webhooks/parse/settings/{hostname}
# operationId: PATCH_user-webhooks-parse-settings-hostname
export def "user-webhooks-parse-settings user-webhooks-parse-settings-hostname-by-hostname-2" [
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --body-hostname: string # A specific and unique domain or subdomain that you have created to use exclusively to parse your incoming email. For example, `parse.yourdomain.com`.
  --send-raw: oneof<nothing, bool> # Indicates if you would like SendGrid to post the original MIME-type content of your parsed email. When this parameter is set to `true`, SendGrid will send a JSON payload of the content of your email.
  --spam-check: oneof<nothing, bool> # Indicates if you would like SendGrid to check the content parsed from your emails for spam before POSTing them to your domain.
  --body-url: string # The public URL where you would like SendGrid to POST the data parsed from your email. Any emails sent with the given hostname provided (whose MX records have been updated to point to SendGrid) will be parsed and POSTed to this URL.
]: any -> record<hostname: string, send_raw: bool, spam_check: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/webhooks/parse/settings/($hostname)")
  let body = {hostname: $body_hostname, send_raw: $send_raw, spam_check: $spam_check, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves Inbound Parse Webhook statistics.
#
# GET /user/webhooks/parse/stats
# operationId: GET_user-webhooks-parse-stats
export def "user-webhooks-parse-stats user-webhooks-parse-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # The number of statistics to return on each page.
  --offset: string # The number of statistics to skip.
  --aggregated-by: string@aggregated-by-completer # How you would like the statistics to by grouped. 
  --start-date: string # The starting date of the statistics you want to retrieve. Must be in the format YYYY-MM-DD
  --end-date: string # The end date of the statistics you want to retrieve. Must be in the format YYYY-MM-DD (default: The day the request is made.)
  --on-behalf-of: string
]: nothing -> table<date: string, stats: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "aggregated_by" $aggregated_by "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/webhooks/parse/stats" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate an email
#
# POST /validations/email
# operationId: POST_validations-email
export def "validations-email validations-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address that you want to validate.
  --body-source: string # A one-word classifier for where this validation originated.
]: any -> record<result: record<checks: record<additional: record, domain: record, local_part: record>, email: string, host: string, ip_address: string, local: string, score: float, source: string, suggestion: string, verdict: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/validations/email")
  let body = {email: $email, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Verified Senders
#
# GET /verified_senders
# operationId: GET_verified_senders
export def "verified-senders senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float
  --lastSeenID: float
  --id: int
]: nothing -> record<results: table<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "lastSeenID" $lastSeenID "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verified_senders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Verified Sender Request
#
# POST /verified_senders
# operationId: POST_verified_senders
export def "verified-senders senders-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string
  --address2: string
  --city: string
  --country: string
  from_email: string # format: email
  --from-name: string
  nickname: string
  reply_to: string # format: email
  --reply-to-name: string
  --state: string
  --zip: string
]: any -> record<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verified_senders")
  let body = {address: $address, address2: $address2, city: $city, country: $country, from_email: $from_email, from_name: $from_name, nickname: $nickname, reply_to: $reply_to, reply_to_name: $reply_to_name, state: $state, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Domain Warn List
#
# GET /verified_senders/domains
# operationId: GET_verified_senders-domains
export def "verified-senders-domains senders-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: record<hard_failures: list<string>, soft_failures: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verified_senders/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend Verified Sender Request
#
# POST /verified_senders/resend/{id}
# operationId: POST_verified_senders-resend-id
export def "verified-senders-resend senders-resend-id" [
  id: string
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
  let full_url = (build-url $base $"/verified_senders/resend/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Completed Steps
#
# GET /verified_senders/steps_completed
# operationId: GET_verified_senders-steps_completed
export def "verified-senders-steps-completed completed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: record<domain_verified: bool, sender_verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verified_senders/steps_completed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Sender Request
#
# GET /verified_senders/verify/{token}
# operationId: GET_verified_senders-verify-token
export def "verified-senders-verify senders-verify-token" [
  token: string
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
  let full_url = (build-url $base $"/verified_senders/verify/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Verified Sender
#
# DELETE /verified_senders/{id}
# operationId: DELETE_verified_senders-id
export def "verified-senders senders-id-by-id" [
  id: string
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
  let full_url = (build-url $base $"/verified_senders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit Verified Sender
#
# PATCH /verified_senders/{id}
# operationId: PATCH_verified_senders-id
export def "verified-senders senders-id-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string
  --address2: string
  --city: string
  --country: string
  from_email: string # format: email
  --from-name: string
  nickname: string
  reply_to: string # format: email
  --reply-to-name: string
  --state: string
  --zip: string
]: any -> record<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verified_senders/($id)")
  let body = {address: $address, address2: $address2, city: $city, country: $country, from_email: $from_email, from_name: $from_name, nickname: $nickname, reply_to: $reply_to, reply_to_name: $reply_to_name, state: $state, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Email DNS records to a co-worker
#
# POST /whitelabel/dns/email
# operationId: POST_whitelabel-dns-email
export def "whitelabel-dns-email whitelabel-dns-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_id: int # The ID of your SendGrid domain record.
  email: string # The email address to send the DNS information to. (format: email)
  link_id: int
  --message: string # A custom text block to include in the email body sent with the records. (default: Please set these DNS records in our hosting solution.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whitelabel/dns/email")
  let body = {domain_id: $domain_id, email: $email, link_id: $link_id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all authenticated domains
#
# GET /whitelabel/domains
# operationId: GET_whitelabel-domains
export def "whitelabel-domains whitelabel-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of domains to return.
  --offset: int # Paging offset.
  --exclude-subusers: oneof<nothing, bool> # Exclude subuser domains from the result.
  --username: string # The username associated with an authenticated domain.
  --domain: string # Search for authenticated domains.
  --on-behalf-of: string
]: nothing -> table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "exclude_subusers" $exclude_subusers "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/domains" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate a domain
#
# POST /whitelabel/domains
# operationId: POST_whitelabel-domains
export def "whitelabel-domains whitelabel-domains-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --automatic-security: oneof<nothing, bool> # Whether to allow SendGrid to manage your SPF records, DKIM keys, and DKIM key rotation.
  --custom-dkim-selector: string # Add a custom DKIM selector. Accepts three letters or numbers.
  --custom-spf: oneof<nothing, bool> # Specify whether to use a custom SPF or allow SendGrid to manage your SPF. This option is only available to authenticated domains set up for manual security.
  --default: oneof<nothing, bool> # Whether to use this authenticated domain as the fallback if no authenticated domains match the sender's domain.
  domain: string # Domain being authenticated.
  --ips: list # The IP addresses that will be included in the custom SPF record for this authenticated domain.
  --subdomain: string # The subdomain to use for this authenticated domain.
  --username: string # The username associated with this domain.
]: any -> record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record<data: string, host: string, type: string, valid: bool>, dkim2: record<data: string, host: string, type: string, valid: bool>, mail_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whitelabel/domains")
  let body = {automatic_security: $automatic_security, custom_dkim_selector: $custom_dkim_selector, custom_spf: $custom_spf, default: $default, domain: $domain, ips: $ips, subdomain: $subdomain, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the default authentication
#
# GET /whitelabel/domains/default
# operationId: GET_whitelabel-domains-default
export def "whitelabel-domains-default whitelabel-domains-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # The domain to find a default authentication.
  --on-behalf-of: string
]: nothing -> table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/domains/default" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociate an authenticated domain from a given user.
#
# DELETE /whitelabel/domains/subuser
# operationId: DELETE_whitelabel-domains-subuser
export def "whitelabel-domains-subuser whitelabel-domains-subuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # Username for the subuser to find associated authenticated domain.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/domains/subuser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the authenticated domain associated with the given user.
#
# GET /whitelabel/domains/subuser
# operationId: GET_whitelabel-domains-subuser
export def "whitelabel-domains-subuser whitelabel-domains-subuser-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # Username for the subuser to find associated authenticated domain.
]: nothing -> record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/domains/subuser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an authenticated domain.
#
# DELETE /whitelabel/domains/{domain_id}
# operationId: DELETE_whitelabel-domains-domain_id
export def "whitelabel-domains id-by-domain_id" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($domain_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an authenticated domain
#
# GET /whitelabel/domains/{domain_id}
# operationId: GET_whitelabel-domains-domain_id
export def "whitelabel-domains id-by-domain_id-1" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record<data: string, host: string, type: string, valid: bool>, dkim2: record<data: string, host: string, type: string, valid: bool>, mail_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($domain_id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an authenticated domain
#
# PATCH /whitelabel/domains/{domain_id}
# operationId: PATCH_whitelabel-domains-domain_id
export def "whitelabel-domains id-by-domain_id-2" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --custom-spf: oneof<nothing, bool> # Indicates whether to generate a custom SPF record for manual security. (default: false)
  --default: oneof<nothing, bool> # Indicates whether this is the default authenticated domain. (default: false)
]: any -> table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($domain_id)")
  let body = {custom_spf: $custom_spf, default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associate an authenticated domain with a given user.
#
# POST /whitelabel/domains/{domain_id}/subuser
# operationId: POST_whitelabel-domains-domain_id-subuser
export def "whitelabel-domains-subuser id-subuser" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # Username to associate with the authenticated domain.
]: any -> record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($domain_id)/subuser")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add an IP to an authenticated domain
#
# POST /whitelabel/domains/{id}/ips
# operationId: POST_whitelabel-domains-id-ips
export def "whitelabel-domains-ips whitelabel-domains-id-ips" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  ip: string # IP to associate with the domain. Used for manually specifying IPs for custom SPF.
]: any -> record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($id)/ips")
  let body = {ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an IP from an authenticated domain.
#
# DELETE /whitelabel/domains/{id}/ips/{ip}
# operationId: DELETE_whitelabel-domains-id-ips-ip
export def "whitelabel-domains-ips whitelabel-domains-id-ips-ip" [
  id: int
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($id)/ips/($ip)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate a domain authentication.
#
# POST /whitelabel/domains/{id}/validate
# operationId: POST_whitelabel-domains-id-validate
export def "whitelabel-domains-validate whitelabel-domains-id-validate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<id: int, valid: bool, validation_results: record<dkim1: record<reason: string, valid: bool>, dkim2: record<reason: string, valid: bool>, mail_cname: record<reason: string, valid: bool>, spf: record<reason: string, valid: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/domains/($id)/validate")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all reverse DNS records
#
# GET /whitelabel/ips
# operationId: GET_whitelabel-ips
export def "whitelabel-ips whitelabel-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to retrieve.
  --offset: int # The point in the list of results to begin retrieving IP addresses from.
  --ip: string # The IP address segment that you'd like to use in a prefix search.
  --on-behalf-of: string
]: nothing -> table<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: list<record>, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/ips" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set up reverse DNS
#
# POST /whitelabel/ips
# operationId: POST_whitelabel-ips
export def "whitelabel-ips whitelabel-ips-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  domain: string # The root, or sending, domain that will be used to send message from the IP address.
  ip: string # The IP address for which you want to set up reverse DNS.
  --subdomain: string # The subdomain that will be used to send emails from the IP address. This should be the same as the subdomain used to set up an authenticated domain.
]: any -> record<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: table<user_id: int, username: string>, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whitelabel/ips")
  let body = {domain: $domain, ip: $ip, subdomain: $subdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a reverse DNS record
#
# DELETE /whitelabel/ips/{id}
# operationId: DELETE_whitelabel-ips-id
export def "whitelabel-ips whitelabel-ips-id-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/ips/($id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a reverse DNS record
#
# GET /whitelabel/ips/{id}
# operationId: GET_whitelabel-ips-id
export def "whitelabel-ips whitelabel-ips-id-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: table<user_id: int, username: string>, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/ips/($id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate a reverse DNS record
#
# POST /whitelabel/ips/{id}/validate
# operationId: POST_whitelabel-ips-id-validate
export def "whitelabel-ips-validate whitelabel-ips-id-validate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<id: int, valid: bool, validation_results: record<a_record: record<reason: string, valid: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/ips/($id)/validate")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all branded links
#
# GET /whitelabel/links
# operationId: GET_whitelabel-links
export def "whitelabel-links whitelabel-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limits the number of results returned per page.
  --on-behalf-of: string
]: nothing -> table<default: bool, dns: record<domain_cname: record, owner_cname: record>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/links" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a branded link
#
# POST /whitelabel/links
# operationId: POST_whitelabel-links
export def "whitelabel-links whitelabel-links-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --default: oneof<nothing, bool> # Indicates if you want to use this link branding as the default or fallback. When setting a new default, the existing default link branding will have its default status removed automatically.
  domain: string # The root domain for the subdomain that you are creating the link branding for. This should match your FROM email address.
  --subdomain: string # The subdomain to create the link branding for. Must be different from the subdomain you used for authenticating your domain.
]: any -> record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whitelabel/links")
  let body = {default: $default, domain: $domain, subdomain: $subdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the default branded link
#
# GET /whitelabel/links/default
# operationId: GET_whitelabel-links-default
export def "whitelabel-links-default whitelabel-links-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # The domain to match against when finding the default branded link.
  --on-behalf-of: string
]: nothing -> record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/links/default" $qp)
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociate a branded link from a subuser
#
# DELETE /whitelabel/links/subuser
# operationId: DELETE_whitelabel-links-subuser
export def "whitelabel-links-subuser whitelabel-links-subuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # The username of the subuser account that you want to disassociate a branded link from.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/links/subuser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a subuser's branded link
#
# GET /whitelabel/links/subuser
# operationId: GET_whitelabel-links-subuser
export def "whitelabel-links-subuser whitelabel-links-subuser-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # The username of the subuser to retrieve associated branded links for.
]: nothing -> record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whitelabel/links/subuser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a branded link
#
# DELETE /whitelabel/links/{id}
# operationId: DELETE_whitelabel-links-id
export def "whitelabel-links whitelabel-links-id-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/links/($id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a branded link
#
# GET /whitelabel/links/{id}
# operationId: GET_whitelabel-links-id
export def "whitelabel-links whitelabel-links-id-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/links/($id)")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a branded link
#
# PATCH /whitelabel/links/{id}
# operationId: PATCH_whitelabel-links-id
export def "whitelabel-links whitelabel-links-id-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
  --default: oneof<nothing, bool> # Indicates if the branded link is set as the default. When setting a new default, the existing default link branding will have its default status removed automatically.
]: any -> record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/links/($id)")
  let body = {default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate a branded link
#
# POST /whitelabel/links/{id}/validate
# operationId: POST_whitelabel-links-id-validate
export def "whitelabel-links-validate whitelabel-links-id-validate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --on-behalf-of: string
]: nothing -> record<id: int, valid: bool, validation_results: record<domain_cname: record<reason: string, valid: bool>, owner_cname: record<reason: string, valid: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/links/($id)/validate")
  let extra_headers = {"on-behalf-of": $on_behalf_of} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a branded link with a subuser
#
# POST /whitelabel/links/{link_id}/subuser
# operationId: POST_whitelabel-links-link_id-subuser
export def "whitelabel-links-subuser id-subuser" [
  link_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # The username of the subuser account that you want to associate the branded link with.
]: any -> record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whitelabel/links/($link_id)/subuser")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
