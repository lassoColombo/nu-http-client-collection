# Auto-generated client for Better Stack API vv2
# Source: https://raw.githubusercontent.com/api-evangelist/better-stack/main/openapi/better-stack-openapi.yml
# Auth: --token flag or $env.BETTER_STACK_API_TOKEN

const BASE_URL = "https://uptime.betterstack.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BETTER_STACK_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://uptime.betterstack.com/api/v2" "https://uptime.betterstack.com/api/v3" "https://betterstack.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def monitor-type-completer [] { ["expected_status_code" "keyword" "keyword_absence" "ping" "status" "tcp"] }
def theme-completer [] { ["dark" "light"] }
def role-completer [] { ["admin" "member" "viewer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "monitors listMonitors" } } | get name | first)
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

# Better Stack List Monitors
#
# GET /monitors
# operationId: listMonitors
export def "monitors listMonitors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-name: string # Filter monitors belonging to a specified team when using a global API token. (e.g. my-team)
  --qp-url: string # Filter monitors by target URL. (e.g. https://example.com)
  --pronounceable-name: string # Filter monitors by pronounceable name. (e.g. Production API)
]: nothing -> record<data: table<id: string, type: string, attributes: record>, pagination: record<first: string, last: string, prev: string, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_name" $team_name "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "pronounceable_name" $pronounceable_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/monitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Create Monitor
#
# POST /monitors
# operationId: createMonitor
export def "monitors createMonitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL to monitor. (format: uri, e.g. https://example.com)
  --pronounceable-name: string # Human-readable name for the monitor. (e.g. Production API)
  --monitor-type: string@monitor-type-completer # Type of monitoring check. (e.g. status)
  --check-frequency: int # Check interval in seconds. (e.g. 180)
  --verify-ssl: string@bool-completer # Whether to verify SSL certificate. (e.g. true)
  --email: string@bool-completer # Alert via email. (e.g. true)
  --sms: string@bool-completer # Alert via SMS. (e.g. false)
  --call: string@bool-completer # Alert via phone call. (e.g. false)
  --push: string@bool-completer # Alert via push notification. (e.g. true)
  --regions: list # Regions to monitor from. (e.g. [us, eu])
  --policy-id: string # Escalation policy ID. (nullable, e.g. 300010)
]: any -> record<data: record<id: string, type: string, attributes: record<url: string, pronounceable_name: string, monitor_type: string, status: string, monitor_group_id: string, policy_id: string, check_frequency: int, verify_ssl: bool, ssl_expiration: int, call: bool, sms: bool, email: bool, push: bool, regions: list, created_at: string, updated_at: string, paused_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitors")
  let body = {url: $body_url, pronounceable_name: $pronounceable_name, monitor_type: $monitor_type, check_frequency: $check_frequency, verify_ssl: $verify_ssl, email: $email, sms: $sms, call: $call, push: $push, regions: $regions, policy_id: $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Get Monitor
#
# GET /monitors/{id}
# operationId: getMonitor
export def "monitors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<url: string, pronounceable_name: string, monitor_type: string, status: string, monitor_group_id: string, policy_id: string, check_frequency: int, verify_ssl: bool, ssl_expiration: int, call: bool, sms: bool, email: bool, push: bool, regions: list, created_at: string, updated_at: string, paused_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Update Monitor
#
# PATCH /monitors/{id}
# operationId: updateMonitor
export def "monitors updateMonitor" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # New URL to monitor. (format: uri, e.g. https://example.com)
  --pronounceable-name: string # New human-readable name. (e.g. Updated API Monitor)
  --check-frequency: int # New check interval in seconds. (e.g. 300)
  --verify-ssl: string@bool-completer # SSL verification setting. (e.g. true)
  --email: string@bool-completer # Alert via email. (e.g. true)
  --sms: string@bool-completer # Alert via SMS. (e.g. false)
  --call: string@bool-completer # Alert via phone call. (e.g. false)
  --push: string@bool-completer # Alert via push notification. (e.g. true)
]: any -> record<data: record<id: string, type: string, attributes: record<url: string, pronounceable_name: string, monitor_type: string, status: string, monitor_group_id: string, policy_id: string, check_frequency: int, verify_ssl: bool, ssl_expiration: int, call: bool, sms: bool, email: bool, push: bool, regions: list, created_at: string, updated_at: string, paused_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)")
  let body = {url: $body_url, pronounceable_name: $pronounceable_name, check_frequency: $check_frequency, verify_ssl: $verify_ssl, email: $email, sms: $sms, call: $call, push: $push} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Delete Monitor
