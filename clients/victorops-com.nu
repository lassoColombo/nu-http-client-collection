# Auto-generated client for VictorOps v0.0.3
# Source: https://api.apis.guru/v2/specs/victorops.com/0.0.3/swagger.json
# Auth: --token flag or $env.VICTOROPS_TOKEN

const BASE_URL = "https://api.victorops.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VICTOROPS_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.victorops.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-public-alerts get" } } | get name | first)
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

# Retrieve alert details.
#
# GET /api-public/v1/alerts/{uuid}
export def "api-public-alerts get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<ackAuthor: string, ackMsg: string, entityDisplayName: string, entityId: string, messageType: string, monitoringTool: string, raw: string, stateMessage: string, stateStartTime: float, timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/api-public/v1/alerts/{uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current incident information
#
# GET /api-public/v1/incidents
export def "api-public-incidents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new incident
#
# POST /api-public/v1/incidents
export def "api-public-incidents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<error: string, incidentNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Acknowledge an incident or list of incidents
#
# PATCH /api-public/v1/incidents/ack
export def "api-public-incidents-ack update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/ack")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Acknowledge all incidents for which a user was paged.
#
# PATCH /api-public/v1/incidents/byUser/ack
export def "api-public-incidents-by-user-ack update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/byUser/ack")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve all incidents for which a user was paged.
#
# PATCH /api-public/v1/incidents/byUser/resolve
export def "api-public-incidents-by-user-resolve update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/byUser/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reroute one or more incidents to one or more new routable destinations.
#
# POST /api-public/v1/incidents/reroute
export def "api-public-incidents-reroute create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<statuses: table<incidentNumber: string, message: string, success: bool, targetStatus: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/reroute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve an incident or list of incidents
#
# PATCH /api-public/v1/incidents/resolve
export def "api-public-incidents-resolve update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an organization's current maintenance mode state
#
# GET /api-public/v1/maintenancemode
export def "api-public-maintenancemode get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/maintenancemode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start maintenance mode for routing keys
#
# POST /api-public/v1/maintenancemode/start
export def "api-public-maintenancemode-start create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/maintenancemode/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# End maintenance mode for routing keys
#
# PUT /api-public/v1/maintenancemode/{maintenancemodeid}/end
export def "api-public-maintenancemode-end update" [
  maintenancemodeid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({maintenancemodeid: (encode-path-segment $maintenancemodeid)} | format pattern "/api-public/v1/maintenancemode/{maintenancemodeid}/end"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an organization's on-call users
#
# GET /api-public/v1/oncall/current
export def "api-public-oncall-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teamsOnCall: table<onCallNow: list, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/oncall/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List routing keys with associated teams
#
# GET /api-public/v1/org/routing-keys
export def "api-public-org-routing-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, routingKeys: table<isDefault: bool, routingKey: string, targets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/org/routing-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the scheduled overrides
#
# GET /api-public/v1/overrides
export def "api-public-overrides list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, overrides: table<assignments: list, end: string, publicId: string, start: string, timezone: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/overrides")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new scheduled override
#
# POST /api-public/v1/overrides
export def "api-public-overrides create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, schedule: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/overrides")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a scheduled override
#
# DELETE /api-public/v1/overrides/{publicId}
export def "api-public-overrides delete" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id)} | format pattern "/api-public/v1/overrides/{public_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the specified scheduled override
#
# GET /api-public/v1/overrides/{publicId}
export def "api-public-overrides get" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, override: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id)} | format pattern "/api-public/v1/overrides/{public_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the specified scheduled override
#
# GET /api-public/v1/overrides/{publicId}/assignments
export def "api-public-overrides-assignments list" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id)} | format pattern "/api-public/v1/overrides/{public_id}/assignments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the scheduled override assignment
#
# DELETE /api-public/v1/overrides/{publicId}/assignments/{policySlug}
export def "api-public-overrides-assignments delete" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id), policy_slug: (encode-path-segment $policy_slug)} | format pattern "/api-public/v1/overrides/{public_id}/assignments/{policy_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the specified scheduled override assignment
#
# GET /api-public/v1/overrides/{publicId}/assignments/{policySlug}
export def "api-public-overrides-assignments get" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id), policy_slug: (encode-path-segment $policy_slug)} | format pattern "/api-public/v1/overrides/{public_id}/assignments/{policy_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the scheduled override assignment
#
# PUT /api-public/v1/overrides/{publicId}/assignments/{policySlug}
export def "api-public-overrides-assignments update" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id), policy_slug: (encode-path-segment $policy_slug)} | format pattern "/api-public/v1/overrides/{public_id}/assignments/{policy_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get escalation policy info
#
# GET /api-public/v1/policies
export def "api-public-policies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<policies: table<policy: record, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the available contact types
#
# GET /api-public/v1/policies/types/contacts
export def "api-public-policies-types-contacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, contactTypes: table<description: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies/types/contacts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the available notification types
#
# GET /api-public/v1/policies/types/notifications
export def "api-public-policies-types-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, notificationTypes: table<description: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies/types/notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the available timeout values
#
# GET /api-public/v1/policies/types/timeouts
export def "api-public-policies-types-timeouts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, timeoutTypes: table<description: string, type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies/types/timeouts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an on-call override (take on-call)
#
# PATCH /api-public/v1/policies/{policy}/oncall/user
export def "api-public-policies-oncall-user update" [
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({policy: (encode-path-segment $policy)} | format pattern "/api-public/v1/policies/{policy}/oncall/user"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the user's paging policy
#
# GET /api-public/v1/profile/{username}/policies
export def "api-public-profile-policies get-by-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, steps: table<index: float, rules: list, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/api-public/v1/profile/{username}/policies"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a paging policy step
#
# POST /api-public/v1/profile/{username}/policies
export def "api-public-profile-policies create-by-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/api-public/v1/profile/{username}/policies"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paging policy step
#
# GET /api-public/v1/profile/{username}/policies/{step}
export def "api-public-profile-policies get-by-username-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step)} | format pattern "/api-public/v1/profile/{username}/policies/{step}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a rule for a paging policy step
#
# POST /api-public/v1/profile/{username}/policies/{step}
export def "api-public-profile-policies create-by-username-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step)} | format pattern "/api-public/v1/profile/{username}/policies/{step}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a paging policy step
#
# PUT /api-public/v1/profile/{username}/policies/{step}
export def "api-public-profile-policies update-by-username-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step)} | format pattern "/api-public/v1/profile/{username}/policies/{step}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a rule from a paging policy step
#
# DELETE /api-public/v1/profile/{username}/policies/{step}/{rule}
export def "api-public-profile-policies delete" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step), rule: (encode-path-segment $rule)} | format pattern "/api-public/v1/profile/{username}/policies/{step}/{rule}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a rule from a paging policy step
#
# GET /api-public/v1/profile/{username}/policies/{step}/{rule}
export def "api-public-profile-policies get-by-username-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step), rule: (encode-path-segment $rule)} | format pattern "/api-public/v1/profile/{username}/policies/{step}/{rule}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a rule for a paging policy step
#
# PUT /api-public/v1/profile/{username}/policies/{step}/{rule}
export def "api-public-profile-policies update-by-username-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step), rule: (encode-path-segment $rule)} | format pattern "/api-public/v1/profile/{username}/policies/{step}/{rule}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List teams
#
# GET /api-public/v1/team
export def "api-public-team list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/team")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a team
#
# POST /api-public/v1/team
export def "api-public-team create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/team")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a team
#
# DELETE /api-public/v1/team/{team}
export def "api-public-team delete" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve information for a team
#
# GET /api-public/v1/team/{team}
export def "api-public-team get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a team
#
# PUT /api-public/v1/team/{team}
export def "api-public-team update" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of team admins for a team
#
# GET /api-public/v1/team/{team}/admins
export def "api-public-team-admins get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teamAdmins: table<_selfUrl: string, firstName: string, lastName: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/admins"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of members for a team
#
# GET /api-public/v1/team/{team}/members
export def "api-public-team-members get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a team member
#
# POST /api-public/v1/team/{team}/members
export def "api-public-team-members create" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a team member
#
# DELETE /api-public/v1/team/{team}/members/{user}
export def "api-public-team-members delete" [
  team: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team), user: (encode-path-segment $user)} | format pattern "/api-public/v1/team/{team}/members/{user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a team's on-call schedule
