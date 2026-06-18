# Auto-generated client for DigitalOcean API v2.0
# Source: https://api.apis.guru/v2/specs/digitalocean.com/2.0/openapi.json
# Auth: --token flag or $env.DIGITALOCEAN_API_TOKEN

const BASE_URL = "https://api.digitalocean.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DIGITALOCEAN_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.digitalocean.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["droplet" "kubernetes"] }
def accept-completer [] { ["application/json" "application/yaml"] }
def content-type-completer [] { ["application/json" "application/yaml"] }
def type-completer-1 [] { ["BUILD" "DEPLOY" "RUN" "UNSPECIFIED"] }
def ttl-completer [] { ["3600" "60" "600" "604800" "86400"] }
def engine-completer [] { ["mongodb" "mysql" "pg" "redis"] }
def type-completer-2 [] { ["A" "AAAA" "CAA" "CNAME" "MX" "NS" "SOA" "SRV" "TXT"] }
def type-completer-3 [] { ["change_kernel" "disable_backups" "enable_backups" "enable_ipv6" "password_reset" "power_cycle" "power_off" "power_on" "reboot" "rebuild" "rename" "resize" "restore" "shutdown" "snapshot"] }
def type-completer-4 [] { ["application" "distribution"] }
def distribution-completer [] { ["Arch Linux" "CentOS" "CoreOS" "Debian" "Fedora" "Fedora Atomic" "FreeBSD" "Gentoo" "RancherOS" "Rocky Linux" "Ubuntu" "Unknown" "openSUSE"] }
def region-completer [] { ["ams1" "ams2" "ams3" "blr1" "fra1" "lon1" "nyc1" "nyc2" "nyc3" "sfo1" "sfo2" "sfo3" "sgp1" "tor1"] }
def type-completer-5 [] { ["convert" "transfer"] }
def compare-completer [] { ["GreaterThan" "LessThan"] }
def type-completer-6 [] { ["v1/dbaas/alerts/cpu_alerts" "v1/dbaas/alerts/disk_utilization_alerts" "v1/dbaas/alerts/load_15_alerts" "v1/dbaas/alerts/memory_utilization_alerts" "v1/insights/droplet/cpu" "v1/insights/droplet/disk_read" "v1/insights/droplet/disk_utilization_percent" "v1/insights/droplet/disk_write" "v1/insights/droplet/load_1" "v1/insights/droplet/load_15" "v1/insights/droplet/load_5" "v1/insights/droplet/memory_utilization_percent" "v1/insights/droplet/private_inbound_bandwidth" "v1/insights/droplet/private_outbound_bandwidth" "v1/insights/droplet/public_inbound_bandwidth" "v1/insights/droplet/public_outbound_bandwidth" "v1/insights/lbaas/avg_cpu_utilization_percent" "v1/insights/lbaas/connection_utilization_percent" "v1/insights/lbaas/droplet_health" "v1/insights/lbaas/high_http_request_response_time" "v1/insights/lbaas/high_http_request_response_time_50p" "v1/insights/lbaas/high_http_request_response_time_95p" "v1/insights/lbaas/high_http_request_response_time_99p" "v1/insights/lbaas/increase_in_http_error_rate_count_4xx" "v1/insights/lbaas/increase_in_http_error_rate_count_5xx" "v1/insights/lbaas/increase_in_http_error_rate_percentage_4xx" "v1/insights/lbaas/increase_in_http_error_rate_percentage_5xx" "v1/insights/lbaas/tls_connections_per_second_utilization_percent"] }
def window-completer [] { ["10m" "1h" "30m" "5m"] }
def interface-completer [] { ["private" "public"] }
def direction-completer [] { ["inbound" "outbound"] }
def environment-completer [] { ["Development" "Production" "Staging"] }
def region-completer-1 [] { ["ams3" "fra1" "nyc3" "sfo3" "sgp1"] }
def subscription-tier-slug-completer [] { ["basic" "professional" "starter"] }
def tier-slug-completer [] { ["basic" "professional" "starter"] }
def resource-type-completer [] { ["droplet" "volume"] }
def type-completer-7 [] { ["http" "https" "ping"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "1-clicks list-one" } } | get name | first)
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