#
# DELETE /monitors/{id}
# operationId: deleteMonitor
export def "monitors delete" [
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
  let full_url = (build-url $base $"/monitors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Get Monitor Response Times
#
# GET /monitors/{id}/response-times
# operationId: getMonitorResponseTimes
export def "monitors-response-times get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<at: string, response_time: int, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)/response-times")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Get Monitor Availability
#
# GET /monitors/{id}/availability
# operationId: getMonitorAvailability
export def "monitors-availability get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<availability: float, downtime_duration: int, number_of_incidents: int, longest_incident_duration: int, average_incident_duration: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/monitors/($id)/availability")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack List Heartbeats
#
# GET /heartbeats
# operationId: listHeartbeats
export def "heartbeats listHeartbeats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-name: string # Filter heartbeats belonging to a specified team when using a global API token. (e.g. my-team)
]: nothing -> record<data: table<id: string, type: string, attributes: record>, pagination: record<first: string, last: string, prev: string, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_name" $team_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/heartbeats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Create Heartbeat
#
# POST /heartbeats
# operationId: createHeartbeat
export def "heartbeats createHeartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name for the heartbeat. (e.g. Daily Backup Job)
  period: int # Expected period in seconds. (e.g. 86400)
  --grace: int # Grace period in seconds. (e.g. 3600)
  --email: string@bool-completer # Alert via email. (e.g. true)
  --sms: string@bool-completer # Alert via SMS. (e.g. false)
  --call: string@bool-completer # Alert via phone call. (e.g. false)
  --push: string@bool-completer # Alert via push notification. (e.g. true)
]: any -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, period: int, grace: int, status: string, call: bool, sms: bool, email: bool, push: bool, created_at: string, updated_at: string, paused_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/heartbeats")
  let body = {name: $name, period: $period, grace: $grace, email: $email, sms: $sms, call: $call, push: $push} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Get Heartbeat