#
# GET /api-public/v1/team/{team}/oncall/schedule
# DEPRECATED
@deprecated
export def "api-public-team-oncall-schedule get-by-team" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<overrides: table<end: float, orig: string, over: string, start: float>, schedule: table<oncall: string, overrideoncall: string, policyType: string, rolls: list, rotationName: string, shiftName: string, shiftRoll: float>, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/oncall/schedule") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an on-call override (take on-call)
#
# PATCH /api-public/v1/team/{team}/oncall/user
# DEPRECATED
@deprecated
export def "api-public-team-oncall-user update" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/oncall/user"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of escalation policies for a team
#
# GET /api-public/v1/team/{team}/policies
export def "api-public-team-policies get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<policies: table<name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/policies"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users
#
# GET /api-public/v1/user
export def "api-public-user list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, users: table<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user
#
# POST /api-public/v1/user
export def "api-public-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a user
#
# DELETE /api-public/v1/user/{user}
export def "api-public-user delete" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve information for a user
#
# GET /api-public/v1/user/{user}
export def "api-public-user get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /api-public/v1/user/{user}
export def "api-public-user update" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all contact methods for a user
#
# GET /api-public/v1/user/{user}/contact-methods
export def "api-public-user-contact-methods get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<devices: table<_selfUrl: string, deviceType: string, extId: string, label: string>, emails: table<_selfUrl: string, deviceType: string, extId: string, label: string>, phones: table<_selfUrl: string, deviceType: string, extId: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all contact devices for a user
#
# GET /api-public/v1/user/{user}/contact-methods/devices
export def "api-public-user-contact-methods-devices list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a contact device for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/devices/{contactId}
export def "api-public-user-contact-methods-devices delete" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the indicated contact device for a user
#
# GET /api-public/v1/user/{user}/contact-methods/devices/{contactId}
export def "api-public-user-contact-methods-devices get" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a contact device for a user
#
# PUT /api-public/v1/user/{user}/contact-methods/devices/{contactId}
export def "api-public-user-contact-methods-devices update" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all contact emails for a user
#
# GET /api-public/v1/user/{user}/contact-methods/emails
export def "api-public-user-contact-methods-emails list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a contact emails for a user
#
# POST /api-public/v1/user/{user}/contact-methods/emails
export def "api-public-user-contact-methods-emails create" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a contact email for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/emails/{contactId}
export def "api-public-user-contact-methods-emails delete" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the indicated contact email for a user
#
# GET /api-public/v1/user/{user}/contact-methods/emails/{contactId}
export def "api-public-user-contact-methods-emails get" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all contact phones for a user
#
# GET /api-public/v1/user/{user}/contact-methods/phones
export def "api-public-user-contact-methods-phones list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a contact phones for a user
#
# POST /api-public/v1/user/{user}/contact-methods/phones
export def "api-public-user-contact-methods-phones create" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a contact phone for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/phones/{contactId}
export def "api-public-user-contact-methods-phones delete" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the indicated contact phone for a user
#
# GET /api-public/v1/user/{user}/contact-methods/phones/{contactId}
export def "api-public-user-contact-methods-phones get" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's on-call schedule
#
# GET /api-public/v1/user/{user}/oncall/schedule
# DEPRECATED
@deprecated
export def "api-public-user-oncall-schedule get-by-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<overrides: list<record>, schedule: list<record>, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/oncall/schedule") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of paging policies for a user
#
# GET /api-public/v1/user/{user}/policies
export def "api-public-user-policies get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<policies: table<contactType: string, extId: string, order: int, timeout: int>, userId: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/policies"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the user's team membership
#
# GET /api-public/v1/user/{user}/teams
export def "api-public-user-teams get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teams: table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a team's on-call schedule
#
# GET /api-public/v2/team/{team}/oncall/schedule
export def "api-public-team-oncall-schedule get-by-team-1" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<schedules: table<overrides: list, policy: record, schedule: list>, team: record<name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v2/team/{team}/oncall/schedule") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's on-call schedule
#
# GET /api-public/v2/user/{user}/oncall/schedule
export def "api-public-user-oncall-schedule get-by-user-1" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teamSchedules: table<schedules: list, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v2/user/{user}/oncall/schedule") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get/search incident history
#
# GET /api-reporting/v1/incidents
# DEPRECATED
@deprecated
export def "api-reporting-incidents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # The offset within the set of matching incidents (default: 0)
  --limit: float # The maximum number of matching incidents to return (100 max) (default: 20)
  --entity-id: string # The entity ID involved This is the unique identifier for the entity causing the incident.
  --incident-number: string # The incident number as shown in VictorOps Multiple values and ranges are allowed: 4,5,20:50
  --started-after: string # Return incidents started after this timestamp Specify the timestamp in ISO8601 format
  --started-before: string # Find incidents started before this timestamp Specify the timestamp in ISO8601 format
  --host: string # The host involved in the incident Multiple values can be separated with commas.
  --service: string # The service involved in the incident (if any) Multiple values can be separated with commas.
  --current-phase: string # The current phase of the incident "resolved", "triggered" or "acknowledged". Multiple values can be separated with commas.
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<incidents: list<record>, limit: float, offset: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "entityId" $entity_id "scalar") (serialize-qp "incidentNumber" $incident_number "scalar") (serialize-qp "startedAfter" $started_after "scalar") (serialize-qp "startedBefore" $started_before "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "currentPhase" $current_phase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api-reporting/v1/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A list of shift changes for a team
#
# GET /api-reporting/v1/team/{team}/oncall/log
export def "api-reporting-team-oncall-log get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Return shift changes occurring after this timestamp. The default is the start of the day at midnight. Specify the timestamp in ISO8601 format (format: date-time)
  --end: string # Return shift changes occurring before this timestamp. The default is the end of the day at 11:59:59. Specify the timestamp in ISO8601 format (format: date-time)
  --user-name: string # The VictorOps user ID. Return shift changes occurring during the interval specified for this user. Without this parameter, all relevant users (with respect to the specified interval) are returned
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<end: string, start: string, teamSlug: string, userLogs: table<adjustedTotal: record, log: list, total: record, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-reporting/v1/team/{team}/oncall/log") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get/search incident history
#
# GET /api-reporting/v2/incidents
export def "api-reporting-incidents get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # The offset within the set of matching incidents (default: 0)
  --limit: float # The maximum number of matching incidents to return (100 max) (default: 20)
  --entity-id: string # The entity ID involved This is the unique identifier for the entity causing the incident.
  --incident-number: string # The incident number as shown in VictorOps Multiple values and ranges are allowed: 4,5,20:50
  --started-after: string # Return incidents started after this timestamp Specify the timestamp in ISO8601 format
  --started-before: string # Find incidents started before this timestamp Specify the timestamp in ISO8601 format
  --host: string # The host involved in the incident Multiple values can be separated with commas.
  --service: string # The service involved in the incident (if any) Multiple values can be separated with commas.
  --current-phase: string # The current phase of the incident "resolved", "triggered" or "acknowledged". Multiple values can be separated with commas. By default, response contains only "resolved" incidents
  --routing-key: string # The original routing of the incident
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "entityId" $entity_id "scalar") (serialize-qp "incidentNumber" $incident_number "scalar") (serialize-qp "startedAfter" $started_after "scalar") (serialize-qp "startedBefore" $started_before "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "currentPhase" $current_phase "scalar") (serialize-qp "routingKey" $routing_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api-reporting/v2/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