# List 1-Click Applications
#
# GET /v2/1-clicks
# operationId: oneClicks_list
export def "1-clicks list-one" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Restrict results to a certain type of 1-Click. (e.g. kubernetes)
]: nothing -> record<1_clicks: table<slug: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/1-clicks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install Kubernetes 1-Click Applications
#
# POST /v2/1-clicks/kubernetes
# operationId: oneClicks_install_kubernetes
export def "1-clicks-kubernetes create-one-install" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  addon_slugs: list<string> # An array of 1-Click Application slugs to be installed to the Kubernetes cluster. (default: [], e.g. [kube-state-metrics, loki])
  cluster_uuid: string # A unique ID for the Kubernetes cluster to which the 1-Click Applications will be installed. (e.g. 50a994b6-c303-438f-9495-7e896cfe6b08)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/1-clicks/kubernetes")
  let req_body = {"addon_slugs": $addon_slugs, "cluster_uuid": $cluster_uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get User Information
#
# GET /v2/account
# operationId: account_get
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: record<droplet_limit: int, email: string, email_verified: bool, floating_ip_limit: int, status: string, status_message: string, team: record<name: string, uuid: string>, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All SSH Keys
#
# GET /v2/account/keys
# operationId: sshKeys_list
export def "account-keys list-ssh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<ssh_keys: table<fingerprint: string, id: int, name: string, public_key: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/account/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New SSH Key
#
# POST /v2/account/keys
# operationId: sshKeys_create
export def "account-keys create-ssh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A human-readable display name for this key, used to easily identify the SSH keys when they are displayed. (e.g. My SSH Public Key)
  public_key: string # The entire public key string that was uploaded. Embedded into the root user's `authorized_keys` file if you include this key during Droplet creation. (e.g. ssh-rsa AEXAMPLEaC1yc2EAAAADAQABAAAAQQDDHr/jh2Jy4yALcK4JyWbVkPRaWmhck3IgCoeOO3z1e2dBowLh64QAM+Qb72pxekALga2oi4GvT+TlWNhzPH4V example)
]: any -> record<ssh_key: record<fingerprint: string, id: int, name: string, public_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account/keys")
  let req_body = {"name": $name, "public_key": $public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an SSH Key
#
# DELETE /v2/account/keys/{ssh_key_identifier}
# operationId: sshKeys_delete
export def "account-keys delete" [
  ssh_key_identifier: any
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
  let full_url = (build-url $base ({ssh_key_identifier: (encode-path-segment $ssh_key_identifier)} | format pattern "/v2/account/keys/{ssh_key_identifier}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing SSH Key
#
# GET /v2/account/keys/{ssh_key_identifier}
# operationId: sshKeys_get
export def "account-keys get" [
  ssh_key_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ssh_key: record<fingerprint: string, id: int, name: string, public_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ssh_key_identifier: (encode-path-segment $ssh_key_identifier)} | format pattern "/v2/account/keys/{ssh_key_identifier}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an SSH Key's Name
#
# PUT /v2/account/keys/{ssh_key_identifier}
# operationId: sshKeys_update
export def "account-keys update" [
  ssh_key_identifier: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human-readable display name for this key, used to easily identify the SSH keys when they are displayed. (e.g. My SSH Public Key)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ssh_key_identifier: (encode-path-segment $ssh_key_identifier)} | format pattern "/v2/account/keys/{ssh_key_identifier}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Actions
#
# GET /v2/actions
# operationId: actions_list
export def "actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<actions: table<completed_at: string, id: int, region: record, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Action
#
# GET /v2/actions/{action_id}
# operationId: actions_get
export def "actions get" [
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({action_id: (encode-path-segment $action_id)} | format pattern "/v2/actions/{action_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Apps
#
# GET /v2/apps
# operationId: apps_list
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --with-projects: oneof<nothing, bool> # Whether the project_id of listed apps should be fetched and included. (e.g. true)
]: nothing -> record<apps: table<active_deployment: record, created_at: string, default_ingress: string, domains: list, id: string, in_progress_deployment: record, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record, pinned_deployment: record, project_id: string, region: record, spec: record, tier_slug: string, updated_at: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "with_projects" $with_projects "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New App
#
# POST /v2/apps
# operationId: apps_create
# --spec shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
export def "apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string@accept-completer # The content-type that should be used by the response. By default, the response will be `application/json`. `application/yaml` is also supported. (e.g. application/json)
  --content-type: string@content-type-completer # The content-type used for the request. By default, the requests are assumed to use `application/json`. `application/yaml` is also supported. (e.g. application/json)
  --project-id: string # The ID of the project the app should be assigned to. If omitted, it will be assigned to your default project.
  spec: record # The desired configuration of an application. — shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
]: any -> record<app: record<active_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, created_at: string, default_ingress: string, domains: list<record>, id: string, in_progress_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, pinned_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, project_id: string, region: record<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, tier_slug: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps")
  let req_body = {"project_id": $project_id, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Retrieve Multiple Apps' Daily Bandwidth Metrics
#
# POST /v2/apps/metrics/bandwidth_daily
# operationId: apps_list_metrics_bandwidth_daily
export def "apps-metrics-bandwidth-daily list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  app_ids: list<string> # A list of app IDs to query bandwidth metrics for. (e.g. [4f6c71e2-1e90-4762-9fee-6cc4a0a9f2cf, c2a93513-8d9b-4223-9d61-5e7272c81cf5])
  --date: string # Optional day to query. Only the date component of the timestamp will be considered. Default: yesterday. (format: date-time, e.g. 2023-01-17T00:00:00Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/metrics/bandwidth_daily")
  let req_body = {"app_ids": $app_ids, "date": $date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Propose an App Spec
#
# POST /v2/apps/propose
# operationId: apps_validate_appSpec
# --spec shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
export def "apps-propose validate-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # An optional ID of an existing app. If set, the spec will be treated as a proposed update to the specified app. The existing app is not modified using this method. (e.g. b6bdf840-2854-4f87-a36c-5f231c617c84)
  spec: record # The desired configuration of an application. — shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
]: any -> record<app_cost: int, app_is_static: bool, app_name_available: bool, app_name_suggestion: string, app_tier_downgrade_cost: int, existing_static_apps: string, spec: record<databases: list<record>, domains: list<record>, functions: list<record>, jobs: list<record>, name: string, region: string, services: list<record>, static_sites: list<record>, workers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/propose")
  let req_body = {"app_id": $app_id, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List App Regions
#
# GET /v2/apps/regions
# operationId: apps_list_regions
export def "apps-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<regions: table<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List App Tiers
#
# GET /v2/apps/tiers
# operationId: apps_list_tiers
export def "apps-tiers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tiers: table<build_seconds: string, egress_bandwidth_bytes: string, name: string, slug: string, storage_bytes: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/tiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Instance Sizes
#
# GET /v2/apps/tiers/instance_sizes
# operationId: apps_list_instanceSizes
export def "apps-tiers-instance-sizes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<discount_percent: float, instance_sizes: table<cpu_type: string, cpus: string, memory_bytes: string, name: string, slug: string, tier_downgrade_to: string, tier_slug: string, tier_upgrade_to: string, usd_per_month: string, usd_per_second: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/tiers/instance_sizes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Instance Size
#
# GET /v2/apps/tiers/instance_sizes/{slug}
# operationId: apps_get_instanceSize
export def "apps-tiers-instance-sizes get" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<instance_size: record<cpu_type: string, cpus: string, memory_bytes: string, name: string, slug: string, tier_downgrade_to: string, tier_slug: string, tier_upgrade_to: string, usd_per_month: string, usd_per_second: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/v2/apps/tiers/instance_sizes/{slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an App Tier
#
# GET /v2/apps/tiers/{slug}
# operationId: apps_get_tier
export def "apps-tiers get" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tier: record<build_seconds: string, egress_bandwidth_bytes: string, name: string, slug: string, storage_bytes: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/v2/apps/tiers/{slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all app alerts
#
# GET /v2/apps/{app_id}/alerts
# operationId: apps_list_alerts
export def "apps-alerts list" [
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alerts: table<component_name: string, emails: list, id: string, phase: string, progress: record, slack_webhooks: list, spec: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/alerts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update destinations for alerts
#
# POST /v2/apps/{app_id}/alerts/{alert_id}/destinations
# operationId: apps_assign_alertDestinations
export def "apps-alerts-destinations assign" [
  app_id: any
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list # e.g. [sammy@digitalocean.com]
  --slack-webhooks: list
]: any -> record<alert: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/apps/{app_id}/alerts/{alert_id}/destinations"))
  let req_body = {"emails": $emails, "slack_webhooks": $slack_webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve Active Deployment Logs
#
# GET /v2/apps/{app_id}/components/{component_name}/logs
# operationId: apps_get_logs_active_deployment
export def "apps-components-logs get-active-deployment" [
  app_id: string
  component_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: oneof<nothing, bool> # Whether the logs should follow live updates. (e.g. true)
  --type: string@type-completer-1 # The type of logs to retrieve - BUILD: Build-time logs - DEPLOY: Deploy-time logs - RUN: Live run-time logs (default: UNSPECIFIED, e.g. BUILD)
  --pod-connection-timeout: string # An optional time duration to wait if the underlying component instance is not immediately available. Default: `3m`. (e.g. 3m)
]: nothing -> record<historic_urls: list<string>, live_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pod_connection_timeout" $pod_connection_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), component_name: (encode-path-segment $component_name)} | format pattern "/v2/apps/{app_id}/components/{component_name}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List App Deployments
#
# GET /v2/apps/{app_id}/deployments
# operationId: apps_list_deployments
export def "apps-deployments list" [
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
]: nothing -> record<deployments: table<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/deployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an App Deployment
#
# POST /v2/apps/{app_id}/deployments
# operationId: apps_create_deployment
export def "apps-deployments create" [
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-build: oneof<nothing, bool> # e.g. true
]: any -> record<deployment: record<cause: string, cloned_from: string, created_at: string, functions: list<record>, id: string, jobs: list<record>, phase: string, phase_last_updated_at: string, progress: record<error_steps: int, pending_steps: int, running_steps: int, steps: list, success_steps: int, summary_steps: list, total_steps: int>, services: list<record>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, static_sites: list<record>, tier_slug: string, updated_at: string, workers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/deployments"))
  let req_body = {"force_build": $force_build} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve an App Deployment
#
# GET /v2/apps/{app_id}/deployments/{deployment_id}
# operationId: apps_get_deployment
export def "apps-deployments get" [
  app_id: any
  deployment_id: string
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a Deployment
#
# POST /v2/apps/{app_id}/deployments/{deployment_id}/cancel
# operationId: apps_cancel_deployment
export def "apps-deployments-cancel cancel" [
  app_id: any
  deployment_id: any
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Deployment Logs
#
# GET /v2/apps/{app_id}/deployments/{deployment_id}/components/{component_name}/logs
# operationId: apps_get_logs
export def "apps-deployments-components-logs get" [
  app_id: any
  deployment_id: any
  component_name: any
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id), component_name: (encode-path-segment $component_name)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}/components/{component_name}/logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Aggregate Deployment Logs
#
# GET /v2/apps/{app_id}/deployments/{deployment_id}/logs
# operationId: apps_get_logs_aggregate
export def "apps-deployments-logs get-aggregate" [
  app_id: any
  deployment_id: any
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}/logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Active Deployment Aggregate Logs
#
# GET /v2/apps/{app_id}/logs
# operationId: apps_get_logs_active_deployment_aggregate
export def "apps-logs get-active-deployment-aggregate" [
  app_id: any
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve App Daily Bandwidth Metrics
#
# GET /v2/apps/{app_id}/metrics/bandwidth_daily
# operationId: apps_get_metrics_bandwidth_daily
export def "apps-metrics-bandwidth-daily get" [
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Optional day to query. Only the date component of the timestamp will be considered. Default: yesterday. (format: date-time, e.g. 2023-01-17T00:00:00Z)
]: nothing -> record<app_bandwidth_usage: table<app_id: string, bandwidth_bytes: string>, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/metrics/bandwidth_daily") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rollback App
#
# POST /v2/apps/{app_id}/rollback
# operationId: apps_create_rollback
export def "apps-rollback create" [
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string # The ID of the deployment to rollback to. (e.g. 3aa4d20e-5527-4c00-b496-601fbd22520a)
  --skip-pin: oneof<nothing, bool> # Whether to skip pinning the rollback deployment. If false, the rollback deployment will be pinned and any new deployments including Auto Deploy on Push hooks will be disabled until the rollback is either manually committed or reverted via the CommitAppRollback or RevertAppRollback endpoints respectively. If true, the rollback will be immediately committed and the app will remain unpinned. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback"))
  let req_body = {"deployment_id": $deployment_id, "skip_pin": $skip_pin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Commit App Rollback
#
# POST /v2/apps/{app_id}/rollback/commit
# operationId: apps_commit_rollback
export def "apps-rollback-commit commit" [
  app_id: any
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback/commit"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revert App Rollback
#
# POST /v2/apps/{app_id}/rollback/revert
# operationId: apps_revert_rollback
export def "apps-rollback-revert create" [
  app_id: any
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback/revert"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate App Rollback
#
# POST /v2/apps/{app_id}/rollback/validate
# operationId: apps_validate_rollback
export def "apps-rollback-validate validate" [
  app_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<error: record<code: string, components: list<string>, message: string>, valid: bool, warnings: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback/validate"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an App
#
# DELETE /v2/apps/{id}
# operationId: apps_delete
export def "apps delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/apps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing App
#
# GET /v2/apps/{id}
# operationId: apps_get
export def "apps get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the app to retrieve. (e.g. myApp)
]: nothing -> record<app: record<active_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, created_at: string, default_ingress: string, domains: list<record>, id: string, in_progress_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, pinned_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, project_id: string, region: record<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, tier_slug: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/apps/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an App
#
# PUT /v2/apps/{id}
# operationId: apps_update
# --spec shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
export def "apps update" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  spec: record # The desired configuration of an application. — shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
]: any -> record<app: record<active_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, created_at: string, default_ingress: string, domains: list<record>, id: string, in_progress_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, pinned_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, project_id: string, region: record<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, tier_slug: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/apps/{id}"))
  let req_body = {"spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All CDN Endpoints
#
# GET /v2/cdn/endpoints
# operationId: cdn_list_endpoints
export def "cdn-endpoints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<endpoints: table<certificate_id: string, created_at: string, custom_domain: string, endpoint: string, id: string, origin: string, ttl: int>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cdn/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New CDN Endpoint
#
# POST /v2/cdn/endpoints
# operationId: cdn_create_endpoint
export def "cdn-endpoints create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-id: string # The ID of a DigitalOcean managed TLS certificate used for SSL when a custom subdomain is provided. (format: uuid, e.g. 892071a0-bb95-49bc-8021-3afd67a210bf)
  --custom-domain: string # The fully qualified domain name (FQDN) of the custom subdomain used with the CDN endpoint. (format: hostname, e.g. static.example.com)
  origin: string # The fully qualified domain name (FQDN) for the origin server which provides the content for the CDN. This is currently restricted to a Space. (format: hostname, e.g. static-images.nyc3.digitaloceanspaces.com)
  --ttl: int@ttl-completer # The amount of time the content is cached by the CDN's edge servers in seconds. TTL must be one of 60, 600, 3600, 86400, or 604800. Defaults to 3600 (one hour) when excluded. (default: 3600, e.g. 3600)
]: any -> record<endpoint: record<certificate_id: string, created_at: string, custom_domain: string, endpoint: string, id: string, origin: string, ttl: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/cdn/endpoints")
  let req_body = {"certificate_id": $certificate_id, "custom_domain": $custom_domain, "origin": $origin, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a CDN Endpoint
#
# DELETE /v2/cdn/endpoints/{cdn_id}
# operationId: cdn_delete_endpoint
export def "cdn-endpoints delete" [
  cdn_id: any
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
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing CDN Endpoint
#
# GET /v2/cdn/endpoints/{cdn_id}
# operationId: cdn_get_endpoint
export def "cdn-endpoints get" [
  cdn_id: string
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
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a CDN Endpoint
#
# PUT /v2/cdn/endpoints/{cdn_id}
# operationId: cdn_update_endpoints
export def "cdn-endpoints update" [
  cdn_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-id: string # The ID of a DigitalOcean managed TLS certificate used for SSL when a custom subdomain is provided. (format: uuid, e.g. 892071a0-bb95-49bc-8021-3afd67a210bf)
  --custom-domain: string # The fully qualified domain name (FQDN) of the custom subdomain used with the CDN endpoint. (format: hostname, e.g. static.example.com)
  --ttl: int@ttl-completer # The amount of time the content is cached by the CDN's edge servers in seconds. TTL must be one of 60, 600, 3600, 86400, or 604800. Defaults to 3600 (one hour) when excluded. (default: 3600, e.g. 3600)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}"))
  let req_body = {"certificate_id": $certificate_id, "custom_domain": $custom_domain, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Purge the Cache for an Existing CDN Endpoint
#
# DELETE /v2/cdn/endpoints/{cdn_id}/cache
# operationId: cdn_purge_cache
export def "cdn-endpoints-cache delete-purge" [
  cdn_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  files: list<string> # An array of strings containing the path to the content to be purged from the CDN cache. (e.g. [path/to/image.png, path/to/css/*])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}/cache"))
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Certificates
#
# GET /v2/certificates
# operationId: certificates_list
export def "certificates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<certificates: table<created_at: string, dns_names: list, id: string, name: string, not_after: string, sha1_fingerprint: string, state: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Certificate
#
# POST /v2/certificates
# operationId: certificates_create
export def "certificates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<certificate: record<created_at: string, dns_names: list<string>, id: string, name: string, not_after: string, sha1_fingerprint: string, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/certificates")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Certificate
#
# DELETE /v2/certificates/{certificate_id}
# operationId: certificates_delete
export def "certificates delete" [
  certificate_id: any
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
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v2/certificates/{certificate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Certificate
#
# GET /v2/certificates/{certificate_id}
# operationId: certificates_get
export def "certificates get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: record<created_at: string, dns_names: list<string>, id: string, name: string, not_after: string, sha1_fingerprint: string, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v2/certificates/{certificate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Customer Balance
#
# GET /v2/customers/my/balance
# operationId: balance_get
export def "customers-my-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_balance: string, generated_at: string, month_to_date_balance: string, month_to_date_usage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/my/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Billing History
#
# GET /v2/customers/my/billing_history
# operationId: billingHistory_list
export def "customers-my-billing-history list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing_history: table<amount: string, date: string, description: string, invoice_id: string, invoice_uuid: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/my/billing_history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Invoices
#
# GET /v2/customers/my/invoices
# operationId: invoices_list
export def "customers-my-invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<invoice_preview: record<amount: string, invoice_period: string, invoice_uuid: string, updated_at: string>, invoices: table<amount: string, invoice_period: string, invoice_uuid: string, updated_at: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/my/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Invoice by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}
# operationId: invoices_get_byUUID
export def "customers-my-invoices get" [
  invoice_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<invoice_items: table<amount: string, description: string, duration: string, duration_unit: string, end_time: string, group_description: string, product: string, project_name: string, resource_id: string, resource_uuid: string, start_time: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Invoice CSV by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}/csv
# operationId: invoices_get_csvByUUID
export def "customers-my-invoices-csv get" [
  invoice_uuid: any
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
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}/csv"))
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Invoice PDF by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}/pdf
# operationId: invoices_get_pdfByUUID
export def "customers-my-invoices-pdf get" [
  invoice_uuid: any
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
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}/pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Invoice Summary by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}/summary
# operationId: invoices_get_summaryByUUID
export def "customers-my-invoices-summary get" [
  invoice_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: string, billing_period: string, credits_and_adjustments: record, invoice_uuid: string, overages: record<amount: string, name: string>, product_charges: record<amount: string, items: list<record>, name: string>, taxes: record, user_billing_address: record<address_line1: string, address_line2: string, city: string, country_iso2_code: string, created_at: string, postal_code: string, region: string, updated_at: string>, user_company: string, user_email: string, user_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}/summary"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Database Clusters
#
# GET /v2/databases
# operationId: databases_list_clusters
export def "databases list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-name: string # Limits the results to database clusters with a specific tag. (e.g. production)
]: nothing -> record<databases: table<connection: record, created_at: string, db_names: list, engine: string, id: string, maintenance_window: record, name: string, num_nodes: int, private_connection: record, private_network_uuid: string, project_id: string, region: string, rules: list, size: string, status: string, tags: list, users: list, version: string, version_end_of_availability: string, version_end_of_life: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_name" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/databases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Database Cluster
#
# POST /v2/databases
# operationId: databases_create_cluster
# --rules item shape: {cluster_uuid?: string, type: "droplet"|"k8s"|"ip_addr"|"tag"|"app", uuid?: string, value: string}
# --users item shape: {mysql_settings?: record, name: string}
# --backup_restore shape: {backup_created_at?: string, database_name: string}
export def "databases create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: any
  engine: string@engine-completer # A slug representing the database engine used for the cluster. The possible values are: "pg" for PostgreSQL, "mysql" for MySQL, "redis" for Redis, and "mongodb" for MongoDB. (e.g. pg)
  --maintenance-window: any
  name: string # A unique, human-readable name referring to a database cluster. (e.g. backend)
  num_nodes: int # The number of nodes in the database cluster. (e.g. 2)
  --private-connection: any
  --private-network-uuid: string # A string specifying the UUID of the VPC to which the database cluster will be assigned. If excluded, the cluster when creating a new database cluster, it will be assigned to your account's default VPC for the region. (e.g. d455e75d-4858-4eec-8c95-da2f0a5f93a7)
  --project-id: string # The ID of the project that the database cluster is assigned to. If excluded when creating a new database cluster, it will be assigned to your default project. (format: uuid, e.g. 9cc10173-e9ea-4176-9dbc-a4cee4c4ff30)
  region: string # The slug identifier for the region where the database cluster is located. (e.g. nyc3)
  --rules: list # item shape: {cluster_uuid?: string, type: "droplet"|"k8s"|"ip_addr"|"tag"|"app", uuid?: string, value: string}
  size: string # The slug identifier representing the size of the nodes in the database cluster. (e.g. db-s-2vcpu-4gb)
  --tags: list<string> # An array of tags that have been applied to the database cluster. (nullable, e.g. [production])
  --version: string # A string representing the version of the database engine in use for the cluster. (e.g. 10)
  --backup-restore: record # shape: {backup_created_at?: string, database_name: string}
]: any -> record<database: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, created_at: string, db_names: list<string>, engine: string, id: string, maintenance_window: record<day: string, description: list, hour: string, pending: bool>, name: string, num_nodes: int, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, private_network_uuid: string, project_id: string, region: string, rules: list<record>, size: string, status: string, tags: list<string>, users: list<record>, version: string, version_end_of_availability: string, version_end_of_life: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/databases")
  let req_body = {"connection": $connection, "engine": $engine, "maintenance_window": $maintenance_window, "name": $name, "num_nodes": $num_nodes, "private_connection": $private_connection, "private_network_uuid": $private_network_uuid, "project_id": $project_id, "region": $region, "rules": $rules, "size": $size, "tags": $tags, "version": $version, "backup_restore": $backup_restore} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Database Options
#
# GET /v2/databases/options
# operationId: databases_list_options
export def "databases-options list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<options: record<mongodb: record<regions: list, versions: list, layouts: list>, mysql: record<regions: list, versions: list, layouts: list>, pg: record<regions: list, versions: list, layouts: list>, redis: record<regions: list, versions: list, layouts: list>>, version_availability: record<mongodb: list<record>, mysql: list<record>, pg: list<record>, redis: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/databases/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Destroy a Database Cluster
#
# DELETE /v2/databases/{database_cluster_uuid}
# operationId: databases_destroy_cluster
export def "databases delete" [
  database_cluster_uuid: any
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Database Cluster
#
# GET /v2/databases/{database_cluster_uuid}
# operationId: databases_get_cluster
export def "databases get" [
  database_cluster_uuid: string
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Backups for a Database Cluster
#
# GET /v2/databases/{database_cluster_uuid}/backups
# operationId: databases_list_backups
export def "databases-backups list" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<backups: table<created_at: string, size_gigabytes: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/backups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Public Certificate
#
# GET /v2/databases/{database_cluster_uuid}/ca
# operationId: databases_get_ca
export def "databases-ca get" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ca: record<certificate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/ca"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Database Cluster Configuration
#
# GET /v2/databases/{database_cluster_uuid}/config
# operationId: databases_get_config
export def "databases-config get" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Database Configuration for an Existing Database
#
# PATCH /v2/databases/{database_cluster_uuid}/config
# operationId: databases_patch_config
export def "databases-config update" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/config"))
  let req_body = {"config": $config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Databases
#
# GET /v2/databases/{database_cluster_uuid}/dbs
# operationId: databases_list
export def "databases-dbs list" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dbs: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a New Database
#
# POST /v2/databases/{database_cluster_uuid}/dbs
# operationId: databases_add
export def "databases-dbs create" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<db: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Database
#
# DELETE /v2/databases/{database_cluster_uuid}/dbs/{database_name}
# operationId: databases_delete
export def "databases-dbs delete" [
  database_cluster_uuid: any
  database_name: any
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), database_name: (encode-path-segment $database_name)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs/{database_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Database
#
# GET /v2/databases/{database_cluster_uuid}/dbs/{database_name}
# operationId: databases_get
export def "databases-dbs get" [
  database_cluster_uuid: any
  database_name: string
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), database_name: (encode-path-segment $database_name)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs/{database_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Eviction Policy for a Redis Cluster
#
# GET /v2/databases/{database_cluster_uuid}/eviction_policy
# operationId: databases_get_evictionPolicy
export def "databases-eviction-policy get" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<eviction_policy: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/eviction_policy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure the Eviction Policy for a Redis Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/eviction_policy
# operationId: databases_update_evictionPolicy
export def "databases-eviction-policy update" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  eviction_policy: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/eviction_policy"))
  let req_body = {"eviction_policy": $eviction_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Firewall Rules (Trusted Sources) for a Database Cluster
#
# GET /v2/databases/{database_cluster_uuid}/firewall
# operationId: databases_list_firewall_rules
export def "databases-firewall list-rules" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rules: table<cluster_uuid: string, created_at: string, type: string, uuid: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/firewall"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Firewall Rules (Trusted Sources) for a Database
#
# PUT /v2/databases/{database_cluster_uuid}/firewall
# operationId: databases_update_firewall_rules
# --rules item shape: {cluster_uuid?: string, type: "droplet"|"k8s"|"ip_addr"|"tag"|"app", uuid?: string, value: string}
export def "databases-firewall update-rules" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # item shape: {cluster_uuid?: string, type: "droplet"|"k8s"|"ip_addr"|"tag"|"app", uuid?: string, value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/firewall"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Configure a Database Cluster's Maintenance Window
#
# PUT /v2/databases/{database_cluster_uuid}/maintenance
# operationId: databases_update_maintenanceWindow
export def "databases-maintenance update-window" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  day: string # The day of the week on which to apply maintenance updates. (e.g. tuesday)
  hour: string # The hour in UTC at which maintenance updates will be applied in 24 hour format. (e.g. 14:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/maintenance"))
  let req_body = {"day": $day, "hour": $hour} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Migrate a Database Cluster to a New Region
#
# PUT /v2/databases/{database_cluster_uuid}/migrate
# operationId: databases_update_region
export def "databases-migrate update-region" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  region: string # A slug identifier for the region to which the database cluster will be migrated. (e.g. lon1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/migrate"))
  let req_body = {"region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve the Status of an Online Migration
#
# GET /v2/databases/{database_cluster_uuid}/online-migration
# operationId: databases_get_migrationStatus
export def "databases-online-migration get-status" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/online-migration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start an Online Migration
#
# PUT /v2/databases/{database_cluster_uuid}/online-migration
# operationId: databases_update_onlineMigration
export def "databases-online-migration update" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disable-ssl: oneof<nothing, bool> # Enables SSL encryption when connecting to the source database. (e.g. false)
  --body-source: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/online-migration"))
  let req_body = {"disable_ssl": $disable_ssl, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stop an Online Migration
#
# DELETE /v2/databases/{database_cluster_uuid}/online-migration/{migration_id}
# operationId: databases_delete_onlineMigration
export def "databases-online-migration delete" [
  database_cluster_uuid: any
  migration_id: string
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), migration_id: (encode-path-segment $migration_id)} | format pattern "/v2/databases/{database_cluster_uuid}/online-migration/{migration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Connection Pools (PostgreSQL)
#
# GET /v2/databases/{database_cluster_uuid}/pools
# operationId: databases_list_connectionPools
export def "databases-pools list-connection" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pools: table<connection: record, db: string, mode: string, name: string, private_connection: record, size: int, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/pools"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a New Connection Pool (PostgreSQL)
#
# POST /v2/databases/{database_cluster_uuid}/pools
# operationId: databases_add_connectionPool
export def "databases-pools create-connection" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<pool: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/pools"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Connection Pool (PostgreSQL)
#
# DELETE /v2/databases/{database_cluster_uuid}/pools/{pool_name}
# operationId: databases_delete_connectionPool
export def "databases-pools delete-connection" [
  database_cluster_uuid: any
  pool_name: any
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), pool_name: (encode-path-segment $pool_name)} | format pattern "/v2/databases/{database_cluster_uuid}/pools/{pool_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Existing Connection Pool (PostgreSQL)
#
# GET /v2/databases/{database_cluster_uuid}/pools/{pool_name}
# operationId: databases_get_connectionPool
export def "databases-pools get-connection" [
  database_cluster_uuid: any
  pool_name: string
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), pool_name: (encode-path-segment $pool_name)} | format pattern "/v2/databases/{database_cluster_uuid}/pools/{pool_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Connection Pools (PostgreSQL)
#
# PUT /v2/databases/{database_cluster_uuid}/pools/{pool_name}
# operationId: databases_update_connectionPool
export def "databases-pools update-connection" [
  database_cluster_uuid: any
  pool_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  db: string # The database for use with the connection pool. (e.g. defaultdb)
  mode: string # The PGBouncer transaction mode for the connection pool. The allowed values are session, transaction, and statement. (e.g. transaction)
  size: int # The desired size of the PGBouncer connection pool. The maximum allowed size is determined by the size of the cluster's primary node. 25 backend server connections are allowed for every 1GB of RAM. Three are reserved for maintenance. For example, a primary node with 1 GB of RAM allows for a maximum of 22 backend server connections while one with 4 GB would allow for 97. Note that these are shared across all connection pools in a cluster. (format: int32, e.g. 10)
  --user: string # The name of the user for use with the connection pool. When excluded, all sessions connect to the database as the inbound user. (e.g. doadmin)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), pool_name: (encode-path-segment $pool_name)} | format pattern "/v2/databases/{database_cluster_uuid}/pools/{pool_name}"))
  let req_body = {"db": $db, "mode": $mode, "size": $size, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Read-only Replicas
#
# GET /v2/databases/{database_cluster_uuid}/replicas
# operationId: databases_list_replicas
export def "databases-replicas list" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<replicas: table<connection: record, created_at: string, id: string, name: string, private_connection: record, private_network_uuid: string, region: string, size: string, status: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Read-only Replica
#
# POST /v2/databases/{database_cluster_uuid}/replicas
# operationId: databases_create_replica
export def "databases-replicas create" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<replica: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Destroy a Read-only Replica
#
# DELETE /v2/databases/{database_cluster_uuid}/replicas/{replica_name}
# operationId: databases_destroy_replica
export def "databases-replicas delete" [
  database_cluster_uuid: any
  replica_name: any
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), replica_name: (encode-path-segment $replica_name)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas/{replica_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Read-only Replica
#
# GET /v2/databases/{database_cluster_uuid}/replicas/{replica_name}
# operationId: databases_get_replica
export def "databases-replicas get" [
  database_cluster_uuid: any
  replica_name: string
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), replica_name: (encode-path-segment $replica_name)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas/{replica_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote a Read-only Replica to become a Primary Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/replicas/{replica_name}/promote
# operationId: databases_promote_replica
export def "databases-replicas-promote update" [
  database_cluster_uuid: any
  replica_name: any
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), replica_name: (encode-path-segment $replica_name)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas/{replica_name}/promote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resize a Database Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/resize
# operationId: databases_update_clusterSize
export def "databases-resize update-size" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  num_nodes: int # The number of nodes in the database cluster. Valid values are are 1-3. In addition to the primary node, up to two standby nodes may be added for highly available configurations. (format: int32, e.g. 3)
  size: string # A slug identifier representing desired the size of the nodes in the database cluster. (e.g. db-s-4vcpu-8gb)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/resize"))
  let req_body = {"num_nodes": $num_nodes, "size": $size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve the SQL Modes for a MySQL Cluster
#
# GET /v2/databases/{database_cluster_uuid}/sql_mode
# operationId: databases_get_sql_mode
export def "databases-sql-mode get" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sql_mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/sql_mode"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SQL Mode for a Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/sql_mode
# operationId: databases_update_sql_mode
export def "databases-sql-mode update" [
  database_cluster_uuid: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/sql_mode"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Upgrade Major Version for a Database
#
# PUT /v2/databases/{database_cluster_uuid}/upgrade
# operationId: databases_update_major_version
export def "databases-upgrade update-major-version" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # A string representing the version of the database engine in use for the cluster. (e.g. 10)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/upgrade"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all Database Users
#
# GET /v2/databases/{database_cluster_uuid}/users
# operationId: databases_list_users
export def "databases-users list" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<mysql_settings: record, name: string, password: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Database User
#
# POST /v2/databases/{database_cluster_uuid}/users
# operationId: databases_add_user
# --mysql_settings shape: {auth_plugin: "mysql_native_password"|"caching_sha2_password"}
export def "databases-users create" [
  database_cluster_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mysql-settings: record # shape: {auth_plugin: "mysql_native_password"|"caching_sha2_password"}
  name: string # The name of a database user. (e.g. app-01)
]: any -> record<user: record<mysql_settings: record<auth_plugin: string>, name: string, password: string, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/users"))
  let req_body = {"mysql_settings": $mysql_settings, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove a Database User
#
# DELETE /v2/databases/{database_cluster_uuid}/users/{username}
# operationId: databases_delete_user
export def "databases-users delete" [
  database_cluster_uuid: any
  username: any
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), username: (encode-path-segment $username)} | format pattern "/v2/databases/{database_cluster_uuid}/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Database User
#
# GET /v2/databases/{database_cluster_uuid}/users/{username}
# operationId: databases_get_user
export def "databases-users get" [
  database_cluster_uuid: any
  username: string
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
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), username: (encode-path-segment $username)} | format pattern "/v2/databases/{database_cluster_uuid}/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset a Database User's Password or Authentication Method
#
# POST /v2/databases/{database_cluster_uuid}/users/{username}/reset_auth
# operationId: databases_reset_auth
# --mysql_settings shape: {auth_plugin: "mysql_native_password"|"caching_sha2_password"}
export def "databases-users-reset-auth reset" [
  database_cluster_uuid: any
  username: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mysql-settings: record # shape: {auth_plugin: "mysql_native_password"|"caching_sha2_password"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), username: (encode-path-segment $username)} | format pattern "/v2/databases/{database_cluster_uuid}/users/{username}/reset_auth"))
  let req_body = {"mysql_settings": $mysql_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Domains
#
# GET /v2/domains
# operationId: domains_list
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<domains: table<ip_address: string, name: string, ttl: int, zone_file: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Domain
#
# POST /v2/domains
# operationId: domains_create
export def "domains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip-address: string # This optional attribute may contain an IP address. When provided, an A record will be automatically created pointing to the apex domain. (e.g. 192.0.2.1)
  --name: string # The name of the domain itself. This should follow the standard domain format of domain.TLD. For instance, `example.com` is a valid domain name. (e.g. example.com)
]: any -> record<domain: record<ip_address: string, name: string, ttl: int, zone_file: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/domains")
  let req_body = {"ip_address": $ip_address, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Domain
#
# DELETE /v2/domains/{domain_name}
# operationId: domains_delete
export def "domains delete" [
  domain_name: any
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
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Domain
#
# GET /v2/domains/{domain_name}
# operationId: domains_get
export def "domains get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: record<ip_address: string, name: string, ttl: int, zone_file: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Domain Records
#
# GET /v2/domains/{domain_name}/records
# operationId: domains_list_records
export def "domains-records list" [
  domain_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A fully qualified record name. For example, to only include records matching sub.example.com, send a GET request to `/v2/domains/$DOMAIN_NAME/records?name=sub.example.com`. (e.g. sub.example.com)
  --type: string@type-completer-2 # The type of the DNS record. For example: A, CNAME, TXT, ... (e.g. A)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<domain_records: table<data: string, flags: int, id: int, name: string, port: int, priority: int, tag: string, ttl: int, type: string, weight: int>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Domain Record
#
# POST /v2/domains/{domain_name}/records
# Discriminator (request): type = A, AAAA, CAA, CNAME, MX, NS, SOA, SRV, TXT
# operationId: domains_create_record
export def "domains-records create" [
  domain_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<domain_record: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}/records"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Domain Record
#
# DELETE /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_delete_record
export def "domains-records delete" [
  domain_name: any
  domain_record_id: any
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
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Domain Record
#
# GET /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_get_record
export def "domains-records get" [
  domain_name: any
  domain_record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_record: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Domain Record
#
# PATCH /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_patch_record
export def "domains-records update-by-domain_name-domain_record_id" [
  domain_name: any
  domain_record_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update a Domain Record
#
# PUT /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_update_record
export def "domains-records update-by-domain_name-domain_record_id-1" [
  domain_name: any
  domain_record_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deleting Droplets by Tag
#
# DELETE /v2/droplets
# operationId: droplets_destroy_byTag
export def "droplets delete-by-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-name: string # Specifies Droplets to be deleted by tag. (e.g. env:test)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_name" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/droplets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Droplets
#
# GET /v2/droplets
# operationId: droplets_list
export def "droplets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --tag-name: string # Used to filter Droplets by a specific tag. Can not be combined with `name`. (e.g. env:prod)
  --name: string # Used to filter list response by Droplet name returning only exact matches. It is case-insensitive and can not be combined with `tag_name`. (e.g. web-01)
]: nothing -> record<droplets: table<backup_ids: list, created_at: string, disk: int, features: list, id: int, image: record, kernel: record, locked: bool, memory: int, name: string, networks: record, next_backup_window: record, region: record, size: record, size_slug: string, snapshot_ids: list, status: string, tags: list, vcpus: int, volume_ids: list, vpc_uuid: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "tag_name" $tag_name "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/droplets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Droplet
#
# POST /v2/droplets
# operationId: droplets_create
export def "droplets create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/droplets")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Acting on Tagged Droplets
#
# POST /v2/droplets/actions
# Discriminator (request): type = disable_backups, enable_backups, enable_ipv6, power_cycle, power_off, power_on, shutdown, snapshot
# operationId: dropletActions_post_byTag
export def "droplets-actions create-by-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-name: string # Used to filter Droplets by a specific tag. Can not be combined with `name`. (e.g. env:prod)
  --body: record
]: any -> record<actions: table<completed_at: string, id: int, region: record, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_name" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/droplets/actions" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an Existing Droplet
#
# DELETE /v2/droplets/{droplet_id}
# operationId: droplets_destroy
export def "droplets delete" [
  droplet_id: any
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
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Droplet
#
# GET /v2/droplets/{droplet_id}
# operationId: droplets_get
export def "droplets get" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<droplet: record<backup_ids: list<int>, created_at: string, disk: int, features: list<string>, id: int, image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list, size_gigabytes: float, slug: string, status: string, tags: list, type: string>, kernel: record<id: int, name: string, version: string>, locked: bool, memory: int, name: string, networks: record<v4: list, v6: list>, next_backup_window: record<end: string, start: string>, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, size: record<available: bool, description: string, disk: int, memory: int, price_hourly: float, price_monthly: float, regions: list, slug: string, transfer: float, vcpus: int>, size_slug: string, snapshot_ids: list<int>, status: string, tags: list<string>, vcpus: int, volume_ids: list<string>, vpc_uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Actions for a Droplet
#
# GET /v2/droplets/{droplet_id}/actions
# operationId: dropletActions_list
export def "droplets-actions list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<actions: table<completed_at: string, id: int, region: record, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate a Droplet Action
#
# POST /v2/droplets/{droplet_id}/actions
# Discriminator (request): type = change_kernel, disable_backups, enable_backups, enable_ipv6, password_reset, power_cycle, power_off, power_on, reboot, rebuild, rename, resize, restore, shutdown, snapshot
# operationId: dropletActions_post
export def "droplets-actions create" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-3 # The type of action to initiate for the Droplet. (e.g. reboot)
]: any -> record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/actions"))
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve a Droplet Action
#
# GET /v2/droplets/{droplet_id}/actions/{action_id}
# operationId: dropletActions_get
export def "droplets-actions get" [
  droplet_id: any
  action_id: any
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
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id), action_id: (encode-path-segment $action_id)} | format pattern "/v2/droplets/{droplet_id}/actions/{action_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Backups for a Droplet
#
# GET /v2/droplets/{droplet_id}/backups
# operationId: droplets_list_backups
export def "droplets-backups list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<backups: table<id: int, created_at: string, min_disk_size: int, name: string, regions: list, size_gigabytes: float, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/backups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Associated Resources for a Droplet
#
# GET /v2/droplets/{droplet_id}/destroy_with_associated_resources
# operationId: droplets_list_associatedResources
export def "droplets-destroy-with-associated-resources list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<floating_ips: list<any>, reserved_ips: table<cost: string, id: string, name: string>, snapshots: list<any>, volume_snapshots: list<any>, volumes: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Destroy a Droplet and All of its Associated Resources (Dangerous)
#
# DELETE /v2/droplets/{droplet_id}/destroy_with_associated_resources/dangerous
# operationId: droplets_destroy_withAssociatedResourcesDangerous
export def "droplets-destroy-with-associated-resources-dangerous delete" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-dangerous: oneof<nothing, bool> # Acknowledge this action will destroy the Droplet and all associated resources and _can not_ be reversed. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/dangerous"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Dangerous": $x_dangerous} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry a Droplet Destroy with Associated Resources Request
#
# POST /v2/droplets/{droplet_id}/destroy_with_associated_resources/retry
# operationId: droplets_destroy_retryWithAssociatedResources
export def "droplets-destroy-with-associated-resources-retry delete" [
  droplet_id: any
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
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/retry"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Selectively Destroy a Droplet and its Associated Resources
#
# DELETE /v2/droplets/{droplet_id}/destroy_with_associated_resources/selective
# operationId: droplets_destroy_withAssociatedResourcesSelective
@deprecated --flag floating-ips
export def "droplets-destroy-with-associated-resources-selective delete" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --floating-ips: list<string> # An array of unique identifiers for the floating IPs to be scheduled for deletion. (DEPRECATED, e.g. [6186916])
  --reserved-ips: list<string> # An array of unique identifiers for the reserved IPs to be scheduled for deletion. (e.g. [6186916])
  --snapshots: list<string> # An array of unique identifiers for the snapshots to be scheduled for deletion. (e.g. [61486916])
  --volume-snapshots: list<string> # An array of unique identifiers for the volume snapshots to be scheduled for deletion. (e.g. [edb0478d-7436-11ea-86e6-0a58ac144b91])
  --volumes: list<string> # An array of unique identifiers for the volumes to be scheduled for deletion. (e.g. [ba49449a-7435-11ea-b89e-0a58ac14480f])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/selective"))
  let req_body = {"floating_ips": $floating_ips, "reserved_ips": $reserved_ips, "snapshots": $snapshots, "volume_snapshots": $volume_snapshots, "volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Check Status of a Droplet Destroy with Associated Resources Request
#
# GET /v2/droplets/{droplet_id}/destroy_with_associated_resources/status
# operationId: droplets_get_DestroyAssociatedResourcesStatus
export def "droplets-destroy-with-associated-resources-status get" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completed_at: string, droplet: record<destroyed_at: string, error_message: string, id: string, name: string>, failures: int, resources: record<floating_ips: list<any>, reserved_ips: list<any>, snapshots: list<any>, volume_snapshots: list<any>, volumes: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Firewalls Applied to a Droplet
#
# GET /v2/droplets/{droplet_id}/firewalls
# operationId: droplets_list_firewalls
export def "droplets-firewalls list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<firewalls: list<record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/firewalls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Available Kernels for a Droplet
#
# GET /v2/droplets/{droplet_id}/kernels
# operationId: droplets_list_kernels
export def "droplets-kernels list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<kernels: table<id: int, name: string, version: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/kernels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Neighbors for a Droplet
#
# GET /v2/droplets/{droplet_id}/neighbors
# operationId: droplets_list_neighbors
export def "droplets-neighbors list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<droplets: table<backup_ids: list, created_at: string, disk: int, features: list, id: int, image: record, kernel: record, locked: bool, memory: int, name: string, networks: record, next_backup_window: record, region: record, size: record, size_slug: string, snapshot_ids: list, status: string, tags: list, vcpus: int, volume_ids: list, vpc_uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/neighbors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Snapshots for a Droplet
#
# GET /v2/droplets/{droplet_id}/snapshots
# operationId: droplets_list_snapshots
export def "droplets-snapshots list" [
  droplet_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<snapshots: list<any>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/snapshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Firewalls
#
# GET /v2/firewalls
# operationId: firewalls_list
export def "firewalls list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<firewalls: list<any>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/firewalls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Firewall
#
# POST /v2/firewalls
# operationId: firewalls_create
export def "firewalls create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<firewall: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/firewalls")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Firewall
#
# DELETE /v2/firewalls/{firewall_id}
# operationId: firewalls_delete
export def "firewalls delete" [
  firewall_id: any
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
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Firewall
#
# GET /v2/firewalls/{firewall_id}
# operationId: firewalls_get
export def "firewalls get" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firewall: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Firewall
#
# PUT /v2/firewalls/{firewall_id}
# operationId: firewalls_update
export def "firewalls update" [
  firewall_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<firewall: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove Droplets from a Firewall
#
# DELETE /v2/firewalls/{firewall_id}/droplets
# operationId: firewalls_delete_droplets
export def "firewalls-droplets delete" [
  firewall_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  droplet_ids: list<int> # An array containing the IDs of the Droplets to be removed from the firewall. (e.g. [49696269])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/droplets"))
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add Droplets to a Firewall
#
# POST /v2/firewalls/{firewall_id}/droplets
# operationId: firewalls_assign_droplets
export def "firewalls-droplets assign" [
  firewall_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  droplet_ids: list<int> # An array containing the IDs of the Droplets to be assigned to the firewall. (e.g. [49696269])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/droplets"))
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove Rules from a Firewall
#
# DELETE /v2/firewalls/{firewall_id}/rules
# operationId: firewalls_delete_rules
export def "firewalls-rules delete" [
  firewall_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/rules"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add Rules to a Firewall
#
# POST /v2/firewalls/{firewall_id}/rules
# operationId: firewalls_add_rules
export def "firewalls-rules create" [
  firewall_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/rules"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove Tags from a Firewall
#
# DELETE /v2/firewalls/{firewall_id}/tags
# operationId: firewalls_delete_tags
export def "firewalls-tags delete" [
  firewall_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/tags"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add Tags to a Firewall
#
# POST /v2/firewalls/{firewall_id}/tags
# operationId: firewalls_add_tags
export def "firewalls-tags create" [
  firewall_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/tags"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Floating IPs
#
# GET /v2/floating_ips
# operationId: floatingIPs_list
export def "floating-ips list-i-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<floating_ips: table<droplet: any, ip: string, locked: bool, project_id: string, region: record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/floating_ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Floating IP
#
# POST /v2/floating_ips
# operationId: floatingIPs_create
export def "floating-ips create-i-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-id: int # The ID of the Droplet that the floating IP will be assigned to. (e.g. 2457247)
  --project-id: string # The UUID of the project to which the floating IP will be assigned. (format: uuid, e.g. 746c6152-2fa2-11ed-92d3-27aaa54e4988)
  --region: string # The slug identifier for the region the floating IP will be reserved to. (e.g. nyc3)
]: any -> record<floating_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>, links: record<actions: list<record>, droplets: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/floating_ips")
  let req_body = {"droplet_id": $droplet_id, "project_id": $project_id, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Floating IP
#
# DELETE /v2/floating_ips/{floating_ip}
# operationId: floatingIPs_delete
export def "floating-ips delete-i-ps" [
  floating_ip: any
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
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Floating IP
#
# GET /v2/floating_ips/{floating_ip}
# operationId: floatingIPs_get
export def "floating-ips get-i-ps" [
  floating_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<floating_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Actions for a Floating IP
#
# GET /v2/floating_ips/{floating_ip}/actions
# operationId: floatingIPsAction_list
export def "floating-ips-actions list-i-ps" [
  floating_ip: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<completed_at: string, id: int, region: record, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}/actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate a Floating IP Action
#
# POST /v2/floating_ips/{floating_ip}/actions
# Discriminator (request): type = assign, unassign
# operationId: floatingIPsAction_post
export def "floating-ips-actions create-i-ps" [
  floating_ip: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string, project_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}/actions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve an Existing Floating IP Action
#
# GET /v2/floating_ips/{floating_ip}/actions/{action_id}
# operationId: floatingIPsAction_get
export def "floating-ips-actions get-i-ps" [
  floating_ip: any
  action_id: any
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
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip), action_id: (encode-path-segment $action_id)} | format pattern "/v2/floating_ips/{floating_ip}/actions/{action_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Namespaces
#
# GET /v2/functions/namespaces
# operationId: functions_list_namespaces
export def "functions-namespaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<namespaces: table<api_host: string, created_at: string, key: string, label: string, namespace: string, region: string, updated_at: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/functions/namespaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Namespace
#
# POST /v2/functions/namespaces
# operationId: functions_create_namespace
export def "functions-namespaces create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The namespace's unique name. (e.g. my namespace)
  region: string # The [datacenter region](https://docs.digitalocean.com/products/platform/availability-matrix/#available-datacenters) in which to create the namespace. (e.g. nyc1)
]: any -> record<namespace: record<api_host: string, created_at: string, key: string, label: string, namespace: string, region: string, updated_at: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/functions/namespaces")
  let req_body = {"label": $label, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Namespace
#
# DELETE /v2/functions/namespaces/{namespace_id}
# operationId: functions_delete_namespace
export def "functions-namespaces delete" [
  namespace_id: any
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
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Namespace
#
# GET /v2/functions/namespaces/{namespace_id}
# operationId: functions_get_namespace
export def "functions-namespaces get" [
  namespace_id: string
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
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Triggers
#
# GET /v2/functions/namespaces/{namespace_id}/triggers
# operationId: functions_list_triggers
export def "functions-namespaces-triggers list" [
  namespace_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<triggers: table<created_at: string, function: string, is_enabled: bool, name: string, namespace: string, scheduled_details: record, scheduled_runs: record, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Trigger
#
# POST /v2/functions/namespaces/{namespace_id}/triggers
# operationId: functions_create_trigger
export def "functions-namespaces-triggers create" [
  namespace_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  function: string # Name of function(action) that exists in the given namespace. (e.g. hello)
  --is-enabled: oneof<nothing, bool> # Indicates weather the trigger is paused or unpaused. (e.g. true)
  name: string # The trigger's unique name within the namespace. (e.g. my trigger)
  scheduled_details: any
  type: string # One of different type of triggers. Currently only SCHEDULED is supported. (e.g. SCHEDULED)
]: any -> record<trigger: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers"))
  let req_body = {"function": $function, "is_enabled": $is_enabled, "name": $name, "scheduled_details": $scheduled_details, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Trigger
#
# DELETE /v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}
# operationId: functions_delete_trigger
export def "functions-namespaces-triggers delete" [
  namespace_id: any
  trigger_name: any
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
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trigger
#
# GET /v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}
# operationId: functions_get_trigger
export def "functions-namespaces-triggers get" [
  namespace_id: any
  trigger_name: string
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
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Trigger
#
# PUT /v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}
# operationId: functions_update_trigger
export def "functions-namespaces-triggers update" [
  namespace_id: any
  trigger_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-enabled: oneof<nothing, bool> # Indicates weather the trigger is paused or unpaused. (e.g. true)
  --scheduled-details: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}"))
  let req_body = {"is_enabled": $is_enabled, "scheduled_details": $scheduled_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Images
#
# GET /v2/images
# operationId: images_list
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-4 # Filters results based on image type which can be either `application` or `distribution`. (e.g. distribution)
  --private: oneof<nothing, bool> # Used to filter only user images. (e.g. true)
  --tag-name: string # Used to filter images by a specific tag. (e.g. base-image)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<images: table<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list, size_gigabytes: float, slug: string, status: string, tags: list, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "tag_name" $tag_name "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Custom Image
#
# POST /v2/images
# operationId: images_create_custom
export def "images create-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional free-form text field to describe an image. (e.g.  )
  --distribution: string@distribution-completer # The name of a custom image's distribution. Currently, the valid values are `Arch Linux`, `CentOS`, `CoreOS`, `Debian`, `Fedora`, `Fedora Atomic`, `FreeBSD`, `Gentoo`, `openSUSE`, `RancherOS`, `Rocky Linux`, `Ubuntu`, and `Unknown`. Any other value will be accepted but ignored, and `Unknown` will be used in its place. (e.g. Ubuntu)
  name: string # The display name that has been given to an image. This is what is shown in the control panel and is generally a descriptive title for the image in question. (e.g. Nifty New Snapshot)
  region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
  url: string # A URL from which the custom Linux virtual machine image may be retrieved. The image it points to must be in the raw, qcow2, vhdx, vdi, or vmdk format. It may be compressed using gzip or bzip2 and must be smaller than 100 GB after being decompressed. (e.g. http://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img)
]: any -> record<image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list<string>, size_gigabytes: float, slug: string, status: string, tags: list<string>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/images")
  let req_body = {"description": $description, "distribution": $distribution, "name": $name, "region": $region, "tags": $tags, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an Image
#
# DELETE /v2/images/{image_id}
# operationId: images_delete
export def "images delete" [
  image_id: any
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
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Image
#
# GET /v2/images/{image_id}
# operationId: images_get
export def "images get" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list<string>, size_gigabytes: float, slug: string, status: string, tags: list<string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Image
#
# PUT /v2/images/{image_id}
# operationId: images_update
export def "images update" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional free-form text field to describe an image. (e.g.  )
  --distribution: string@distribution-completer # The name of a custom image's distribution. Currently, the valid values are `Arch Linux`, `CentOS`, `CoreOS`, `Debian`, `Fedora`, `Fedora Atomic`, `FreeBSD`, `Gentoo`, `openSUSE`, `RancherOS`, `Rocky Linux`, `Ubuntu`, and `Unknown`. Any other value will be accepted but ignored, and `Unknown` will be used in its place. (e.g. Ubuntu)
  --name: string # The display name that has been given to an image. This is what is shown in the control panel and is generally a descriptive title for the image in question. (e.g. Nifty New Snapshot)
]: any -> record<image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list<string>, size_gigabytes: float, slug: string, status: string, tags: list<string>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}"))
  let req_body = {"description": $description, "distribution": $distribution, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Actions for an Image
#
# GET /v2/images/{image_id}/actions
# operationId: imageActions_list
export def "images-actions list" [
  image_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<completed_at: string, id: int, region: record, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}/actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate an Image Action
#
# POST /v2/images/{image_id}/actions
# Discriminator (request): type = convert, transfer
# operationId: imageActions_post
export def "images-actions create" [
  image_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-5 # The action to be taken on the image. Can be either `convert` or `transfer`. (e.g. convert)
]: any -> record<completed_at: string, id: int, region: record<available: bool, features: list<string>, name: string, sizes: list<string>, slug: string>, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}/actions"))
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve an Existing Action
#
# GET /v2/images/{image_id}/actions/{action_id}
# operationId: imageActions_get
export def "images-actions get" [
  image_id: any
  action_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completed_at: string, id: int, region: record<available: bool, features: list<string>, name: string, sizes: list<string>, slug: string>, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id), action_id: (encode-path-segment $action_id)} | format pattern "/v2/images/{image_id}/actions/{action_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Kubernetes Clusters
#
# GET /v2/kubernetes/clusters
# operationId: kubernetes_list_clusters
export def "kubernetes-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<kubernetes_clusters: table<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record, name: string, node_pools: list, region: string, registry_enabled: bool, service_subnet: string, status: record, surge_upgrade: bool, tags: list, updated_at: string, version: string, vpc_uuid: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/kubernetes/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Kubernetes Cluster
#
# POST /v2/kubernetes/clusters
# operationId: kubernetes_create_cluster
# --maintenance_policy shape: {day?: "any"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time?: string}
# --node_pools item shape: {size: string, auto_scale?: bool, count: int, labels?: record, max_nodes?: int, min_nodes?: int, name: string, tags?: list<string>, taints?: list}
# --status shape: {message?: string, state?: "running"|"provisioning"|"degraded"|"error"|"deleted"|"upgrading"|"deleting"}
export def "kubernetes-clusters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-upgrade: oneof<nothing, bool> # A boolean value indicating whether the cluster will be automatically upgraded to new patch releases during its maintenance window. (default: false, e.g. true)
  --ha: oneof<nothing, bool> # A boolean value indicating whether the control plane is run in a highly available configuration in the cluster. Highly available control planes incur less downtime. The property cannot be disabled. (default: false, e.g. true)
  --maintenance-policy: record # An object specifying the maintenance window policy for the Kubernetes cluster. (nullable) — shape: {day?: "any"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time?: string}
  name: string # A human-readable name for a Kubernetes cluster. (e.g. prod-cluster-01)
  node_pools: list # An object specifying the details of the worker nodes available to the Kubernetes cluster. — item shape: {size: string, auto_scale?: bool, count: int, labels?: record, max_nodes?: int, min_nodes?: int, name: string, tags?: list<string>, taints?: list}
  region: string # The slug identifier for the region where the Kubernetes cluster is located. (e.g. nyc1)
  --surge-upgrade: oneof<nothing, bool> # A boolean value indicating whether surge upgrade is enabled/disabled for the cluster. Surge upgrade makes cluster upgrades fast and reliable by bringing up new nodes before destroying the outdated nodes. (default: false, e.g. true)
  --tags: list<string> # An array of tags applied to the Kubernetes cluster. All clusters are automatically tagged `k8s` and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, production, web-team])
  version: string # The slug identifier for the version of Kubernetes used for the cluster. If set to a minor version (e.g. "1.14"), the latest version within it will be used (e.g. "1.14.6-do.1"); if set to "latest", the latest published version will be used. See the `/v2/kubernetes/options` endpoint to find all currently available versions. (e.g. 1.18.6-do.0)
  --vpc-uuid: string # A string specifying the UUID of the VPC to which the Kubernetes cluster is assigned. (format: uuid, e.g. c33931f2-a26a-4e61-b85c-4e95a2ec431b)
]: any -> record<kubernetes_cluster: record<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record<day: string, duration: string, start_time: string>, name: string, node_pools: list<record>, region: string, registry_enabled: bool, service_subnet: string, status: record<message: string, state: string>, surge_upgrade: bool, tags: list<string>, updated_at: string, version: string, vpc_uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/clusters")
  let req_body = {"auto_upgrade": $auto_upgrade, "ha": $ha, "maintenance_policy": $maintenance_policy, "name": $name, "node_pools": $node_pools, "region": $region, "surge_upgrade": $surge_upgrade, "tags": $tags, "version": $version, "vpc_uuid": $vpc_uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Kubernetes Cluster
#
# DELETE /v2/kubernetes/clusters/{cluster_id}
# operationId: kubernetes_delete_cluster
export def "kubernetes-clusters delete" [
  cluster_id: any
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
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}
# operationId: kubernetes_get_cluster
export def "kubernetes-clusters get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kubernetes_cluster: record<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record<day: string, duration: string, start_time: string>, name: string, node_pools: list<record>, region: string, registry_enabled: bool, service_subnet: string, status: record<message: string, state: string>, surge_upgrade: bool, tags: list<string>, updated_at: string, version: string, vpc_uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Kubernetes Cluster
#
# PUT /v2/kubernetes/clusters/{cluster_id}
# operationId: kubernetes_update_cluster
# --maintenance_policy shape: {day?: "any"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time?: string}
export def "kubernetes-clusters update" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-upgrade: oneof<nothing, bool> # A boolean value indicating whether the cluster will be automatically upgraded to new patch releases during its maintenance window. (default: false, e.g. true)
  --ha: oneof<nothing, bool> # A boolean value indicating whether the control plane is run in a highly available configuration in the cluster. Highly available control planes incur less downtime. The property cannot be disabled. (default: false, e.g. true)
  --maintenance-policy: record # An object specifying the maintenance window policy for the Kubernetes cluster. (nullable) — shape: {day?: "any"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time?: string}
  name: string # A human-readable name for a Kubernetes cluster. (e.g. prod-cluster-01)
  --surge-upgrade: oneof<nothing, bool> # A boolean value indicating whether surge upgrade is enabled/disabled for the cluster. Surge upgrade makes cluster upgrades fast and reliable by bringing up new nodes before destroying the outdated nodes. (default: false, e.g. true)
  --tags: list<string> # An array of tags applied to the Kubernetes cluster. All clusters are automatically tagged `k8s` and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, production, web-team])
]: any -> record<kubernetes_cluster: record<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record<day: string, duration: string, start_time: string>, name: string, node_pools: list<record>, region: string, registry_enabled: bool, service_subnet: string, status: record<message: string, state: string>, surge_upgrade: bool, tags: list<string>, updated_at: string, version: string, vpc_uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}"))
  let req_body = {"auto_upgrade": $auto_upgrade, "ha": $ha, "maintenance_policy": $maintenance_policy, "name": $name, "surge_upgrade": $surge_upgrade, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Fetch Clusterlint Diagnostics for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/clusterlint
# operationId: kubernetes_get_clusterLintResults
export def "kubernetes-clusters-clusterlint get-lint-results" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --run-id: string # Specifies the clusterlint run whose results will be retrieved. (format: uuid, e.g. 50c2f44c-011d-493e-aee5-361a4a0d1844)
]: nothing -> record<completed_at: string, diagnostics: table<check_name: string, message: string, object: record, severity: string>, requested_at: string, run_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "run_id" $run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/clusterlint") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run Clusterlint Checks on a Kubernetes Cluster
#
# POST /v2/kubernetes/clusters/{cluster_id}/clusterlint
# operationId: kubernetes_run_clusterLint
export def "kubernetes-clusters-clusterlint create-run-lint" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-checks: list<string> # An array of checks that will be run when clusterlint executes checks. (e.g. [default-namespace])
  --exclude-groups: list<string> # An array of check groups that will be omitted when clusterlint executes checks. (e.g. [workload-health])
  --include-checks: list<string> # An array of checks that will be run when clusterlint executes checks. (e.g. [bare-pods, resource-requirements])
  --include-groups: list<string> # An array of check groups that will be run when clusterlint executes checks. (e.g. [basic, doks, security])
]: any -> record<run_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/clusterlint"))
  let req_body = {"exclude_checks": $exclude_checks, "exclude_groups": $exclude_groups, "include_checks": $include_checks, "include_groups": $include_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve Credentials for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/credentials
# operationId: kubernetes_get_credentials
export def "kubernetes-clusters-credentials get" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate_authority_data: string, client_certificate_data: string, client_key_data: string, expires_at: string, server: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Associated Resources for Cluster Deletion
#
# GET /v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources
# operationId: kubernetes_list_associatedResources
export def "kubernetes-clusters-destroy-with-associated-resources list" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<load_balancers: table<id: string, name: string>, volume_snapshots: list<any>, volumes: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Cluster and All of its Associated Resources (Dangerous)
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/dangerous
# operationId: kubernetes_destroy_associatedResourcesDangerous
export def "kubernetes-clusters-destroy-with-associated-resources-dangerous delete" [
  cluster_id: any
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
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/dangerous"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Selectively Delete a Cluster and its Associated Resources
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/selective
# operationId: kubernetes_destroy_associatedResourcesSelective
export def "kubernetes-clusters-destroy-with-associated-resources-selective delete" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --load-balancers: list<string> # A list of IDs for associated load balancers to destroy along with the cluster. (e.g. [4de7ac8b-495b-4884-9a69-1050c6793cd6])
  --volume-snapshots: list<string> # A list of IDs for associated volume snapshots to destroy along with the cluster. (e.g. [edb0478d-7436-11ea-86e6-0a58ac144b91])
  --volumes: list<string> # A list of IDs for associated volumes to destroy along with the cluster. (e.g. [ba49449a-7435-11ea-b89e-0a58ac14480f])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/selective"))
  let req_body = {"load_balancers": $load_balancers, "volume_snapshots": $volume_snapshots, "volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve the kubeconfig for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/kubeconfig
# operationId: kubernetes_get_kubeconfig
export def "kubernetes-clusters-kubeconfig get" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-seconds: int # The duration in seconds that the returned Kubernetes credentials will be valid. If not set or 0, the credentials will have a 7 day expiry. (default: 0, e.g. 300)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry_seconds" $expiry_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/kubeconfig") $qp)
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Node Pools in a Kubernetes Clusters
#
# GET /v2/kubernetes/clusters/{cluster_id}/node_pools
# operationId: kubernetes_list_nodePools
export def "kubernetes-clusters-node-pools list" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<node_pools: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Node Pool to a Kubernetes Cluster
#
# POST /v2/kubernetes/clusters/{cluster_id}/node_pools
# operationId: kubernetes_add_nodePool
# --nodes item shape: {created_at?: string, droplet_id?: string, id?: string, name?: string, status?: record, updated_at?: string}
# --taints item shape: {effect?: "NoSchedule"|"PreferNoSchedule"|"NoExecute", key?: string, value?: string}
export def "kubernetes-clusters-node-pools create" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  size: string # The slug identifier for the type of Droplet used as workers in the node pool. (e.g. s-1vcpu-2gb)
  --auto-scale: oneof<nothing, bool> # A boolean value indicating whether auto-scaling is enabled for this node pool. (e.g. true)
  count: int # The number of Droplet instances in the node pool. (e.g. 3)
  --labels: record # An object containing a set of Kubernetes labels. The keys and are values are both user-defined. (nullable)
  --max-nodes: int # The maximum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 6)
  --min-nodes: int # The minimum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 3)
  name: string # A human-readable name for the node pool. (e.g. frontend-pool)
  --tags: list<string> # An array containing the tags applied to the node pool. All node pools are automatically tagged `k8s`, `k8s-worker`, and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, k8s-worker, production, web-team])
  --taints: list # An array of taints to apply to all nodes in a pool. Taints will automatically be applied to all existing nodes and any subsequent nodes added to the pool. When a taint is removed, it is removed from all nodes in the pool. — item shape: {effect?: "NoSchedule"|"PreferNoSchedule"|"NoExecute", key?: string, value?: string}
]: any -> record<node_pool: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools"))
  let req_body = {"size": $size, "auto_scale": $auto_scale, "count": $count, "labels": $labels, "max_nodes": $max_nodes, "min_nodes": $min_nodes, "name": $name, "tags": $tags, "taints": $taints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Node Pool in a Kubernetes Cluster
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}
# operationId: kubernetes_delete_nodePool
export def "kubernetes-clusters-node-pools delete" [
  cluster_id: any
  node_pool_id: any
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
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Node Pool for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}
# operationId: kubernetes_get_nodePool
export def "kubernetes-clusters-node-pools get" [
  cluster_id: any
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<node_pool: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Node Pool in a Kubernetes Cluster
#
# PUT /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}
# operationId: kubernetes_update_nodePool
# --nodes item shape: {created_at?: string, droplet_id?: string, id?: string, name?: string, status?: record, updated_at?: string}
# --taints item shape: {effect?: "NoSchedule"|"PreferNoSchedule"|"NoExecute", key?: string, value?: string}
export def "kubernetes-clusters-node-pools update" [
  cluster_id: any
  node_pool_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scale: oneof<nothing, bool> # A boolean value indicating whether auto-scaling is enabled for this node pool. (e.g. true)
  count: int # The number of Droplet instances in the node pool. (e.g. 3)
  --labels: record # An object containing a set of Kubernetes labels. The keys and are values are both user-defined. (nullable)
  --max-nodes: int # The maximum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 6)
  --min-nodes: int # The minimum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 3)
  name: string # A human-readable name for the node pool. (e.g. frontend-pool)
  --tags: list<string> # An array containing the tags applied to the node pool. All node pools are automatically tagged `k8s`, `k8s-worker`, and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, k8s-worker, production, web-team])
  --taints: list # An array of taints to apply to all nodes in a pool. Taints will automatically be applied to all existing nodes and any subsequent nodes added to the pool. When a taint is removed, it is removed from all nodes in the pool. — item shape: {effect?: "NoSchedule"|"PreferNoSchedule"|"NoExecute", key?: string, value?: string}
]: any -> record<node_pool: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}"))
  let req_body = {"auto_scale": $auto_scale, "count": $count, "labels": $labels, "max_nodes": $max_nodes, "min_nodes": $min_nodes, "name": $name, "tags": $tags, "taints": $taints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Node in a Kubernetes Cluster
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/nodes/{node_id}
# operationId: kubernetes_delete_node
export def "kubernetes-clusters-node-pools-nodes delete" [
  cluster_id: any
  node_pool_id: any
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-drain: int # Specifies whether or not to drain workloads from a node before it is deleted. Setting it to `1` causes node draining to be skipped. Omitting the query parameter or setting its value to `0` carries out draining prior to deletion. (default: 0, e.g. 1)
  --replace: int # Specifies whether or not to replace a node after it has been deleted. Setting it to `1` causes the node to be replaced by a new one after deletion. Omitting the query parameter or setting its value to `0` deletes without replacement. (default: 0, e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip_drain" $skip_drain "scalar") (serialize-qp "replace" $replace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/nodes/{node_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recycle a Kubernetes Node Pool
#
# POST /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/recycle
# DEPRECATED
# operationId: kubernetes_recycle_node_pool
@deprecated
export def "kubernetes-clusters-node-pools-recycle create" [
  cluster_id: any
  node_pool_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodes: list<string> # e.g. [d8db5e1a-6103-43b5-a7b3-8a948210a9fc]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/recycle"))
  let req_body = {"nodes": $nodes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Upgrade a Kubernetes Cluster
#
# POST /v2/kubernetes/clusters/{cluster_id}/upgrade
# operationId: kubernetes_upgrade_cluster
export def "kubernetes-clusters-upgrade create" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The slug identifier for the version of Kubernetes that the cluster will be upgraded to. (e.g. 1.16.13-do.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/upgrade"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve Available Upgrades for an Existing Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/upgrades
# operationId: kubernetes_get_availableUpgrades
export def "kubernetes-clusters-upgrades get-available" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available_upgrade_versions: table<kubernetes_version: string, slug: string, supported_features: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/upgrades"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve User Information for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/user
# operationId: kubernetes_get_clusterUser
export def "kubernetes-clusters-user get" [
  cluster_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kubernetes_cluster_user: record<groups: list<string>, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/user"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Available Regions, Node Sizes, and Versions of Kubernetes
#
# GET /v2/kubernetes/options
# operationId: kubernetes_list_options
export def "kubernetes-options list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<options: record<regions: list<record>, sizes: list<record>, versions: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Container Registry from Kubernetes Clusters
#
# DELETE /v2/kubernetes/registry
# operationId: kubernetes_remove_registry
export def "kubernetes-registry delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-uuids: list<string> # An array containing the UUIDs of Kubernetes clusters. (e.g. [bd5f5959-5e1e-4205-a714-a914373942af, 50c2f44c-011d-493e-aee5-361a4a0d1844])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/registry")
  let req_body = {"cluster_uuids": $cluster_uuids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add Container Registry to Kubernetes Clusters
#
# POST /v2/kubernetes/registry
# operationId: kubernetes_add_registry
export def "kubernetes-registry create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-uuids: list<string> # An array containing the UUIDs of Kubernetes clusters. (e.g. [bd5f5959-5e1e-4205-a714-a914373942af, 50c2f44c-011d-493e-aee5-361a4a0d1844])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/registry")
  let req_body = {"cluster_uuids": $cluster_uuids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Load Balancers
#
# GET /v2/load_balancers
# operationId: loadBalancers_list
export def "load-balancers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<load_balancers: table<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record, forwarding_rules: list, health_check: record, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record, vpc_uuid: string, region: record, droplet_ids: list, tag: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/load_balancers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Load Balancer
#
# POST /v2/load_balancers
# operationId: loadBalancers_create
export def "load-balancers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<load_balancer: record<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record<allow: list, deny: list>, forwarding_rules: list<record>, health_check: record<check_interval_seconds: int, healthy_threshold: int, path: string, port: int, protocol: string, response_timeout_seconds: int, unhealthy_threshold: int>, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record<cookie_name: string, cookie_ttl_seconds: int, type: string>, vpc_uuid: string, region: record, droplet_ids: list<int>, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/load_balancers")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Load Balancer
#
# DELETE /v2/load_balancers/{lb_id}
# operationId: loadBalancers_delete
export def "load-balancers delete" [
  lb_id: any
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
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Load Balancer
#
# GET /v2/load_balancers/{lb_id}
# operationId: loadBalancers_get
export def "load-balancers get" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<load_balancer: record<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record<allow: list, deny: list>, forwarding_rules: list<record>, health_check: record<check_interval_seconds: int, healthy_threshold: int, path: string, port: int, protocol: string, response_timeout_seconds: int, unhealthy_threshold: int>, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record<cookie_name: string, cookie_ttl_seconds: int, type: string>, vpc_uuid: string, region: record, droplet_ids: list<int>, tag: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Load Balancer
#
# PUT /v2/load_balancers/{lb_id}
# operationId: loadBalancers_update
export def "load-balancers update" [
  lb_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<load_balancer: record<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record<allow: list, deny: list>, forwarding_rules: list<record>, health_check: record<check_interval_seconds: int, healthy_threshold: int, path: string, port: int, protocol: string, response_timeout_seconds: int, unhealthy_threshold: int>, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record<cookie_name: string, cookie_ttl_seconds: int, type: string>, vpc_uuid: string, region: record, droplet_ids: list<int>, tag: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove Droplets from a Load Balancer
#
# DELETE /v2/load_balancers/{lb_id}/droplets
# operationId: loadBalancers_remove_droplets
export def "load-balancers-droplets delete" [
  lb_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the load balancer. (e.g. [3164444, 3164445])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/droplets"))
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add Droplets to a Load Balancer
#
# POST /v2/load_balancers/{lb_id}/droplets
# operationId: loadBalancers_add_droplets
export def "load-balancers-droplets create" [
  lb_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the load balancer. (e.g. [3164444, 3164445])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/droplets"))
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove Forwarding Rules from a Load Balancer
#
# DELETE /v2/load_balancers/{lb_id}/forwarding_rules
# operationId: loadBalancers_remove_forwardingRules
# --forwarding_rules item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
export def "load-balancers-forwarding-rules delete" [
  lb_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  forwarding_rules: list # item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/forwarding_rules"))
  let req_body = {"forwarding_rules": $forwarding_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add Forwarding Rules to a Load Balancer
#
# POST /v2/load_balancers/{lb_id}/forwarding_rules
# operationId: loadBalancers_add_forwardingRules
# --forwarding_rules item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
export def "load-balancers-forwarding-rules create" [
  lb_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  forwarding_rules: list # item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/forwarding_rules"))
  let req_body = {"forwarding_rules": $forwarding_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Alert Policies
#
# GET /v2/monitoring/alerts
# operationId: monitoring_list_alertPolicy
export def "monitoring-alerts list-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<policies: table<alerts: record, compare: string, description: string, enabled: bool, entities: list, tags: list, type: string, uuid: string, value: float, window: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Alert Policy
#
# POST /v2/monitoring/alerts
# operationId: monitoring_create_alertPolicy
# --alerts shape: {email: list<string>, slack: list}
export def "monitoring-alerts create-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alerts: record # shape: {email: list<string>, slack: list}
  compare: string@compare-completer # e.g. GreaterThan
  description: string # e.g. CPU Alert
  --enabled: oneof<nothing, bool> # e.g. true
  entities: list<string> # e.g. [192018292]
  tags: list<string> # e.g. [droplet_tag]
  type: string@type-completer-6 # e.g. v1/insights/droplet/cpu
  value: float # format: float, e.g. 80
  window: string@window-completer # e.g. 5m
]: any -> record<policy: record<alerts: record<email: list, slack: list>, compare: string, description: string, enabled: bool, entities: list<string>, tags: list<string>, type: string, uuid: string, value: float, window: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/monitoring/alerts")
  let req_body = {"alerts": $alerts, "compare": $compare, "description": $description, "enabled": $enabled, "entities": $entities, "tags": $tags, "type": $type, "value": $value, "window": $window} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an Alert Policy
#
# DELETE /v2/monitoring/alerts/{alert_uuid}
# operationId: monitoring_delete_alertPolicy
export def "monitoring-alerts delete-policy" [
  alert_uuid: any
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
  let full_url = (build-url $base ({alert_uuid: (encode-path-segment $alert_uuid)} | format pattern "/v2/monitoring/alerts/{alert_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Alert Policy
#
# GET /v2/monitoring/alerts/{alert_uuid}
# operationId: monitoring_get_alertPolicy
export def "monitoring-alerts get-policy" [
  alert_uuid: string
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
  let full_url = (build-url $base ({alert_uuid: (encode-path-segment $alert_uuid)} | format pattern "/v2/monitoring/alerts/{alert_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Alert Policy
#
# PUT /v2/monitoring/alerts/{alert_uuid}
# operationId: monitoring_update_alertPolicy
# --alerts shape: {email: list<string>, slack: list}
export def "monitoring-alerts update-policy" [
  alert_uuid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alerts: record # shape: {email: list<string>, slack: list}
  compare: string@compare-completer # e.g. GreaterThan
  description: string # e.g. CPU Alert
  --enabled: oneof<nothing, bool> # e.g. true
  entities: list<string> # e.g. [192018292]
  tags: list<string> # e.g. [droplet_tag]
  type: string@type-completer-6 # e.g. v1/insights/droplet/cpu
  value: float # format: float, e.g. 80
  window: string@window-completer # e.g. 5m
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({alert_uuid: (encode-path-segment $alert_uuid)} | format pattern "/v2/monitoring/alerts/{alert_uuid}"))
  let req_body = {"alerts": $alerts, "compare": $compare, "description": $description, "enabled": $enabled, "entities": $entities, "tags": $tags, "type": $type, "value": $value, "window": $window} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Droplet Bandwidth Metrics
#
# GET /v2/monitoring/metrics/droplet/bandwidth
# operationId: monitoring_get_dropletBandwidthMetrics
export def "monitoring-metrics-droplet-bandwidth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --interface: string@interface-completer # The network interface. (e.g. private)
  --direction: string@direction-completer # The traffic direction. (e.g. inbound)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> record<data: record<result: list<record>, resultType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "interface" $interface "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/bandwidth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet CPU Metrics
#
# GET /v2/monitoring/metrics/droplet/cpu
# operationId: monitoring_get_DropletCpuMetrics
export def "monitoring-metrics-droplet-cpu get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> record<data: record<result: list<record>, resultType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/cpu" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Filesystem Free Metrics
#
# GET /v2/monitoring/metrics/droplet/filesystem_free
# operationId: monitoring_get_dropletFilesystemFreeMetrics
export def "monitoring-metrics-droplet-filesystem-free get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> record<data: record<result: list<record>, resultType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/filesystem_free" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Filesystem Size Metrics
#
# GET /v2/monitoring/metrics/droplet/filesystem_size
# operationId: monitoring_get_dropletFilesystemSizeMetrics
export def "monitoring-metrics-droplet-filesystem-size get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/filesystem_size" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Load1 Metrics
#
# GET /v2/monitoring/metrics/droplet/load_1
# operationId: monitoring_get_dropletLoad1Metrics
export def "monitoring-metrics-droplet-load-1 get-load1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> record<data: record<result: list<record>, resultType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/load_1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Load15 Metrics
#
# GET /v2/monitoring/metrics/droplet/load_15
# operationId: monitoring_get_dropletLoad15Metrics
export def "monitoring-metrics-droplet-load-15 get-load15" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/load_15" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Load5 Metrics
#
# GET /v2/monitoring/metrics/droplet/load_5
# operationId: monitoring_get_dropletLoad5Metrics
export def "monitoring-metrics-droplet-load-5 get-load5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/load_5" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Available Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_available
# operationId: monitoring_get_dropletMemoryAvailableMetrics
export def "monitoring-metrics-droplet-memory-available get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_available" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Cached Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_cached
# operationId: monitoring_get_dropletMemoryCachedMetrics
export def "monitoring-metrics-droplet-memory-cached get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_cached" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Free Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_free
# operationId: monitoring_get_dropletMemoryFreeMetrics
export def "monitoring-metrics-droplet-memory-free get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_free" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Droplet Total Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_total
# operationId: monitoring_get_dropletMemoryTotalMetrics
export def "monitoring-metrics-droplet-memory-total get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (e.g. 17209102)
  --start: string # Timestamp to start metric window. (e.g. 1620683817)
  --end: string # Timestamp to end metric window. (e.g. 1620705417)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_total" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Projects
#
# GET /v2/projects
# operationId: projects_list
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<projects: table<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project
#
# POST /v2/projects
# operationId: projects_create
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  --environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
]: any -> record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects")
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve the Default Project
#
# GET /v2/projects/default
# operationId: projects_get_default
export def "projects-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch the Default Project
#
# PATCH /v2/projects/default
# operationId: projects_patch_default
export def "projects-default update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  --environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  --name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  --purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
  --is-default: oneof<nothing, bool> # If true, all resources will be added to this project if no project is specified. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default")
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose, "is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the Default Project
#
# PUT /v2/projects/default
# operationId: projects_update_default
export def "projects-default update-1" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Default Project Resources
#
# GET /v2/projects/default/resources
# operationId: projects_list_resources_default
export def "projects-default-resources list" [
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
  let full_url = (build-url $base "/v2/projects/default/resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign Resources to Default Project
#
# POST /v2/projects/default/resources
# operationId: projects_assign_resources_default
export def "projects-default-resources assign" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default/resources")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an Existing Project
#
# DELETE /v2/projects/{project_id}
# operationId: projects_delete
export def "projects delete" [
  project_id: any
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
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Project
#
# GET /v2/projects/{project_id}
# operationId: projects_get
export def "projects get" [
  project_id: string
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
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a Project
#
# PATCH /v2/projects/{project_id}
# operationId: projects_patch
export def "projects update-by-project_id" [
  project_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  --environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  --name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  --purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
  --is-default: oneof<nothing, bool> # If true, all resources will be added to this project if no project is specified. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}"))
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose, "is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update a Project
#
# PUT /v2/projects/{project_id}
# operationId: projects_update
export def "projects update-by-project_id-1" [
  project_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Project Resources
#
# GET /v2/projects/{project_id}/resources
# operationId: projects_list_resources
export def "projects-resources list" [
  project_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<resources: table<assigned_at: string, links: record, status: string, urn: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/resources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign Resources to a Project
#
# POST /v2/projects/{project_id}/resources
# operationId: projects_assign_resources
export def "projects-resources assign" [
  project_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources: list # A list of uniform resource names (URNs) to be added to a project. (e.g. [do:droplet:13457723])
]: any -> record<resources: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/resources"))
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Data Center Regions
#
# GET /v2/regions
# operationId: regions_list
export def "regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<regions: table<available: bool, features: list, name: string, sizes: list, slug: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Container Registry
#
# DELETE /v2/registry
# operationId: registry_delete
export def "registry delete" [
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
  let full_url = (build-url $base "/v2/registry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Container Registry Information
#
# GET /v2/registry
# operationId: registry_get
export def "registry get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<registry: record<created_at: string, name: string, region: string, storage_usage_bytes: int, storage_usage_bytes_updated_at: string, subscription: record<created_at: string, tier: record, updated_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Container Registry
#
# POST /v2/registry
# operationId: registry_create
export def "registry create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A globally unique name for the container registry. Must be lowercase and be composed only of numbers, letters and `-`, up to a limit of 63 characters. (e.g. example)
  --region: string@region-completer-1 # Slug of the region where registry data is stored. When not provided, a region will be selected. (e.g. fra1)
  subscription_tier_slug: string@subscription-tier-slug-completer # The slug of the subscription tier to sign up for. Valid values can be retrieved using the options endpoint. (e.g. basic)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry")
  let req_body = {"name": $name, "region": $region, "subscription_tier_slug": $subscription_tier_slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Docker Credentials for Container Registry
#
# GET /v2/registry/docker-credentials
# operationId: registry_get_dockerCredentials
export def "registry-docker-credentials get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-seconds: int # The duration in seconds that the returned registry credentials will be valid. If not set or 0, the credentials will not expire. (default: 0, e.g. 3600)
  --read-write: oneof<nothing, bool> # By default, the registry credentials allow for read-only access. Set this query parameter to `true` to obtain read-write credentials. (default: false, e.g. true)
]: nothing -> record<auths: record<registry_digitalocean_com: record<auth: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry_seconds" $expiry_seconds "scalar") (serialize-qp "read_write" $read_write "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/registry/docker-credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Registry Options (Subscription Tiers and Available Regions)
#
# GET /v2/registry/options
# operationId: registry_get_options
export def "registry-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<options: record<available_regions: list<string>, subscription_tiers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subscription Information
#
# GET /v2/registry/subscription
# operationId: registry_get_subscription
export def "registry-subscription get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<subscription: record<created_at: string, tier: record<allow_storage_overage: bool, included_bandwidth_bytes: int, included_repositories: int, included_storage_bytes: int, monthly_price_in_cents: int, name: string, slug: string, storage_overage_price_in_cents: int>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Subscription Tier
#
# POST /v2/registry/subscription
# operationId: registry_update_subscription
export def "registry-subscription update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tier-slug: string@tier-slug-completer # The slug of the subscription tier to sign up for. (e.g. basic)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/subscription")
  let req_body = {"tier_slug": $tier_slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Validate a Container Registry Name
#
# POST /v2/registry/validate-name
# operationId: registry_validate_name
export def "registry-validate-name validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A globally unique name for the container registry. Must be lowercase and be composed only of numbers, letters and `-`, up to a limit of 63 characters. (e.g. example)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/validate-name")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Active Garbage Collection
#
# GET /v2/registry/{registry_name}/garbage-collection
# operationId: registry_get_garbageCollection
export def "registry-garbage-collection get" [
  registry_name: any
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
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/garbage-collection"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Garbage Collection
#
# POST /v2/registry/{registry_name}/garbage-collection
# operationId: registry_run_garbageCollection
export def "registry-garbage-collection create-run" [
  registry_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<garbage_collection: record<blobs_deleted: int, created_at: string, freed_bytes: int, registry_name: string, status: string, updated_at: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/garbage-collection"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Garbage Collection
#
# PUT /v2/registry/{registry_name}/garbage-collection/{garbage_collection_uuid}
# operationId: registry_update_garbageCollection
export def "registry-garbage-collection update" [
  registry_name: any
  garbage_collection_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancel: oneof<nothing, bool> # A boolean value indicating that the garbage collection should be cancelled. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), garbage_collection_uuid: (encode-path-segment $garbage_collection_uuid)} | format pattern "/v2/registry/{registry_name}/garbage-collection/{garbage_collection_uuid}"))
  let req_body = {"cancel": $cancel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Garbage Collections
#
# GET /v2/registry/{registry_name}/garbage-collections
# operationId: registry_list_garbageCollections
export def "registry-garbage-collections list" [
  registry_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<garbage_collections: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/garbage-collections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Container Registry Repositories
#
# GET /v2/registry/{registry_name}/repositories
# DEPRECATED
# operationId: registry_list_repositories
@deprecated
export def "registry-repositories list" [
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<repositories: table<latest_tag: record, name: string, registry_name: string, tag_count: int>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/repositories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Container Registry Repositories (V2)
#
# GET /v2/registry/{registry_name}/repositoriesV2
# operationId: registry_list_repositoriesV2
export def "registry-repositories-v2 list" [
  registry_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. Ignored when 'page_token' is provided. (default: 1, e.g. 1)
  --page-token: string # Token to retrieve of the next or previous set of results more quickly than using 'page'. (e.g. eyJUb2tlbiI6IkNnZGpiMjlz)
]: nothing -> record<repositories: table<latest_manifest: record, manifest_count: int, name: string, registry_name: string, tag_count: int>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/repositoriesV2") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Container Registry Repository Manifests
#
# GET /v2/registry/{registry_name}/{repository_name}/digests
# operationId: registry_list_repositoryManifests
export def "registry-digests list-manifests" [
  registry_name: any
  repository_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<manifests: list<any>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/v2/registry/{registry_name}/{repository_name}/digests") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Container Registry Repository Manifest
#
# DELETE /v2/registry/{registry_name}/{repository_name}/digests/{manifest_digest}
# operationId: registry_delete_repositoryManifest
export def "registry-digests delete" [
  registry_name: any
  repository_name: any
  manifest_digest: string
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
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name), manifest_digest: (encode-path-segment $manifest_digest)} | format pattern "/v2/registry/{registry_name}/{repository_name}/digests/{manifest_digest}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Container Registry Repository Tags
#
# GET /v2/registry/{registry_name}/{repository_name}/tags
# operationId: registry_list_repositoryTags
export def "registry-tags list" [
  registry_name: any
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<tags: list<any>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/v2/registry/{registry_name}/{repository_name}/tags") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Container Registry Repository Tag
#
# DELETE /v2/registry/{registry_name}/{repository_name}/tags/{repository_tag}
# operationId: registry_delete_repositoryTag
export def "registry-tags delete" [
  registry_name: any
  repository_name: any
  repository_tag: string
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
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name), repository_tag: (encode-path-segment $repository_tag)} | format pattern "/v2/registry/{registry_name}/{repository_name}/tags/{repository_tag}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Droplet Neighbors
#
# GET /v2/reports/droplet_neighbors_ids
# operationId: droplets_list_neighborsIds
export def "reports-droplet-neighbors-ids list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<neighbor_ids: list<list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/reports/droplet_neighbors_ids")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Reserved IPs
#
# GET /v2/reserved_ips
# operationId: reservedIPs_list
export def "reserved-ips list-i-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<reserved_ips: table<droplet: any, ip: string, locked: bool, project_id: string, region: record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/reserved_ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Reserved IP
#
# POST /v2/reserved_ips
# operationId: reservedIPs_create
export def "reserved-ips create-i-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-id: int # The ID of the Droplet that the reserved IP will be assigned to. (e.g. 2457247)
  --project-id: string # The UUID of the project to which the reserved IP will be assigned. (format: uuid, e.g. 746c6152-2fa2-11ed-92d3-27aaa54e4988)
  --region: string # The slug identifier for the region the reserved IP will be reserved to. (e.g. nyc3)
]: any -> record<links: record<actions: list<record>, droplets: list<record>>, reserved_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/reserved_ips")
  let req_body = {"droplet_id": $droplet_id, "project_id": $project_id, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Reserved IP
#
# DELETE /v2/reserved_ips/{reserved_ip}
# operationId: reservedIPs_delete
export def "reserved-ips delete-i-ps" [
  reserved_ip: any
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
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Reserved IP
#
# GET /v2/reserved_ips/{reserved_ip}
# operationId: reservedIPs_get
export def "reserved-ips get-i-ps" [
  reserved_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<reserved_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Actions for a Reserved IP
#
# GET /v2/reserved_ips/{reserved_ip}/actions
# operationId: reservedIPsActions_list
export def "reserved-ips-actions list-i-ps" [
  reserved_ip: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<completed_at: string, id: int, region: record, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}/actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate a Reserved IP Action
#
# POST /v2/reserved_ips/{reserved_ip}/actions
# Discriminator (request): type = assign, unassign
# operationId: reservedIPsActions_post
export def "reserved-ips-actions create-i-ps" [
  reserved_ip: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: record, resource_id: int, resource_type: string, started_at: string, status: string, type: string, project_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}/actions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve an Existing Reserved IP Action
#
# GET /v2/reserved_ips/{reserved_ip}/actions/{action_id}
# operationId: reservedIPsActions_get
export def "reserved-ips-actions get-i-ps" [
  reserved_ip: any
  action_id: any
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
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip), action_id: (encode-path-segment $action_id)} | format pattern "/v2/reserved_ips/{reserved_ip}/actions/{action_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Droplet Sizes
#
# GET /v2/sizes
# operationId: sizes_list
export def "sizes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<sizes: table<available: bool, description: string, disk: int, memory: int, price_hourly: float, price_monthly: float, regions: list, slug: string, transfer: float, vcpus: int>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sizes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Snapshots
#
# GET /v2/snapshots
# operationId: snapshots_list
export def "snapshots list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --resource-type: string@resource-type-completer # Used to filter snapshots by a resource type. (e.g. droplet)
]: nothing -> record<snapshots: table<id: string, resource_id: string, resource_type: string, tags: list>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Snapshot
#
# DELETE /v2/snapshots/{snapshot_id}
# operationId: snapshots_delete
export def "snapshots delete" [
  snapshot_id: any
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
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/snapshots/{snapshot_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Snapshot
#
# GET /v2/snapshots/{snapshot_id}
# operationId: snapshots_get
export def "snapshots get" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<snapshot: record<id: string, resource_id: string, resource_type: string, tags: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/snapshots/{snapshot_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Tags
#
# GET /v2/tags
# operationId: tags_list
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<tags: table<name: string, resources: record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Tag
#
# POST /v2/tags
# operationId: tags_create
# --resources shape: {count?: int, last_tagged_uri?: string, databases?: record, droplets?: record, imgages?: record, volume_snapshots?: record, volumes?: record}
export def "tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the tag. Tags may contain letters, numbers, colons, dashes, and underscores. There is a limit of 255 characters per tag. **Note:** Tag names are case stable, which means the capitalization you use when you first create a tag is canonical. When working with tags in the API, you must use the tag's canonical capitalization. For example, if you create a tag named "PROD", the URL to add that tag to a resource would be `https://api.digitalocean.com/v2/tags/PROD/resources` (not `/v2/tags/prod/resources`). Tagged resources in the control panel will always display the canonical capitalization. For example, if you create a tag named "PROD", you can tag resources in the control panel by entering "prod". The tag will still display with its canonical capitalization, "PROD". (e.g. extra-awesome)
]: any -> record<tag: record<name: string, resources: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tags")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Tag
#
# DELETE /v2/tags/{tag_id}
# operationId: tags_delete
export def "tags delete" [
  tag_id: any
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
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Tag
#
# GET /v2/tags/{tag_id}
# operationId: tags_get
export def "tags get" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tag: record<name: string, resources: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Untag a Resource
#
# DELETE /v2/tags/{tag_id}/resources
# operationId: tags_unassign_resources
export def "tags-resources delete-unassign" [
  tag_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}/resources"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Tag a Resource
#
# POST /v2/tags/{tag_id}/resources
# operationId: tags_assign_resources
# --resources item shape: {resource_id?: string, resource_type?: "droplet"|"image"|"volume"|"volume_snapshot"}
export def "tags-resources assign" [
  tag_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  resources: list # An array of objects containing resource_id and resource_type attributes. (e.g. [{resource_id: 9569411, resource_type: droplet}, {resource_id: 7555620, resource_type: image}, {resource_id: 3d80cb72-342b-4aaa-b92e-4e4abb24a933, resource_type: volume}]) — item shape: {resource_id?: string, resource_type?: "droplet"|"image"|"volume"|"volume_snapshot"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}/resources"))
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Checks
#
# GET /v2/uptime/checks
# operationId: uptime_checks_list
export def "uptime-checks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<checks: list<record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/uptime/checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Check
#
# POST /v2/uptime/checks
# operationId: uptime_check_create
export def "uptime-checks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # A boolean value indicating whether the check is enabled/disabled. (default: true, e.g. true)
  name: string # A human-friendly display name. (e.g. Landing page check)
  regions: list<string> # An array containing the selected regions to perform healthchecks from. (e.g. [us_east, eu_west])
  target: string # The endpoint to perform healthchecks on. (format: url, e.g. https://www.landingpage.com)
  type: string@type-completer-7 # The type of health check to perform. (e.g. https)
]: any -> record<check: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/uptime/checks")
  let req_body = {"enabled": $enabled, "name": $name, "regions": $regions, "target": $target, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Check
#
# DELETE /v2/uptime/checks/{check_id}
# operationId: uptime_check_delete
export def "uptime-checks delete" [
  check_id: any
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
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Check
#
# GET /v2/uptime/checks/{check_id}
# operationId: uptime_check_get
export def "uptime-checks get" [
  check_id: string
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
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Check
#
# PUT /v2/uptime/checks/{check_id}
# operationId: uptime_check_update
export def "uptime-checks update" [
  check_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # A boolean value indicating whether the check is enabled/disabled. (default: true, e.g. true)
  --name: string # A human-friendly display name. (e.g. Landing page check)
  --regions: list<string> # An array containing the selected regions to perform healthchecks from. (e.g. [us_east, eu_west])
  --target: string # The endpoint to perform healthchecks on. (format: url, e.g. https://www.landingpage.com)
  --type: string@type-completer-7 # The type of health check to perform. (e.g. https)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}"))
  let req_body = {"enabled": $enabled, "name": $name, "regions": $regions, "target": $target, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All Alerts
#
# GET /v2/uptime/checks/{check_id}/alerts
# operationId: uptime_check_alerts_list
export def "uptime-checks-alerts list" [
  check_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<alerts: list<record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Alert
#
# POST /v2/uptime/checks/{check_id}/alerts
# operationId: uptime_alert_create
export def "uptime-checks-alerts create" [
  check_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<alert: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an Alert
#
# DELETE /v2/uptime/checks/{check_id}/alerts/{alert_id}
# operationId: uptime_alert_delete
export def "uptime-checks-alerts delete" [
  check_id: any
  alert_id: any
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
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts/{alert_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Alert
#
# GET /v2/uptime/checks/{check_id}/alerts/{alert_id}
# operationId: uptime_alert_get
export def "uptime-checks-alerts get" [
  check_id: any
  alert_id: string
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
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts/{alert_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Alert
#
# PUT /v2/uptime/checks/{check_id}/alerts/{alert_id}
# operationId: uptime_alert_update
export def "uptime-checks-alerts update" [
  check_id: any
  alert_id: any
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts/{alert_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve Check State
#
# GET /v2/uptime/checks/{check_id}/state
# operationId: uptime_check_state_get
export def "uptime-checks-state get" [
  check_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<state: record<previous_outage: record<duration_seconds: int, ended_at: string, region: string, started_at: string>, regions: record<eu_west: any, us_east: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Block Storage Volume by Name
#
# DELETE /v2/volumes
# operationId: volumes_delete_byName
export def "volumes delete-by-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The block storage volume's name. (e.g. example)
  --region: string@region-completer # The slug identifier for the region where the resource is available. (e.g. nyc3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Block Storage Volumes
#
# GET /v2/volumes
# operationId: volumes_list
export def "volumes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The block storage volume's name. (e.g. example)
  --region: string@region-completer # The slug identifier for the region where the resource is available. (e.g. nyc3)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<volumes: list<record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New Block Storage Volume
#
# POST /v2/volumes
# operationId: volumes_create
export def "volumes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<volume: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/volumes")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Initiate A Block Storage Action By Volume Name
#
# POST /v2/volumes/actions
# Discriminator (request): type = attach, detach
# operationId: volumeActions_post
export def "volumes-actions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --body: record
]: any -> record<action: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/volumes/actions" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a Volume Snapshot
#
# DELETE /v2/volumes/snapshots/{snapshot_id}
# operationId: volumeSnapshots_delete_byId
export def "volumes-snapshots delete" [
  snapshot_id: any
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
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/volumes/snapshots/{snapshot_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Volume Snapshot
#
# GET /v2/volumes/snapshots/{snapshot_id}
# operationId: volumeSnapshots_get_byId
export def "volumes-snapshots get" [
  snapshot_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<snapshot: record<id: string, resource_id: string, resource_type: string, tags: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/volumes/snapshots/{snapshot_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Block Storage Volume
#
# DELETE /v2/volumes/{volume_id}
# operationId: volumes_delete
export def "volumes delete" [
  volume_id: any
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
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing Block Storage Volume
#
# GET /v2/volumes/{volume_id}
# operationId: volumes_get
export def "volumes get" [
  volume_id: string
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
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Actions for a Volume
#
# GET /v2/volumes/{volume_id}/actions
# operationId: volumeActions_list
export def "volumes-actions list" [
  volume_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<actions: list<record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate A Block Storage Action By Volume Id
#
# POST /v2/volumes/{volume_id}/actions
# Discriminator (request): type = attach, detach, resize
# operationId: volumeActions_post_byId
export def "volumes-actions create-by-volume_id" [
  volume_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/actions") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve an Existing Volume Action
#
# GET /v2/volumes/{volume_id}/actions/{action_id}
# operationId: volumeActions_get
export def "volumes-actions get" [
  volume_id: any
  action_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id), action_id: (encode-path-segment $action_id)} | format pattern "/v2/volumes/{volume_id}/actions/{action_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Snapshots for a Volume
#
# GET /v2/volumes/{volume_id}/snapshots
# operationId: volumeSnapshots_list
export def "volumes-snapshots list" [
  volume_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<snapshots: table<id: string, resource_id: string, resource_type: string, tags: list>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/snapshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Snapshot from a Volume
#
# POST /v2/volumes/{volume_id}/snapshots
# operationId: volumeSnapshots_create
export def "volumes-snapshots create" [
  volume_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A human-readable name for the volume snapshot. (e.g. big-data-snapshot1475261774)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/snapshots"))
  let req_body = {"name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List All VPCs
#
# GET /v2/vpcs
# operationId: vpcs_list
export def "vpcs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<vpcs: list<record>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vpcs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a New VPC
#
# POST /v2/vpcs
# operationId: vpcs_create
export def "vpcs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A free-form text field for describing the VPC's purpose. It may be a maximum of 255 characters. (e.g. VPC for production environment)
  name: string # The name of the VPC. Must be unique and may only contain alphanumeric characters, dashes, and periods. (e.g. env.prod-vpc)
  --ip-range: string # The range of IP addresses in the VPC in CIDR notation. Network ranges cannot overlap with other networks in the same account and must be in range of private addresses as defined in RFC1918. It may not be smaller than `/28` nor larger than `/16`. If no IP range is specified, a `/20` network range is generated that won't conflict with other VPC networks in your account. (e.g. 10.10.10.0/24)
  region: string # The slug identifier for the region where the VPC will be created. (e.g. nyc1)
]: any -> record<vpc: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vpcs")
  let req_body = {"description": $description, "name": $name, "ip_range": $ip_range, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a VPC
#
# DELETE /v2/vpcs/{vpc_id}
# operationId: vpcs_delete
export def "vpcs delete" [
  vpc_id: any
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
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Existing VPC
#
# GET /v2/vpcs/{vpc_id}
# operationId: vpcs_get
export def "vpcs get" [
  vpc_id: string
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
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially Update a VPC
#
# PATCH /v2/vpcs/{vpc_id}
# operationId: vpcs_patch
export def "vpcs update-by-vpc_id" [
  vpc_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A free-form text field for describing the VPC's purpose. It may be a maximum of 255 characters. (e.g. VPC for production environment)
  --name: string # The name of the VPC. Must be unique and may only contain alphanumeric characters, dashes, and periods. (e.g. env.prod-vpc)
  --default: oneof<nothing, bool> # A boolean value indicating whether or not the VPC is the default network for the region. All applicable resources are placed into the default VPC network unless otherwise specified during their creation. The `default` field cannot be unset from `true`. If you want to set a new default VPC network, update the `default` field of another VPC network in the same region. The previous network's `default` field will be set to `false` when a new default VPC has been defined. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}"))
  let req_body = {"description": $description, "name": $name, "default": $default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update a VPC
#
# PUT /v2/vpcs/{vpc_id}
# operationId: vpcs_update
export def "vpcs update-by-vpc_id-1" [
  vpc_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A free-form text field for describing the VPC's purpose. It may be a maximum of 255 characters. (e.g. VPC for production environment)
  name: string # The name of the VPC. Must be unique and may only contain alphanumeric characters, dashes, and periods. (e.g. env.prod-vpc)
  --default: oneof<nothing, bool> # A boolean value indicating whether or not the VPC is the default network for the region. All applicable resources are placed into the default VPC network unless otherwise specified during their creation. The `default` field cannot be unset from `true`. If you want to set a new default VPC network, update the `default` field of another VPC network in the same region. The previous network's `default` field will be set to `false` when a new default VPC has been defined. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}"))
  let req_body = {"description": $description, "name": $name, "default": $default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the Member Resources of a VPC
#
# GET /v2/vpcs/{vpc_id}/members
# operationId: vpcs_list_members
export def "vpcs-members list" [
  vpc_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string # Used to filter VPC members by a resource type. (e.g. droplet)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> record<members: table<created_at: string, name: string, urn: any>, links: record<pages: any>, meta: record<total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