#
# GET /heartbeats/{id}
# operationId: getHeartbeat
export def "heartbeats get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, period: int, grace: int, status: string, call: bool, sms: bool, email: bool, push: bool, created_at: string, updated_at: string, paused_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heartbeats/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Update Heartbeat
#
# PATCH /heartbeats/{id}
# operationId: updateHeartbeat
export def "heartbeats updateHeartbeat" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New name for the heartbeat. (e.g. Updated Backup Job)
  --period: int # New period in seconds. (e.g. 86400)
  --grace: int # New grace period in seconds. (e.g. 7200)
]: any -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, period: int, grace: int, status: string, call: bool, sms: bool, email: bool, push: bool, created_at: string, updated_at: string, paused_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heartbeats/($id)")
  let body = {name: $name, period: $period, grace: $grace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Delete Heartbeat
#
# DELETE /heartbeats/{id}
# operationId: deleteHeartbeat
export def "heartbeats delete" [
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
  let full_url = (build-url $base $"/heartbeats/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Get Heartbeat Availability
#
# GET /heartbeats/{id}/availability
# operationId: getHeartbeatAvailability
export def "heartbeats-availability get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<availability: float, downtime_duration: int, number_of_incidents: int, longest_incident_duration: int, average_incident_duration: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heartbeats/($id)/availability")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack List Incidents
#
# GET /incidents
# operationId: listIncidents
export def "incidents listIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-name: string # Filter incidents by team name when using a global API token. (e.g. my-team)
  --qp-from: string # Filter incidents starting from this date (YYYY-MM-DD). (format: date, e.g. 2026-01-01)
  --qp-to: string # Filter incidents up to this date (YYYY-MM-DD). (format: date, e.g. 2026-04-19)
  --monitor-id: int # Filter incidents by monitor ID. (e.g. 500123)
  --heartbeat-id: int # Filter incidents by heartbeat ID. (e.g. 100200)
  --resolved: string@bool-completer # Filter by resolved status. (e.g. false)
  --acknowledged: string@bool-completer # Filter by acknowledged status. (e.g. false)
]: nothing -> record<data: table<id: string, type: string, attributes: record>, pagination: record<first: string, last: string, prev: string, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_name" $team_name "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "monitor_id" $monitor_id "scalar") (serialize-qp "heartbeat_id" $heartbeat_id "scalar") (serialize-qp "resolved" $resolved "scalar") (serialize-qp "acknowledged" $acknowledged "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Create Incident
#
# POST /incidents
# operationId: createIncident
export def "incidents createIncident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name or description of the incident. (e.g. Database degraded)
  --email: string@bool-completer # Alert via email. (e.g. true)
  --sms: string@bool-completer # Alert via SMS. (e.g. false)
  --call: string@bool-completer # Alert via phone call. (e.g. false)
  --push: string@bool-completer # Alert via push notification. (e.g. true)
]: any -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, http_method: string, cause: string, started_at: string, acknowledged_at: string, resolved_at: string, status: string, team_name: string, regions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/incidents")
  let body = {name: $name, email: $email, sms: $sms, call: $call, push: $push} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Get Incident
