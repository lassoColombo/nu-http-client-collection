# Auto-generated client for Machines API v1.0
# Source: https://docs.machines.dev/swagger/doc.json
# Auth: --token flag or $env.MACHINES_API_TOKEN

const BASE_URL = "https://api.machines.dev/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MACHINES_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.machines.dev/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/octet-stream"] }
def signal-completer [] { ["SIGHUP" "SIGINT" "SIGKILL" "SIGQUIT" "SIGTERM" "SIGUSR1" "SIGUSR2"] }
def signal-completer-1 [] { ["SIGABRT" "SIGALRM" "SIGFPE" "SIGHUP" "SIGILL" "SIGINT" "SIGKILL" "SIGPIPE" "SIGQUIT" "SIGSEGV" "SIGTERM" "SIGTRAP" "SIGUSR1" "SIGUSR2"] }
def state-completer [] { ["destroyed" "failed" "settled" "started" "stopped" "suspended"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps list" } } | get name | first)
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

# List Apps
#
# GET /apps
# operationId: Apps_list
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --org-slug: string # The org slug, or 'personal', to filter apps
  --app-role: string # Filter apps by role
]: nothing -> record<apps: table<id: string, internal_numeric_id: int, machine_count: int, name: string, network: string, organization: record, status: string, volume_count: int>, total_apps: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org_slug" $org_slug "scalar") (serialize-qp "app_role" $app_role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create App
#
# POST /apps
# operationId: Apps_create
export def "apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-subdomains: string@bool-completer
  --name: string
  --network: string
  --org-slug: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps")
  let body = {enable_subdomains: $enable_subdomains, name: $name, network: $network, org_slug: $org_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get App
#
# GET /apps/{app_name}
# operationId: Apps_show
export def "apps show" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, internal_numeric_id: int, machine_count: int, name: string, network: string, organization: record<internal_numeric_id: int, name: string, slug: string>, status: string, volume_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Destroy App
#
# DELETE /apps/{app_name}
# operationId: Apps_delete
export def "apps delete" [
  app_name: string
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
  let full_url = (build-url $base $"/apps/($app_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List certificates for app
#
# GET /apps/{app_name}/certificates
# operationId: App_Certificates_list
export def "apps-certificates list" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Hostname filter (substring match)
  --cursor: string # Pagination cursor from previous response
  --limit: int # Number of results per page (default 25, max 500)
]: nothing -> record<certificates: table<acme_alpn_configured: bool, acme_dns_configured: bool, acme_http_configured: bool, acme_requested: bool, configured: bool, created_at: string, dns_provider: string, has_custom_certificate: bool, has_fly_certificate: bool, hostname: string, ownership_txt_configured: bool, status: string, updated_at: string>, next_cursor: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request ACME certificate
#
# POST /apps/{app_name}/certificates/acme
# operationId: App_Certificates_acme_create
export def "apps-certificates-acme create" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hostname: string
]: any -> record<acme_requested: bool, certificates: table<created_at: string, expires_at: string, issued: list, issuer: string, source: string, status: string>, configured: bool, dns_provider: string, dns_requirements: record<a: list<string>, aaaa: list<string>, acme_challenge: record<name: string, target: string>, cname: string, ownership: record<app_value: string, name: string, org_value: string>>, hostname: string, rate_limited_until: string, status: string, validation: record<alpn_configured: bool, dns_configured: bool, http_configured: bool, ownership_txt_configured: bool>, validation_errors: table<code: string, message: string, remediation: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/certificates/acme")
  let body = {hostname: $hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload custom certificate
#
# POST /apps/{app_name}/certificates/custom
# operationId: App_Certificates_custom_create
export def "apps-certificates-custom create" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fullchain: string
  --hostname: string
  --private-key: string
]: any -> record<acme_requested: bool, certificates: table<created_at: string, expires_at: string, issued: list, issuer: string, source: string, status: string>, configured: bool, dns_provider: string, dns_requirements: record<a: list<string>, aaaa: list<string>, acme_challenge: record<name: string, target: string>, cname: string, ownership: record<app_value: string, name: string, org_value: string>>, hostname: string, rate_limited_until: string, status: string, validation: record<alpn_configured: bool, dns_configured: bool, http_configured: bool, ownership_txt_configured: bool>, validation_errors: table<code: string, message: string, remediation: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/certificates/custom")
  let body = {fullchain: $fullchain, hostname: $hostname, private_key: $private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get certificate details
#
# GET /apps/{app_name}/certificates/{hostname}
# operationId: App_Certificates_show
export def "apps-certificates show" [
  app_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acme_requested: bool, certificates: table<created_at: string, expires_at: string, issued: list, issuer: string, source: string, status: string>, configured: bool, dns_provider: string, dns_requirements: record<a: list<string>, aaaa: list<string>, acme_challenge: record<name: string, target: string>, cname: string, ownership: record<app_value: string, name: string, org_value: string>>, hostname: string, rate_limited_until: string, status: string, validation: record<alpn_configured: bool, dns_configured: bool, http_configured: bool, ownership_txt_configured: bool>, validation_errors: table<code: string, message: string, remediation: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/certificates/($hostname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove certificate
#
# DELETE /apps/{app_name}/certificates/{hostname}
# operationId: App_Certificates_delete
export def "apps-certificates delete" [
  app_name: string
  hostname: string
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
  let full_url = (build-url $base $"/apps/($app_name)/certificates/($hostname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove ACME certificates
#
# DELETE /apps/{app_name}/certificates/{hostname}/acme
# operationId: App_Certificates_acme_delete
export def "apps-certificates-acme delete" [
  app_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acme_requested: bool, certificates: table<created_at: string, expires_at: string, issued: list, issuer: string, source: string, status: string>, configured: bool, dns_provider: string, dns_requirements: record<a: list<string>, aaaa: list<string>, acme_challenge: record<name: string, target: string>, cname: string, ownership: record<app_value: string, name: string, org_value: string>>, hostname: string, rate_limited_until: string, status: string, validation: record<alpn_configured: bool, dns_configured: bool, http_configured: bool, ownership_txt_configured: bool>, validation_errors: table<code: string, message: string, remediation: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/certificates/($hostname)/acme")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check DNS and re-validate certificate
#
# POST /apps/{app_name}/certificates/{hostname}/check
# operationId: App_Certificates_check
export def "apps-certificates-check check" [
  app_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acme_requested: bool, certificates: table<created_at: string, expires_at: string, issued: list, issuer: string, source: string, status: string>, configured: bool, dns_provider: string, dns_records: record<a: list<string>, aaaa: list<string>, acme_challenge_cname: string, cname: list<string>, ownership_txt: string, resolved_addresses: list<string>, soa: string>, dns_requirements: record<a: list<string>, aaaa: list<string>, acme_challenge: record<name: string, target: string>, cname: string, ownership: record<app_value: string, name: string, org_value: string>>, hostname: string, rate_limited_until: string, status: string, validation: record<alpn_configured: bool, dns_configured: bool, http_configured: bool, ownership_txt_configured: bool>, validation_errors: table<code: string, message: string, remediation: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/certificates/($hostname)/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove custom certificate
#
# DELETE /apps/{app_name}/certificates/{hostname}/custom
# operationId: App_Certificates_custom_delete
export def "apps-certificates-custom delete" [
  app_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acme_requested: bool, certificates: table<created_at: string, expires_at: string, issued: list, issuer: string, source: string, status: string>, configured: bool, dns_provider: string, dns_requirements: record<a: list<string>, aaaa: list<string>, acme_challenge: record<name: string, target: string>, cname: string, ownership: record<app_value: string, name: string, org_value: string>>, hostname: string, rate_limited_until: string, status: string, validation: record<alpn_configured: bool, dns_configured: bool, http_configured: bool, ownership_txt_configured: bool>, validation_errors: table<code: string, message: string, remediation: string, timestamp: string>, warning: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/certificates/($hostname)/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create App deploy token
#
# POST /apps/{app_name}/deploy_token
# operationId: App_create_deploy_token
export def "apps-deploy-token token" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiry: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/deploy_token")
  let body = {expiry: $expiry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List IP assignments for app
#
# GET /apps/{app_name}/ip_assignments
# operationId: App_IPAssignments_list
export def "apps-ip-assignments list" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ips: table<created_at: string, ip: string, region: string, service_name: string, shared: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/ip_assignments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign new IP address to app
#
# POST /apps/{app_name}/ip_assignments
# operationId: App_IPAssignments_create
export def "apps-ip-assignments create" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --network: string
  --org-slug: string
  --region: string
  --service-name: string
  --type: string
]: any -> record<created_at: string, ip: string, region: string, service_name: string, shared: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/ip_assignments")
  let body = {network: $network, org_slug: $org_slug, region: $region, service_name: $service_name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove IP assignment from app
#
# DELETE /apps/{app_name}/ip_assignments/{ip}
# operationId: App_IPAssignments_delete
export def "apps-ip-assignments delete" [
  app_name: string
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
  let full_url = (build-url $base $"/apps/($app_name)/ip_assignments/($ip)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Machines
#
# GET /apps/{app_name}/machines
# operationId: Machines_list
export def "apps-machines list" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deleted: string@bool-completer # Include deleted machines
  --region: string # Region filter
  --state: string # comma separated list of states to filter (created, started, stopped, suspended)
  --summary: string@bool-completer # Only return summary info about machines (omit config, checks, events, host_status, nonce, etc.)
]: nothing -> table<checks: list<record>, config: record<auto_destroy: bool, cache_drive: record, checks: record, containers: list, disable_machine_autostart: bool, dns: record, env: record, files: list, guest: record, image: string, init: record, metadata: record, metrics: record, mounts: list, processes: list, restart: record, rootfs: record, schedule: string, services: list, size: string, spot: record, standbys: list, statics: list, stop_config: record>, created_at: string, events: list<record>, host_status: string, id: string, image_ref: record<digest: string, labels: record, registry: string, repository: string, tag: string>, incomplete_config: record<auto_destroy: bool, cache_drive: record, checks: record, containers: list, disable_machine_autostart: bool, dns: record, env: record, files: list, guest: record, image: string, init: record, metadata: record, metrics: record, mounts: list, processes: list, restart: record, rootfs: record, schedule: string, services: list, size: string, spot: record, standbys: list, statics: list, stop_config: record>, instance_id: string, name: string, nonce: string, private_ip: string, region: string, state: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "summary" $summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/machines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Machine
#
# POST /apps/{app_name}/machines
# operationId: Machines_create
export def "apps-machines create" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: any # An object defining the Machine configuration
  --lease-ttl: int
  --min-secrets-version: int
  --name: string # Unique name for this Machine. If omitted, one is generated for you
  --region: string # The target region. Omitting this param launches in the same region as your WireGuard peer connection (somewhere near you).
  --skip-launch: string@bool-completer
  --skip-secrets: string@bool-completer
  --skip-service-registration: string@bool-completer
]: any -> record<checks: table<name: string, output: string, status: string, updated_at: string>, config: record<auto_destroy: bool, cache_drive: record<size_mb: int>, checks: record, containers: list<record>, disable_machine_autostart: bool, dns: record<dns_forward_rules: list, hostname: string, hostname_fqdn: string, nameservers: list, options: list, searches: list, skip_registration: bool>, env: record, files: list<record>, guest: record<cpu_kind: string, cpus: int, gpu_kind: string, gpus: int, host_dedication_id: string, kernel_args: list, max_memory_mb: int, memory_mb: int, persist_rootfs: string>, image: string, init: record<cmd: list, entrypoint: list, exec: list, kernel_args: list, swap_size_mb: int, tty: bool>, metadata: record, metrics: record<https: bool, path: string, port: int>, mounts: list<record>, processes: list<record>, restart: record<gpu_bid_price: float, max_retries: int, policy: string>, rootfs: record<persist: string, size_gb: int>, schedule: string, services: list<record>, size: string, spot: record<max_price_fraction: float>, standbys: list<string>, statics: list<record>, stop_config: record<signal: string, timeout: string>>, created_at: string, events: table<id: string, request: any, source: string, status: string, timestamp: int, type: string>, host_status: string, id: string, image_ref: record<digest: string, labels: record, registry: string, repository: string, tag: string>, incomplete_config: record<auto_destroy: bool, cache_drive: record<size_mb: int>, checks: record, containers: list<record>, disable_machine_autostart: bool, dns: record<dns_forward_rules: list, hostname: string, hostname_fqdn: string, nameservers: list, options: list, searches: list, skip_registration: bool>, env: record, files: list<record>, guest: record<cpu_kind: string, cpus: int, gpu_kind: string, gpus: int, host_dedication_id: string, kernel_args: list, max_memory_mb: int, memory_mb: int, persist_rootfs: string>, image: string, init: record<cmd: list, entrypoint: list, exec: list, kernel_args: list, swap_size_mb: int, tty: bool>, metadata: record, metrics: record<https: bool, path: string, port: int>, mounts: list<record>, processes: list<record>, restart: record<gpu_bid_price: float, max_retries: int, policy: string>, rootfs: record<persist: string, size_gb: int>, schedule: string, services: list<record>, size: string, spot: record<max_price_fraction: float>, standbys: list<string>, statics: list<record>, stop_config: record<signal: string, timeout: string>>, instance_id: string, name: string, nonce: string, private_ip: string, region: string, state: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines")
  let body = {config: $config, lease_ttl: $lease_ttl, min_secrets_version: $min_secrets_version, name: $name, region: $region, skip_launch: $skip_launch, skip_secrets: $skip_secrets, skip_service_registration: $skip_service_registration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Machine
#
# GET /apps/{app_name}/machines/{machine_id}
# operationId: Machines_show
export def "apps-machines show" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<checks: table<name: string, output: string, status: string, updated_at: string>, config: record<auto_destroy: bool, cache_drive: record<size_mb: int>, checks: record, containers: list<record>, disable_machine_autostart: bool, dns: record<dns_forward_rules: list, hostname: string, hostname_fqdn: string, nameservers: list, options: list, searches: list, skip_registration: bool>, env: record, files: list<record>, guest: record<cpu_kind: string, cpus: int, gpu_kind: string, gpus: int, host_dedication_id: string, kernel_args: list, max_memory_mb: int, memory_mb: int, persist_rootfs: string>, image: string, init: record<cmd: list, entrypoint: list, exec: list, kernel_args: list, swap_size_mb: int, tty: bool>, metadata: record, metrics: record<https: bool, path: string, port: int>, mounts: list<record>, processes: list<record>, restart: record<gpu_bid_price: float, max_retries: int, policy: string>, rootfs: record<persist: string, size_gb: int>, schedule: string, services: list<record>, size: string, spot: record<max_price_fraction: float>, standbys: list<string>, statics: list<record>, stop_config: record<signal: string, timeout: string>>, created_at: string, events: table<id: string, request: any, source: string, status: string, timestamp: int, type: string>, host_status: string, id: string, image_ref: record<digest: string, labels: record, registry: string, repository: string, tag: string>, incomplete_config: record<auto_destroy: bool, cache_drive: record<size_mb: int>, checks: record, containers: list<record>, disable_machine_autostart: bool, dns: record<dns_forward_rules: list, hostname: string, hostname_fqdn: string, nameservers: list, options: list, searches: list, skip_registration: bool>, env: record, files: list<record>, guest: record<cpu_kind: string, cpus: int, gpu_kind: string, gpus: int, host_dedication_id: string, kernel_args: list, max_memory_mb: int, memory_mb: int, persist_rootfs: string>, image: string, init: record<cmd: list, entrypoint: list, exec: list, kernel_args: list, swap_size_mb: int, tty: bool>, metadata: record, metrics: record<https: bool, path: string, port: int>, mounts: list<record>, processes: list<record>, restart: record<gpu_bid_price: float, max_retries: int, policy: string>, rootfs: record<persist: string, size_gb: int>, schedule: string, services: list<record>, size: string, spot: record<max_price_fraction: float>, standbys: list<string>, statics: list<record>, stop_config: record<signal: string, timeout: string>>, instance_id: string, name: string, nonce: string, private_ip: string, region: string, state: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Machine
#
# POST /apps/{app_name}/machines/{machine_id}
# operationId: Machines_update
export def "apps-machines update" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: any # An object defining the Machine configuration
  --current-version: string
  --lease-ttl: int
  --min-secrets-version: int
  --name: string # Unique name for this Machine. If omitted, one is generated for you
  --region: string # The target region. Omitting this param launches in the same region as your WireGuard peer connection (somewhere near you).
  --skip-launch: string@bool-completer
  --skip-secrets: string@bool-completer
  --skip-service-registration: string@bool-completer
]: any -> record<checks: table<name: string, output: string, status: string, updated_at: string>, config: record<auto_destroy: bool, cache_drive: record<size_mb: int>, checks: record, containers: list<record>, disable_machine_autostart: bool, dns: record<dns_forward_rules: list, hostname: string, hostname_fqdn: string, nameservers: list, options: list, searches: list, skip_registration: bool>, env: record, files: list<record>, guest: record<cpu_kind: string, cpus: int, gpu_kind: string, gpus: int, host_dedication_id: string, kernel_args: list, max_memory_mb: int, memory_mb: int, persist_rootfs: string>, image: string, init: record<cmd: list, entrypoint: list, exec: list, kernel_args: list, swap_size_mb: int, tty: bool>, metadata: record, metrics: record<https: bool, path: string, port: int>, mounts: list<record>, processes: list<record>, restart: record<gpu_bid_price: float, max_retries: int, policy: string>, rootfs: record<persist: string, size_gb: int>, schedule: string, services: list<record>, size: string, spot: record<max_price_fraction: float>, standbys: list<string>, statics: list<record>, stop_config: record<signal: string, timeout: string>>, created_at: string, events: table<id: string, request: any, source: string, status: string, timestamp: int, type: string>, host_status: string, id: string, image_ref: record<digest: string, labels: record, registry: string, repository: string, tag: string>, incomplete_config: record<auto_destroy: bool, cache_drive: record<size_mb: int>, checks: record, containers: list<record>, disable_machine_autostart: bool, dns: record<dns_forward_rules: list, hostname: string, hostname_fqdn: string, nameservers: list, options: list, searches: list, skip_registration: bool>, env: record, files: list<record>, guest: record<cpu_kind: string, cpus: int, gpu_kind: string, gpus: int, host_dedication_id: string, kernel_args: list, max_memory_mb: int, memory_mb: int, persist_rootfs: string>, image: string, init: record<cmd: list, entrypoint: list, exec: list, kernel_args: list, swap_size_mb: int, tty: bool>, metadata: record, metrics: record<https: bool, path: string, port: int>, mounts: list<record>, processes: list<record>, restart: record<gpu_bid_price: float, max_retries: int, policy: string>, rootfs: record<persist: string, size_gb: int>, schedule: string, services: list<record>, size: string, spot: record<max_price_fraction: float>, standbys: list<string>, statics: list<record>, stop_config: record<signal: string, timeout: string>>, instance_id: string, name: string, nonce: string, private_ip: string, region: string, state: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)")
  let body = {config: $config, current_version: $current_version, lease_ttl: $lease_ttl, min_secrets_version: $min_secrets_version, name: $name, region: $region, skip_launch: $skip_launch, skip_secrets: $skip_secrets, skip_service_registration: $skip_service_registration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Destroy Machine
#
# DELETE /apps/{app_name}/machines/{machine_id}
# operationId: Machines_delete
export def "apps-machines delete" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # Force kill the machine if it's running
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cordon Machine
#
# POST /apps/{app_name}/machines/{machine_id}/cordon
# operationId: Machines_cordon
export def "apps-machines-cordon cordon" [
  app_name: string
  machine_id: string
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
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/cordon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Events
#
# GET /apps/{app_name}/machines/{machine_id}/events
# operationId: Machines_list_events
export def "apps-machines-events events" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to fetch (max of 50). If omitted, this is set to 20 by default.
]: nothing -> table<id: string, request: any, source: string, status: string, timestamp: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute Command
#
# POST /apps/{app_name}/machines/{machine_id}/exec
# operationId: Machines_exec
export def "apps-machines-exec exec" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --cmd: string # Deprecated: use Command instead
  --command: list
  --container: string
  --stdin: string
  --timeout: int
]: any -> record<exit_code: int, exit_signal: int, stderr: string, stdout: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/exec")
  let body = {cmd: $cmd, command: $command, container: $container, stdin: $stdin, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Lease
#
# GET /apps/{app_name}/machines/{machine_id}/lease
# operationId: Machines_show_lease
export def "apps-machines-lease lease-by-app_name-machine_id" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, expires_at: int, nonce: string, owner: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/lease")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Lease
#
# POST /apps/{app_name}/machines/{machine_id}/lease
# operationId: Machines_create_lease
export def "apps-machines-lease lease-by-app_name-machine_id-1" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fly-machine-lease-nonce: string # Existing lease nonce to refresh by ttl, empty or non-existent to create a new lease
  --description: string
  --ttl: int # seconds lease will be valid
]: any -> record<description: string, expires_at: int, nonce: string, owner: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/lease")
  let body = {description: $description, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"fly-machine-lease-nonce": $fly_machine_lease_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Release Lease
#
# DELETE /apps/{app_name}/machines/{machine_id}/lease
# operationId: Machines_release_lease
export def "apps-machines-lease lease-by-app_name-machine_id-2" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fly-machine-lease-nonce: string # Existing lease nonce
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/lease")
  let extra_headers = {"fly-machine-lease-nonce": $fly_machine_lease_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Machine Memory
#
# GET /apps/{app_name}/machines/{machine_id}/memory
# operationId: Machines_get_memory
export def "apps-machines-memory memory" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<available_mb: int, limit_mb: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/memory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Machine Memory Limit
#
# PUT /apps/{app_name}/machines/{machine_id}/memory
# operationId: Machines_set_memory_limit
export def "apps-machines-memory limit" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit-mb: int
]: any -> record<available_mb: int, limit_mb: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/memory")
  let body = {limit_mb: $limit_mb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reclaim Machine Memory
#
# POST /apps/{app_name}/machines/{machine_id}/memory/reclaim
# operationId: Machines_reclaim_memory
export def "apps-machines-memory-reclaim memory" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount-mb: int
]: any -> record<actual_mb: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/memory/reclaim")
  let body = {amount_mb: $amount_mb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Metadata
#
# GET /apps/{app_name}/machines/{machine_id}/metadata
# operationId: Machines_show_metadata
export def "apps-machines-metadata metadata-by-app_name-machine_id" [
  app_name: string
  machine_id: string
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
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Metadata (set/remove multiple keys)
#
# PUT /apps/{app_name}/machines/{machine_id}/metadata
# operationId: Machines_update_metadata
export def "apps-machines-metadata metadata-by-app_name-machine_id-1" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --machine-version: string
  --metadata: record
  --updated-at: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/metadata")
  let body = {machine_version: $machine_version, metadata: $metadata, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Metadata (set/remove multiple keys)
#
# PATCH /apps/{app_name}/machines/{machine_id}/metadata
# operationId: Machines_update_metadata
export def "apps-machines-metadata metadata-by-app_name-machine_id-2" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --machine-version: string
  --metadata: record
  --updated-at: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/metadata")
  let body = {machine_version: $machine_version, metadata: $metadata, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Metadata Value
#
# GET /apps/{app_name}/machines/{machine_id}/metadata/{key}
# operationId: Machines_get_metadata_key
export def "apps-machines-metadata key" [
  app_name: string
  machine_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/metadata/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Metadata Key
#
# POST /apps/{app_name}/machines/{machine_id}/metadata/{key}
# operationId: Machines_upsert_metadata
export def "apps-machines-metadata metadata-by-app_name-machine_id-key" [
  app_name: string
  machine_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updated-at: string
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/metadata/($key)")
  let body = {updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Metadata
#
# DELETE /apps/{app_name}/machines/{machine_id}/metadata/{key}
# operationId: Machines_delete_metadata
export def "apps-machines-metadata metadata-by-app_name-machine_id-key-1" [
  app_name: string
  machine_id: string
  key: string
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
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/metadata/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Processes
#
# GET /apps/{app_name}/machines/{machine_id}/ps
# operationId: Machines_list_processes
export def "apps-machines-ps processes" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string # Sort by
  --order: string # Order
]: nothing -> table<command: string, cpu: int, directory: string, listen_sockets: list<record>, pid: int, rss: int, rtime: int, stime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/ps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart Machine
#
# POST /apps/{app_name}/machines/{machine_id}/restart
# operationId: Machines_restart
export def "apps-machines-restart restart" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: string # Restart timeout as a Go duration string or number of seconds
  --signal: string@signal-completer # Unix signal name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "signal" $signal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Signal Machine
#
# POST /apps/{app_name}/machines/{machine_id}/signal
# operationId: Machines_signal
export def "apps-machines-signal signal" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string@signal-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/signal")
  let body = {signal: $signal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start Machine
#
# POST /apps/{app_name}/machines/{machine_id}/start
# operationId: Machines_start
export def "apps-machines-start start" [
  app_name: string
  machine_id: string
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
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop Machine
#
# POST /apps/{app_name}/machines/{machine_id}/stop
# operationId: Machines_stop
export def "apps-machines-stop stop" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string@signal-completer # e.g. SIGTERM
  --timeout: string # e.g. 1s
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/stop")
  let body = {signal: $signal, timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Suspend Machine
#
# POST /apps/{app_name}/machines/{machine_id}/suspend
# operationId: Machines_suspend
export def "apps-machines-suspend suspend" [
  app_name: string
  machine_id: string
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
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Uncordon Machine
#
# POST /apps/{app_name}/machines/{machine_id}/uncordon
# operationId: Machines_uncordon
export def "apps-machines-uncordon uncordon" [
  app_name: string
  machine_id: string
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
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/uncordon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Versions
#
# GET /apps/{app_name}/machines/{machine_id}/versions
# operationId: Machines_list_versions
export def "apps-machines-versions versions" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<user_config: record<auto_destroy: bool, cache_drive: record, checks: record, containers: list, disable_machine_autostart: bool, dns: record, env: record, files: list, guest: record, image: string, init: record, metadata: record, metrics: record, mounts: list, processes: list, restart: record, rootfs: record, schedule: string, services: list, size: string, spot: record, standbys: list, statics: list, stop_config: record>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Wait for State
#
# GET /apps/{app_name}/machines/{machine_id}/wait
# operationId: Machines_wait
export def "apps-machines-wait wait" [
  app_name: string
  machine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # 26-character Machine version ID
  --instance-id: string # 26-character Machine version ID (deprecated; use version)
  --from-event-id: string # 26-character Machine event ID to start waiting after
  --timeout: int # wait timeout. default 60s
  --state: string@state-completer # desired state(s), supports repeated or comma-separated values
]: nothing -> record<event_id: string, ok: bool, state: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "instance_id" $instance_id "scalar") (serialize-qp "from_event_id" $from_event_id "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/machines/($machine_id)/wait" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List secret keys belonging to an app
#
# GET /apps/{app_name}/secretkeys
# operationId: Secretkeys_list
export def "apps-secretkeys list" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --types: string # Comma-seperated list of secret keys to list
]: nothing -> record<secret_keys: table<created_at: string, name: string, public_key: list, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar") (serialize-qp "types" $types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an app's secret key
#
# GET /apps/{app_name}/secretkeys/{secret_name}
# operationId: Secretkey_get
export def "apps-secretkeys get" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
]: nothing -> record<created_at: string, name: string, public_key: list<int>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a secret key
#
# POST /apps/{app_name}/secretkeys/{secret_name}
# operationId: Secretkey_set
export def "apps-secretkeys set" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string
  --value: list
]: any -> record<Version: int, created_at: string, name: string, public_key: list<int>, type: string, updated_at: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)")
  let body = {type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an app's secret key
#
# DELETE /apps/{app_name}/secretkeys/{secret_name}
# operationId: Secretkey_delete
export def "apps-secretkeys delete" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Version: int, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decrypt with a secret key
#
# POST /apps/{app_name}/secretkeys/{secret_name}/decrypt
# operationId: Secretkey_decrypt
export def "apps-secretkeys-decrypt decrypt" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --associated-data: list
  --ciphertext: list
]: any -> record<plaintext: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)/decrypt" $qp)
  let body = {associated_data: $associated_data, ciphertext: $ciphertext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Encrypt with a secret key
#
# POST /apps/{app_name}/secretkeys/{secret_name}/encrypt
# operationId: Secretkey_encrypt
export def "apps-secretkeys-encrypt encrypt" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --associated-data: list
  --plaintext: list
]: any -> record<ciphertext: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)/encrypt" $qp)
  let body = {associated_data: $associated_data, plaintext: $plaintext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a random secret key
#
# POST /apps/{app_name}/secretkeys/{secret_name}/generate
# operationId: Secretkey_generate
export def "apps-secretkeys-generate generate" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string
  --value: list
]: any -> record<Version: int, created_at: string, name: string, public_key: list<int>, type: string, updated_at: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)/generate")
  let body = {type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sign with a secret key
#
# POST /apps/{app_name}/secretkeys/{secret_name}/sign
# operationId: Secretkey_sign
export def "apps-secretkeys-sign sign" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --plaintext: list
]: any -> record<signature: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)/sign" $qp)
  let body = {plaintext: $plaintext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify with a secret key
#
# POST /apps/{app_name}/secretkeys/{secret_name}/verify
# operationId: Secretkey_verify
export def "apps-secretkeys-verify verify" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --plaintext: list
  --signature: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secretkeys/($secret_name)/verify" $qp)
  let body = {plaintext: $plaintext, signature: $signature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List app secrets belonging to an app
#
# GET /apps/{app_name}/secrets
# operationId: Secrets_list
export def "apps-secrets list" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --show-secrets: string@bool-completer # Show the secret values.
]: nothing -> record<secrets: table<created_at: string, digest: string, name: string, updated_at: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar") (serialize-qp "show_secrets" $show_secrets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update app secrets belonging to an app
#
# POST /apps/{app_name}/secrets
# operationId: Secrets_update
export def "apps-secrets update" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --values: record
]: any -> record<Version: int, secrets: table<created_at: string, digest: string, name: string, updated_at: string, value: string>, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/secrets")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an app secret
#
# GET /apps/{app_name}/secrets/{secret_name}
# operationId: Secret_get
export def "apps-secrets get" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --min-version: string # Minimum secrets version to return. Returned when setting a new secret
  --show-secrets: string@bool-completer # Show the secret value.
]: nothing -> record<created_at: string, digest: string, name: string, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_version" $min_version "scalar") (serialize-qp "show_secrets" $show_secrets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/secrets/($secret_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update Secret
#
# POST /apps/{app_name}/secrets/{secret_name}
# operationId: Secret_create
export def "apps-secrets create" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: string
]: any -> record<Version: int, created_at: string, digest: string, name: string, updated_at: string, value: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/secrets/($secret_name)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an app secret
#
# DELETE /apps/{app_name}/secrets/{secret_name}
# operationId: Secret_delete
export def "apps-secrets delete" [
  app_name: string
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Version: int, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/secrets/($secret_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Volumes
#
# GET /apps/{app_name}/volumes
# operationId: Volumes_list
export def "apps-volumes list" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --summary: string@bool-completer # Only return summary info about volumes (omit blocks, block size, etc)
]: nothing -> table<attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summary" $summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($app_name)/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Volume
#
# POST /apps/{app_name}/volumes
# operationId: Volumes_create
# --compute shape: {cpu_kind?: string, cpus?: int, gpu_kind?: string, gpus?: int, host_dedication_id?: string, kernel_args?: list, max_memory_mb?: int, memory_mb?: int, persist_rootfs?: "never"|"always"|"restart"}
export def "apps-volumes create" [
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-backup-enabled: string@bool-completer # enable scheduled automatic snapshots. Defaults to `true`
  --compute: record # shape: {cpu_kind?: string, cpus?: int, gpu_kind?: string, gpus?: int, host_dedication_id?: string, kernel_args?: list, max_memory_mb?: int, memory_mb?: int, persist_rootfs?: "never"|"always"|"restart"}
  --compute-image: string
  --encrypted: string@bool-completer
  --fstype: string
  --name: string
  --region: string
  --require-unique-zone: string@bool-completer
  --size-gb: int
  --snapshot-id: string # restore from snapshot
  --snapshot-retention: int
  --source-volume-id: string # fork from remote volume
  --unique-zone-app-wide: string@bool-completer
]: any -> record<attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/volumes")
  let body = {auto_backup_enabled: $auto_backup_enabled, compute: $compute, compute_image: $compute_image, encrypted: $encrypted, fstype: $fstype, name: $name, region: $region, require_unique_zone: $require_unique_zone, size_gb: $size_gb, snapshot_id: $snapshot_id, snapshot_retention: $snapshot_retention, source_volume_id: $source_volume_id, unique_zone_app_wide: $unique_zone_app_wide} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Volume
#
# GET /apps/{app_name}/volumes/{volume_id}
# operationId: Volumes_get_by_id
export def "apps-volumes id" [
  app_name: string
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/volumes/($volume_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Volume
#
# PUT /apps/{app_name}/volumes/{volume_id}
# operationId: Volumes_update
export def "apps-volumes update" [
  app_name: string
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-backup-enabled: string@bool-completer
  --snapshot-retention: int
]: any -> record<attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/volumes/($volume_id)")
  let body = {auto_backup_enabled: $auto_backup_enabled, snapshot_retention: $snapshot_retention} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Destroy Volume
#
# DELETE /apps/{app_name}/volumes/{volume_id}
# operationId: Volume_delete
export def "apps-volumes delete" [
  app_name: string
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/volumes/($volume_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extend Volume
#
# PUT /apps/{app_name}/volumes/{volume_id}/extend
# operationId: Volumes_extend
export def "apps-volumes-extend extend" [
  app_name: string
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size-gb: int
]: any -> record<needs_restart: bool, volume: record<attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, zone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/volumes/($volume_id)/extend")
  let body = {size_gb: $size_gb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Snapshots
#
# GET /apps/{app_name}/volumes/{volume_id}/snapshots
# operationId: Volumes_list_snapshots
export def "apps-volumes-snapshots snapshots" [
  app_name: string
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<created_at: string, digest: string, id: string, retention_days: int, size: int, status: string, volume_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($app_name)/volumes/($volume_id)/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Snapshot
#
# POST /apps/{app_name}/volumes/{volume_id}/snapshots
# operationId: createVolumeSnapshot
export def "apps-volumes-snapshots createVolumeSnapshot" [
  app_name: string
  volume_id: string
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
  let full_url = (build-url $base $"/apps/($app_name)/volumes/($volume_id)/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Machines
#
# GET /orgs/{org_slug}/machines
# operationId: Machines_org_list
export def "orgs-machines list" [
  org_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deleted: string@bool-completer # Include deleted machines
  --region: string # Region filter
  --state: string # Comma separated list of states to filter (created, started, stopped, suspended)
  --summary: string@bool-completer # Omit config from responses
  --updated-after: string # Only return machines updated after this time. Timestamp must be in the RFC 3339 format
  --cursor: string # Pagination cursor from previous response (takes precedence over updated_after). Note that there is no guarantee that all machines returned by this endpoint are sorted by their updated_at fields. Pagination may reveal machines older than the last updated_at.
  --limit: int # The number of machines to fetch (max of 1000). This limit is advisory. Responses may be shorter, or even empty, even when more machines remain. If omitted, the maximum is used
]: nothing -> record<error_regions: list<string>, last_machine_id: string, last_updated_at: string, machines: table<app_name: string, config: record, created_at: string, id: string, name: string, private_ip: string, region: string, state: string, updated_at: string, version: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "summary" $summary "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_slug)/machines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Volumes
#
# GET /orgs/{org_slug}/volumes
# operationId: Volumes_org_list
export def "orgs-volumes list" [
  org_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deleted: string@bool-completer # Include deleted volumes
  --region: string # Region filter
  --state: string # Comma separated list of volume states to filter
  --summary: string@bool-completer # Only return summary info about volumes (omit blocks, block size, etc)
  --updated-after: string # Only return volumes updated after this time. Timestamp must be in the RFC 3339 format
  --cursor: string # Pagination cursor from previous response (takes precedence over updated_after)
  --limit: int # The number of volumes to fetch (max of 1000). This limit is advisory. Responses may be shorter, even when more volumes remain. If omitted, the maximum is used
]: nothing -> record<last_updated_at: string, last_volume_id: string, next_cursor: string, volumes: table<app_name: string, attached_alloc_id: string, attached_machine_id: string, auto_backup_enabled: bool, block_size: int, blocks: int, blocks_avail: int, blocks_free: int, bytes_total: int, bytes_used: int, created_at: string, encrypted: bool, fstype: string, host_status: string, id: string, name: string, region: string, size_gb: int, snapshot_retention: int, state: string, type: string, updated_at: string, zone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_deleted" $include_deleted "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "summary" $summary "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org_slug)/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Placements
#
# POST /platform/placements
# operationId: Platform_placements_post
export def "platform-placements post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --compute: any # Resource requirements for the Machine to simulate. Defaults to a performance-1x machine
  --count: int # Number of machines to simulate placement. Defaults to 0, which returns the org-specific limit for each region.
  org_slug: string # e.g. personal
  --region: string # Region expression for placement as a comma-delimited set of regions or aliases. Defaults to "[region],any", to prefer the API endpoint's local region with any other region as fallback. (e.g. lhr,eu)
  --volume-name: string # e.g. 
  --volume-size-bytes: int
  --weights: any # Optional weights to override default placement preferences. (e.g. {region: 1000, spread: 0})
]: any -> record<regions: table<concurrency: int, count: int, region: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/platform/placements")
  let body = {compute: $compute, count: $count, org_slug: $org_slug, region: $region, volume_name: $volume_name, volume_size_bytes: $volume_size_bytes, weights: $weights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Regions
#
# GET /platform/regions
# operationId: Platform_regions_get
export def "platform-regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nearest: string, regions: table<code: string, deprecated: bool, gateway_available: bool, geo_region: string, latitude: float, longitude: float, name: string, requires_paid_plan: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/platform/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate token header
#
# POST /tokens/authenticate
# operationId: Tokens_authenticate
export def "tokens-authenticate authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --header: string
]: any -> table<caveats: record<caveats: list>, header: string, nonce: record<kid: list, proof: bool, rnd: list>, permission_token: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/authenticate")
  let body = {header: $header} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorize token for resource access
#
# POST /tokens/authorize
# operationId: Tokens_authorize
# --access shape: {action?: any, app_feature?: string, app_name?: string, command?: list, machine_feature?: string, machine_id?: string, mutation?: string, org_feature?: string, org_slug?: string, source_machine?: string, storage_object?: string, volume_id?: string}
export def "tokens-authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access: record # shape: {action?: any, app_feature?: string, app_name?: string, command?: list, machine_feature?: string, machine_id?: string, mutation?: string, org_feature?: string, org_slug?: string, source_machine?: string, storage_object?: string, volume_id?: string}
  --header: string
]: any -> record<access: record<action: int, app_feature: string, appid: int, cluster: string, command: list<string>, feature: string, machine: string, machine_feature: string, mutation: string, orgid: int, sourceApp: string, sourceMachine: string, sourceOrganization: string, storage_object: string, volume: string>, verified_token: record<caveats: record<caveats: list>, header: string, nonce: record<kid: list, proof: bool, rnd: list>, permission_token: list<int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/authorize")
  let body = {access: $access, header: $header} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Current Token Information
#
# GET /tokens/current
# operationId: CurrentToken_show
export def "tokens-current show" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tokens: table<apps: list, org_slug: string, organization: string, restricted_to_machine: string, source_machine_id: string, token_id: string, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request a Petsem token for accessing KMS
#
# POST /tokens/kms
# operationId: Tokens_request_Kms
export def "tokens-kms Kms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/kms")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request an OIDC token
#
# POST /tokens/oidc
# operationId: Tokens_request_OIDC
export def "tokens-oidc OIDC" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aud: string # e.g. https://fly.io/org-slug
  --aws-principal-tags: string@bool-completer
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens/oidc")
  let body = {aud: $aud, aws_principal_tags: $aws_principal_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