#
# GET /incidents/{id}
# operationId: getIncident
export def "incidents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, http_method: string, cause: string, started_at: string, acknowledged_at: string, resolved_at: string, status: string, team_name: string, regions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Delete Incident
#
# DELETE /incidents/{id}
# operationId: deleteIncident
export def "incidents delete" [
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
  let full_url = (build-url $base $"/incidents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Acknowledge Incident
#
# POST /incidents/{id}/acknowledge
# operationId: acknowledgeIncident
export def "incidents-acknowledge acknowledgeIncident" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, http_method: string, cause: string, started_at: string, acknowledged_at: string, resolved_at: string, status: string, team_name: string, regions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/acknowledge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Resolve Incident
#
# POST /incidents/{id}/resolve
# operationId: resolveIncident
export def "incidents-resolve resolveIncident" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<name: string, url: string, http_method: string, cause: string, started_at: string, acknowledged_at: string, resolved_at: string, status: string, team_name: string, regions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/incidents/($id)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack List Status Pages
#
# GET /status-pages
# operationId: listStatusPages
export def "status-pages listStatusPages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-name: string # Filter by team name when using a global API token. (e.g. my-team)
]: nothing -> record<data: table<id: string, type: string, attributes: record>, pagination: record<first: string, last: string, prev: string, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_name" $team_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status-pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Create Status Page
#
# POST /status-pages
# operationId: createStatusPage
export def "status-pages createStatusPage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  company_name: string # Company name displayed on the page. (e.g. Acme Corp)
  --company-website: string # Company website URL. (format: uri, e.g. https://acme.com)
  subdomain: string # Subdomain slug. (e.g. acme)
  --timezone: string # Timezone for the page. (e.g. UTC)
  --theme: string@theme-completer # Page theme. (e.g. light)
]: any -> record<data: record<id: string, type: string, attributes: record<company_name: string, company_website: string, subdomain: string, custom_domain: string, timezone: string, theme: string, aggregate_state: string, created_at: string, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status-pages")
  let body = {company_name: $company_name, company_website: $company_website, subdomain: $subdomain, timezone: $timezone, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Get Status Page
#
# GET /status-pages/{id}
# operationId: getStatusPage
export def "status-pages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<company_name: string, company_website: string, subdomain: string, custom_domain: string, timezone: string, theme: string, aggregate_state: string, created_at: string, updated_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Update Status Page
#
# PATCH /status-pages/{id}
# operationId: updateStatusPage
export def "status-pages updateStatusPage" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --company-name: string # New company name. (e.g. Acme Corp Updated)
  --custom-domain: string # New custom domain. (e.g. status.acme.com)
  --theme: string@theme-completer # New theme. (e.g. dark)
]: any -> record<data: record<id: string, type: string, attributes: record<company_name: string, company_website: string, subdomain: string, custom_domain: string, timezone: string, theme: string, aggregate_state: string, created_at: string, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/status-pages/($id)")
  let body = {company_name: $company_name, custom_domain: $custom_domain, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Delete Status Page
#
# DELETE /status-pages/{id}
# operationId: deleteStatusPage
export def "status-pages delete" [
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
  let full_url = (build-url $base $"/status-pages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack List Escalation Policies
#
# GET /policies
# operationId: listEscalationPolicies
export def "policies listEscalationPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-name: string # Filter policies by team name when using a global API token. (e.g. my-team)
]: nothing -> record<data: table<id: string, type: string, attributes: record>, pagination: record<first: string, last: string, prev: string, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_name" $team_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Create Escalation Policy
#
# POST /policies
# operationId: createEscalationPolicy
export def "policies createEscalationPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Policy name. (e.g. Default On-Call)
  --repeat-count: int # Number of repeat cycles. (e.g. 3)
  --repeat-delay: int # Delay between cycles in seconds. (e.g. 300)
]: any -> record<data: record<id: string, type: string, attributes: record<name: string, repeat_count: int, repeat_delay: int, incident_token: string, policy_group_id: string, team_name: string, steps: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies")
  let body = {name: $name, repeat_count: $repeat_count, repeat_delay: $repeat_delay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Get Escalation Policy
#
# GET /policies/{id}
# operationId: getEscalationPolicy
export def "policies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<name: string, repeat_count: int, repeat_delay: int, incident_token: string, policy_group_id: string, team_name: string, steps: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Update Escalation Policy
#
# PATCH /policies/{id}
# operationId: updateEscalationPolicy
export def "policies updateEscalationPolicy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New policy name. (e.g. Updated On-Call Policy)
  --repeat-count: int # New repeat count. (e.g. 5)
  --repeat-delay: int # New repeat delay in seconds. (e.g. 600)
]: any -> record<data: record<id: string, type: string, attributes: record<name: string, repeat_count: int, repeat_delay: int, incident_token: string, policy_group_id: string, team_name: string, steps: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/policies/($id)")
  let body = {name: $name, repeat_count: $repeat_count, repeat_delay: $repeat_delay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Delete Escalation Policy
#
# DELETE /policies/{id}
# operationId: deleteEscalationPolicy
export def "policies delete" [
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
  let full_url = (build-url $base $"/policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack List Team Members
#
# GET /team-members
# operationId: listTeamMembers
export def "team-members listTeamMembers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-name: string # Filter by team name when using a global API token. (e.g. my-team)
  --email: string # Filter by member email address. (format: email, e.g. jsmith@example.com)
]: nothing -> record<data: table<id: string, type: string, attributes: record>, pagination: record<first: string, last: string, prev: string, next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_name" $team_name "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Invite Team Member
#
# POST /team-members
# operationId: inviteTeamMember
export def "team-members inviteTeamMember" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email address of the person to invite. (format: email, e.g. newmember@example.com)
  --role: string@role-completer # Role to assign. (e.g. member)
]: any -> record<data: record<id: string, type: string, attributes: record<email: string, name: string, role: string, created_at: string, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-members")
  let body = {email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Better Stack Get Team Member
#
# GET /team-members/{id}
# operationId: getTeamMember
export def "team-members get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<email: string, name: string, role: string, created_at: string, updated_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Better Stack Delete Team Member
#
# DELETE /team-members/{id}
# operationId: deleteTeamMember
export def "team-members delete" [
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
  let full_url = (build-url $base $"/team-members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
