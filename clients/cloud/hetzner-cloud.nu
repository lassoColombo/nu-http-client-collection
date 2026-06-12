# Auto-generated client for Hetzner Cloud API v1.0.0
# Source: https://api.apis.guru/v2/specs/hetzner.cloud/1.0.0/openapi.json
# Auth: --token flag or $env.HETZNER_CLOUD_API_TOKEN

const BASE_URL = "https://api.hetzner.cloud/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HETZNER_CLOUD_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.hetzner.cloud/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["command" "command:asc" "command:desc" "finished" "finished:asc" "finished:desc" "id" "id:asc" "id:desc" "progress" "progress:asc" "progress:desc" "started" "started:asc" "started:desc" "status" "status:asc" "status:desc"] }
def status-completer [] { ["error" "running" "success"] }
def sort-completer-1 [] { ["created" "created:asc" "created:desc" "id" "id:asc" "id:desc" "name" "name:asc" "name:desc"] }
def type-completer [] { ["managed" "uploaded"] }
def sort-completer-2 [] { ["created" "created:asc" "created:desc" "id" "id:asc" "id:desc"] }
def type-completer-1 [] { ["ipv4" "ipv6"] }
def type-completer-2 [] { ["app" "backup" "snapshot" "system"] }
def status-completer-1 [] { ["available" "creating"] }
def type-completer-3 [] { ["snapshot"] }
def protocol-completer [] { ["http" "https" "tcp"] }
def type-completer-4 [] { ["ip" "label_selector" "server"] }
def type-completer-5 [] { ["least_connections" "round_robin"] }
def type-completer-6 [] { ["bandwidth" "connections_per_second" "open_connections" "requests_per_second"] }
def type-completer-7 [] { ["cloud" "server" "vswitch"] }
def type-completer-8 [] { ["spread"] }
def assignee-type-completer [] { ["server"] }
def status-completer-2 [] { ["deleting" "initializing" "migrating" "off" "rebuilding" "running" "starting" "stopping" "unknown"] }
def type-completer-9 [] { ["backup" "snapshot"] }
def type-completer-10 [] { ["linux32" "linux64"] }
def type-completer-11 [] { ["cpu" "disk" "network"] }
def sort-completer-3 [] { ["id" "id:asc" "id:desc" "name" "name:asc" "name:desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions list" } } | get name | first)
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

# Get all Actions
#
# GET /actions
export def "actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # Can be used multiple times, the response will contain only Actions with specified IDs
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Action
#
# GET /actions/{id}
export def "actions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/actions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Certificates
#
# GET /certificates
export def "certificates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --type: string@type-completer # Can be used multiple times. The response will only contain Certificates matching the type.
]: nothing -> record<certificates: table<certificate: string, created: string, domain_names: list, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record, type: string, used_by: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Certificate
#
# POST /certificates
export def "certificates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certificate: string # Certificate and chain in PEM format, in order so that each record directly certifies the one preceding. Required for type `uploaded` Certificates. (e.g. -----BEGIN CERTIFICATE----- ...)
  --domain-names: list # Domains and subdomains that should be contained in the Certificate issued by *Let's Encrypt*. Required for type `managed` Certificates.
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the Certificate (e.g. my website cert)
  --private-key: string # Certificate key in PEM format. Required for type `uploaded` Certificates. (e.g. -----BEGIN PRIVATE KEY----- ...)
  --type: string@type-completer # Choose between uploading a Certificate in PEM format or requesting a managed *Let's Encrypt* Certificate. If omitted defaults to `uploaded`. (e.g. uploaded)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/certificates")
  let body = {certificate: $certificate, domain_names: $domain_names, labels: $labels, name: $name, private_key: $private_key, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Certificate
#
# DELETE /certificates/{id}
export def "certificates delete" [
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
  let full_url = (build-url $base $"/certificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Certificate
#
# GET /certificates/{id}
export def "certificates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/certificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Certificate
#
# PUT /certificates/{id}
export def "certificates put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New Certificate name (e.g. my website cert)
]: any -> record<certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/certificates/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Certificate
#
# GET /certificates/{id}/actions
export def "certificates-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/certificates/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry Issuance or Renewal
#
# POST /certificates/{id}/actions/retry
export def "certificates-actions-retry post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/certificates/($id)/actions/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Action for a Certificate
#
# GET /certificates/{id}/actions/{action_id}
export def "certificates-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/certificates/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Datacenters
#
# GET /datacenters
export def "datacenters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter Datacenters by their name. The response will only contain the Datacenter matching the specified name. When the name does not match the Datacenter name format, an `invalid_input` error is returned.
]: nothing -> record<datacenters: table<description: string, id: int, location: record, name: string, server_types: record>, recommendation: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datacenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Datacenter
#
# GET /datacenters/{id}
export def "datacenters get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<datacenter: record<description: string, id: int, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, server_types: record<available: list, available_for_migration: list, supported: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datacenters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Firewalls
#
# GET /firewalls
export def "firewalls list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> record<firewalls: table<applied_to: list, created: string, id: int, labels: record, name: string, rules: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/firewalls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Firewall
#
# POST /firewalls
# --apply_to item shape: {label_selector?: record, server?: record, type: "server"|"label_selector"}
# --rules item shape: {description?: string, destination_ips?: list, direction: "in"|"out", port?: string, protocol: "tcp"|"udp"|"icmp"|"esp"|"gre", source_ips?: list}
export def "firewalls post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apply-to: list # Resources the Firewall should be applied to after creation — item shape: {label_selector?: record, server?: record, type: "server"|"label_selector"}
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the Firewall (e.g. Corporate Intranet Protection)
  --rules: list # Array of rules (e.g. [{direction: in, port: 80, protocol: tcp, source_ips: [28.239.13.1/32, 28.239.14.0/24, ff21:1eac:9a3b:ee58:5ca:990c:8bc9:c03b/128]}]) — item shape: {description?: string, destination_ips?: list, direction: "in"|"out", port?: string, protocol: "tcp"|"udp"|"icmp"|"esp"|"gre", source_ips?: list}
]: any -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/firewalls")
  let body = {apply_to: $apply_to, labels: $labels, name: $name, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Firewall
#
# DELETE /firewalls/{id}
export def "firewalls delete" [
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
  let full_url = (build-url $base $"/firewalls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Firewall
#
# GET /firewalls/{id}
export def "firewalls get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/firewalls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Firewall
#
# PUT /firewalls/{id}
export def "firewalls put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New Firewall name (e.g. new-name)
]: any -> record<firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/firewalls/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Firewall
#
# GET /firewalls/{id}/actions
export def "firewalls-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/firewalls/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply to Resources
#
# POST /firewalls/{id}/actions/apply_to_resources
# --apply_to item shape: {label_selector?: record, server?: record, type?: "server"|"label_selector"}
export def "firewalls-actions-apply-to-resources post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  apply_to: list # Resources the Firewall should be applied to — item shape: {label_selector?: record, server?: record, type?: "server"|"label_selector"}
]: any -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/firewalls/($id)/actions/apply_to_resources")
  let body = {apply_to: $apply_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove from Resources
#
# POST /firewalls/{id}/actions/remove_from_resources
# --remove_from item shape: {label_selector?: record, server?: record, type?: "server"|"label_selector"}
export def "firewalls-actions-remove-from-resources post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  remove_from: list # Resources the Firewall should be removed from — item shape: {label_selector?: record, server?: record, type?: "server"|"label_selector"}
]: any -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/firewalls/($id)/actions/remove_from_resources")
  let body = {remove_from: $remove_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Rules
#
# POST /firewalls/{id}/actions/set_rules
# --rules item shape: {description?: string, destination_ips?: list, direction: "in"|"out", port?: string, protocol: "tcp"|"udp"|"icmp"|"esp"|"gre", source_ips?: list}
export def "firewalls-actions-set-rules post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  rules: list # Array of rules — item shape: {description?: string, destination_ips?: list, direction: "in"|"out", port?: string, protocol: "tcp"|"udp"|"icmp"|"esp"|"gre", source_ips?: list}
]: any -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/firewalls/($id)/actions/set_rules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Action for a Firewall
#
# GET /firewalls/{id}/actions/{action_id}
export def "firewalls-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/firewalls/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Floating IPs
#
# GET /floating_ips
export def "floating-ips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter Floating IPs by their name. The response will only contain the Floating IP matching the specified name.
  --label-selector: string # Can be used to filter Floating IPs by labels. The response will only contain Floating IPs matching the label selector.
  --qp-sort: string@sort-completer-2 # Can be used multiple times. Choices id id:asc id:desc created created:asc created:desc
]: nothing -> record<floating_ips: table<blocked: bool, created: string, description: string, dns_ptr: list, home_location: record, id: int, ip: string, labels: record, name: string, protection: record, server: int, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/floating_ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Floating IP
#
# POST /floating_ips
export def "floating-ips post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # e.g. Web Frontend
  --home-location: string # Home Location (routing is optimized for that Location). Only optional if Server argument is passed. (e.g. fsn1)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # e.g. Web Frontend
  --server: int # Server to assign the Floating IP to (e.g. 42)
  type: string@type-completer-1 # Floating IP type
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/floating_ips")
  let body = {description: $description, home_location: $home_location, labels: $labels, name: $name, server: $server, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Floating IP
#
# DELETE /floating_ips/{id}
export def "floating-ips delete" [
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
  let full_url = (build-url $base $"/floating_ips/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Floating IP
#
# GET /floating_ips/{id}
export def "floating-ips get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Floating IP
#
# PUT /floating_ips/{id}
export def "floating-ips put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # New Description to set (e.g. Web Frontend)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New unique name to set (e.g. Web Frontend)
]: any -> record<floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)")
  let body = {description: $description, labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Floating IP
#
# GET /floating_ips/{id}/actions
export def "floating-ips-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/floating_ips/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a Floating IP to a Server
#
# POST /floating_ips/{id}/actions/assign
export def "floating-ips-actions-assign post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  server: int # ID of the Server the Floating IP shall be assigned to (e.g. 42)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)/actions/assign")
  let body = {server: $server} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change reverse DNS entry for a Floating IP
#
# POST /floating_ips/{id}/actions/change_dns_ptr
export def "floating-ips-actions-change-dns-ptr post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry, will reset to original default value if `null` (nullable, e.g. server02.example.com)
  ip: string # IP address for which to set the reverse DNS entry (e.g. 1.2.3.4)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)/actions/change_dns_ptr")
  let body = {dns_ptr: $dns_ptr, ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Floating IP Protection
#
# POST /floating_ips/{id}/actions/change_protection
export def "floating-ips-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the Floating IP from being deleted (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)/actions/change_protection")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a Floating IP
#
# POST /floating_ips/{id}/actions/unassign
export def "floating-ips-actions-unassign post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)/actions/unassign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Action for a Floating IP
#
# GET /floating_ips/{id}/actions/{action_id}
export def "floating-ips-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/floating_ips/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Images
#
# GET /images
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --type: string@type-completer-2 # Can be used multiple times.
  --status: string@status-completer-1 # Can be used multiple times. The response will only contain Images matching the status.
  --bound-to: string # Can be used multiple times. Server ID linked to the Image. Only available for Images of type `backup`
  --include-deprecated: oneof<nothing, bool> # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> record<images: table<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "bound_to" $bound_to "scalar") (serialize-qp "include_deprecated" $include_deprecated "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Image
#
# DELETE /images/{id}
export def "images delete" [
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
  let full_url = (build-url $base $"/images/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Image
#
# GET /images/{id}
export def "images get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Image
#
# PUT /images/{id}
export def "images put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # New description of Image (e.g. My new Image description)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --type: string@type-completer-3 # Destination Image type to convert to
]: any -> record<image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($id)")
  let body = {description: $description, labels: $labels, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for an Image
#
# GET /images/{id}/actions
export def "images-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Image Protection
#
# POST /images/{id}/actions/change_protection
export def "images-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the snapshot from being deleted (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($id)/actions/change_protection")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Action for an Image
#
# GET /images/{id}/actions/{action_id}
export def "images-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all ISOs
#
# GET /isos
export def "isos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter ISOs by their name. The response will only contain the ISO matching the specified name.
]: nothing -> record<isos: table<deprecated: string, description: string, id: int, name: string, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/isos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an ISO
#
# GET /isos/{id}
export def "isos get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<iso: record<deprecated: string, description: string, id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/isos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Load Balancer Types
#
# GET /load_balancer_types
export def "load-balancer-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter Load Balancer types by their name. The response will only contain the Load Balancer type matching the specified name.
]: nothing -> record<load_balancer_types: table<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/load_balancer_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Load Balancer Type
#
# GET /load_balancer_types/{id}
export def "load-balancer-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancer_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Load Balancers
#
# GET /load_balancers
export def "load-balancers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> record<load_balancers: table<algorithm: record, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record, location: record, name: string, outgoing_traffic: int, private_net: list, protection: record, public_net: record, services: list, targets: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/load_balancers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Load Balancer
#
# POST /load_balancers
# --algorithm shape: {type: "round_robin"|"least_connections"}
# --labels shape: {labelkey?: string}
# --services item shape: {destination_port: int, health_check: record, http?: record, listen_port: int, protocol: "tcp"|"http"|"https", proxyprotocol: bool}
# --targets item shape: {health_status?: list, ip?: record, label_selector?: record, server?: record, targets?: list, type: "server"|"label_selector"|"ip", use_private_ip?: bool}
export def "load-balancers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  algorithm: record # Algorithm of the Load Balancer — shape: {type: "round_robin"|"least_connections"}
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  load_balancer_type: string # ID or name of the Load Balancer type this Load Balancer should be created with (e.g. lb11)
  --location: string # ID or name of Location to create Load Balancer in
  name: string # Name of the Load Balancer (e.g. Web Frontend)
  --network: int # ID of the network the Load Balancer should be attached to on creation (e.g. 123)
  --network-zone: string # Name of network zone (e.g. eu-central)
  --public-interface: oneof<nothing, bool> # Enable or disable the public interface of the Load Balancer (e.g. true)
  --services: list # Array of services — item shape: {destination_port: int, health_check: record, http?: record, listen_port: int, protocol: "tcp"|"http"|"https", proxyprotocol: bool}
  --targets: list # Array of targets — item shape: {health_status?: list, ip?: record, label_selector?: record, server?: record, targets?: list, type: "server"|"label_selector"|"ip", use_private_ip?: bool}
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/load_balancers")
  let body = {algorithm: $algorithm, labels: $labels, load_balancer_type: $load_balancer_type, location: $location, name: $name, network: $network, network_zone: $network_zone, public_interface: $public_interface, services: $services, targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Load Balancer
#
# DELETE /load_balancers/{id}
export def "load-balancers delete" [
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
  let full_url = (build-url $base $"/load_balancers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Load Balancer
#
# GET /load_balancers/{id}
export def "load-balancers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Load Balancer
#
# PUT /load_balancers/{id}
export def "load-balancers put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New Load Balancer name (e.g. new-name)
]: any -> record<load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Load Balancer
#
# GET /load_balancers/{id}/actions
export def "load-balancers-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/load_balancers/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Service
#
# POST /load_balancers/{id}/actions/add_service
# --health_check shape: {http?: record, interval: int, port: int, protocol: "tcp"|"http", retries: int, timeout: int}
# --http shape: {certificates?: list, cookie_lifetime?: int, cookie_name?: string, redirect_http?: bool, sticky_sessions?: bool}
export def "load-balancers-actions-add-service post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination_port: int # Port the Load Balancer will balance to (e.g. 80)
  health_check: record # Service health check — shape: {http?: record, interval: int, port: int, protocol: "tcp"|"http", retries: int, timeout: int}
  --http: record # Configuration option for protocols http and https — shape: {certificates?: list, cookie_lifetime?: int, cookie_name?: string, redirect_http?: bool, sticky_sessions?: bool}
  listen_port: int # Port the Load Balancer listens on (e.g. 443)
  protocol: string@protocol-completer # Protocol of the Load Balancer (e.g. https)
  --proxyprotocol: oneof<nothing, bool> # Is Proxyprotocol enabled or not (e.g. false)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/add_service")
  let body = {destination_port: $destination_port, health_check: $health_check, http: $http, listen_port: $listen_port, protocol: $protocol, proxyprotocol: $proxyprotocol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Target
#
# POST /load_balancers/{id}/actions/add_target
# --ip shape: {ip: string}
# --label_selector shape: {selector: string}
# --server shape: {id: float}
export def "load-balancers-actions-add-target post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: record # IP targets where the traffic should be routed through. It is only possible to use the (Public or vSwitch) IPs of Hetzner Online Root Servers belonging to the project owner. IPs belonging to other users are blocked. Additionally IPs belonging to services provided by Hetzner Cloud (Servers, Load Balancers, ...) are blocked as well. — shape: {ip: string}
  --label-selector: record # Configuration for label selector targets, required if type is `label_selector` — shape: {selector: string}
  --server: record # Configuration for type Server, required if type is `server` — shape: {id: float}
  type: string@type-completer-4 # Type of the resource
  --use-private-ip: oneof<nothing, bool> # Use the private network IP instead of the public IP of the Server, requires the Server and Load Balancer to be in the same network. Default value is false. (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/add_target")
  let body = {ip: $ip, label_selector: $label_selector, server: $server, type: $type, use_private_ip: $use_private_ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach a Load Balancer to a Network
#
# POST /load_balancers/{id}/actions/attach_to_network
export def "load-balancers-actions-attach-to-network post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # IP to request to be assigned to this Load Balancer; if you do not provide this then you will be auto assigned an IP address (e.g. 10.0.1.1)
  network: float # ID of an existing network to attach the Load Balancer to (e.g. 4711)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/attach_to_network")
  let body = {ip: $ip, network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Algorithm
#
# POST /load_balancers/{id}/actions/change_algorithm
export def "load-balancers-actions-change-algorithm post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-5 # Algorithm of the Load Balancer
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/change_algorithm")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change reverse DNS entry for this Load Balancer
#
# POST /load_balancers/{id}/actions/change_dns_ptr
export def "load-balancers-actions-change-dns-ptr post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry (nullable, e.g. lb1.example.com)
  ip: string # Public IP address for which the reverse DNS entry should be set (e.g. 1.2.3.4)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/change_dns_ptr")
  let body = {dns_ptr: $dns_ptr, ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Load Balancer Protection
#
# POST /load_balancers/{id}/actions/change_protection
export def "load-balancers-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the Load Balancer from being deleted (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/change_protection")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change the Type of a Load Balancer
#
# POST /load_balancers/{id}/actions/change_type
export def "load-balancers-actions-change-type post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  load_balancer_type: string # ID or name of Load Balancer type the Load Balancer should migrate to (e.g. lb21)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/change_type")
  let body = {load_balancer_type: $load_balancer_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Service
#
# POST /load_balancers/{id}/actions/delete_service
export def "load-balancers-actions-delete-service post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  listen_port: float # The listen port of the service you want to delete (e.g. 4711)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/delete_service")
  let body = {listen_port: $listen_port} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detach a Load Balancer from a Network
#
# POST /load_balancers/{id}/actions/detach_from_network
export def "load-balancers-actions-detach-from-network post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  network: float # ID of an existing network to detach the Load Balancer from (e.g. 4711)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/detach_from_network")
  let body = {network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable the public interface of a Load Balancer
#
# POST /load_balancers/{id}/actions/disable_public_interface
export def "load-balancers-actions-disable-public-interface post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/disable_public_interface")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable the public interface of a Load Balancer
#
# POST /load_balancers/{id}/actions/enable_public_interface
export def "load-balancers-actions-enable-public-interface post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/enable_public_interface")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Target
#
# POST /load_balancers/{id}/actions/remove_target
# --ip shape: {ip: string}
# --label_selector shape: {selector: string}
# --server shape: {id: float}
export def "load-balancers-actions-remove-target post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: record # IP targets where the traffic should be routed through. It is only possible to use the (Public or vSwitch) IPs of Hetzner Online Root Servers belonging to the project owner. IPs belonging to other users are blocked. Additionally IPs belonging to services provided by Hetzner Cloud (Servers, Load Balancers, ...) are blocked as well. — shape: {ip: string}
  --label-selector: record # Configuration for label selector targets, required if type is `label_selector` — shape: {selector: string}
  --server: record # Configuration for type Server, required if type is `server` — shape: {id: float}
  type: string@type-completer-4 # Type of the resource
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/remove_target")
  let body = {ip: $ip, label_selector: $label_selector, server: $server, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Service
#
# POST /load_balancers/{id}/actions/update_service
# --health_check shape: {http?: record, interval: int, port: int, protocol: "tcp"|"http", retries: int, timeout: int}
# --http shape: {certificates?: list, cookie_lifetime?: int, cookie_name?: string, redirect_http?: bool, sticky_sessions?: bool}
export def "load-balancers-actions-update-service post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination_port: int # Port the Load Balancer will balance to (e.g. 80)
  health_check: record # Service health check — shape: {http?: record, interval: int, port: int, protocol: "tcp"|"http", retries: int, timeout: int}
  --http: record # Configuration option for protocols http and https — shape: {certificates?: list, cookie_lifetime?: int, cookie_name?: string, redirect_http?: bool, sticky_sessions?: bool}
  listen_port: int # Port the Load Balancer listens on (e.g. 443)
  protocol: string@protocol-completer # Protocol of the Load Balancer (e.g. https)
  --proxyprotocol: oneof<nothing, bool> # Is Proxyprotocol enabled or not (e.g. false)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/update_service")
  let body = {destination_port: $destination_port, health_check: $health_check, http: $http, listen_port: $listen_port, protocol: $protocol, proxyprotocol: $proxyprotocol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Action for a Load Balancer
#
# GET /load_balancers/{id}/actions/{action_id}
export def "load-balancers-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load_balancers/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Metrics for a LoadBalancer
#
# GET /load_balancers/{id}/metrics
export def "load-balancers-metrics get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-6 # Type of metrics to get
  --start: string # Start of period to get Metrics for (in ISO-8601 format)
  --end: string # End of period to get Metrics for (in ISO-8601 format)
  --step: string # Resolution of results in seconds
]: nothing -> record<metrics: record<end: string, start: string, step: float, time_series: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/load_balancers/($id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Locations
#
# GET /locations
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter Locations by their name. The response will only contain the Location matching the specified name.
]: nothing -> record<locations: table<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Location
#
# GET /locations/{id}
export def "locations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/locations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Networks
#
# GET /networks
export def "networks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter networks by their name. The response will only contain the networks matching the specified name.
  --label-selector: string # Can be used to filter networks by labels. The response will only contain networks with a matching label selector pattern.
]: nothing -> record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, networks: table<created: string, id: int, ip_range: string, labels: record, load_balancers: list, name: string, protection: record, routes: list, servers: list, subnets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Network
#
# POST /networks
# --labels shape: {labelkey?: string}
# --routes item shape: {destination: string, gateway: string}
# --subnets item shape: {ip_range?: string, network_zone: string, type: "cloud"|"server"|"vswitch"}
export def "networks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ip_range: string # IP range of the whole network which must span all included subnets. Must be one of the private IPv4 ranges of RFC1918. Minimum network size is /24. We highly recommend that you pick a larger network with a /16 netmask. (e.g. 10.0.0.0/16)
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  name: string # Name of the network (e.g. mynet)
  --routes: list # Array of routes set in this network. The destination of the route must be one of the private IPv4 ranges of RFC1918. The gateway must be a subnet/IP of the ip_range of the network object. The destination must not overlap with an existing ip_range in any subnets or with any destinations in other routes or with the first IP of the networks ip_range or with 172.31.1.1. The gateway cannot be the first IP of the networks ip_range and also cannot be 172.31.1.1. — item shape: {destination: string, gateway: string}
  --subnets: list # Array of subnets allocated. — item shape: {ip_range?: string, network_zone: string, type: "cloud"|"server"|"vswitch"}
]: any -> record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networks")
  let body = {ip_range: $ip_range, labels: $labels, name: $name, routes: $routes, subnets: $subnets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Network
#
# DELETE /networks/{id}
export def "networks delete" [
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
  let full_url = (build-url $base $"/networks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Network
#
# GET /networks/{id}
export def "networks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Network
#
# PUT /networks/{id}
# --labels shape: {labelkey?: string}
export def "networks put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  --name: string # New network name (e.g. new-name)
]: any -> record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Network
#
# GET /networks/{id}/actions
export def "networks-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a route to a Network
#
# POST /networks/{id}/actions/add_route
export def "networks-actions-add-route post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination: string # Destination network or host of this route. Must not overlap with an existing ip_range in any subnets or with any destinations in other routes or with the first IP of the networks ip_range or with 172.31.1.1. Must be one of the private IPv4 ranges of RFC1918. (e.g. 10.100.1.0/24)
  gateway: string # Gateway for the route. Cannot be the first IP of the networks ip_range, an IP behind a vSwitch or 172.31.1.1, as this IP is being used as a gateway for the public network interface of Servers. (e.g. 10.0.1.1)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/add_route")
  let body = {destination: $destination, gateway: $gateway} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a subnet to a Network
#
# POST /networks/{id}/actions/add_subnet
export def "networks-actions-add-subnet post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip-range: string # Range to allocate IPs from. Must be a Subnet of the ip_range of the parent network object and must not overlap with any other subnets or with any destinations in routes. If the Subnet is of type vSwitch, it also can not overlap with any gateway in routes. Minimum Network size is /30. We suggest that you pick a bigger Network with a /24 netmask. (e.g. 10.0.1.0/24)
  network_zone: string # Name of Network zone. The Location object contains the `network_zone` property each Location belongs to. (e.g. eu-central)
  type: string@type-completer-7 # Type of Subnetwork
  --vswitch-id: int # ID of the robot vSwitch. Must be supplied if the subnet is of type vswitch. (e.g. 1000)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/add_subnet")
  let body = {ip_range: $ip_range, network_zone: $network_zone, type: $type, vswitch_id: $vswitch_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change IP range of a Network
#
# POST /networks/{id}/actions/change_ip_range
export def "networks-actions-change-ip-range post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ip_range: string # The new prefix for the whole Network (e.g. 10.0.0.0/12)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/change_ip_range")
  let body = {ip_range: $ip_range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Network Protection
#
# POST /networks/{id}/actions/change_protection
export def "networks-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the Network from being deleted (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/change_protection")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a route from a Network
#
# POST /networks/{id}/actions/delete_route
export def "networks-actions-delete-route post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination: string # Destination network or host of this route. Must not overlap with an existing ip_range in any subnets or with any destinations in other routes or with the first IP of the networks ip_range or with 172.31.1.1. Must be one of the private IPv4 ranges of RFC1918. (e.g. 10.100.1.0/24)
  gateway: string # Gateway for the route. Cannot be the first IP of the networks ip_range, an IP behind a vSwitch or 172.31.1.1, as this IP is being used as a gateway for the public network interface of Servers. (e.g. 10.0.1.1)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/delete_route")
  let body = {destination: $destination, gateway: $gateway} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a subnet from a Network
#
# POST /networks/{id}/actions/delete_subnet
export def "networks-actions-delete-subnet post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ip_range: string # IP range of subnet to delete (e.g. 10.0.1.0/24)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/delete_subnet")
  let body = {ip_range: $ip_range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Action for a Network
#
# GET /networks/{id}/actions/{action_id}
export def "networks-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all PlacementGroups
#
# GET /placement_groups
export def "placement-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --type: string@type-completer-8 # Can be used multiple times. The response will only contain PlacementGroups matching the type.
]: nothing -> record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, placement_groups: table<created: string, id: int, labels: record, name: string, servers: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/placement_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a PlacementGroup
#
# POST /placement_groups
export def "placement-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the PlacementGroup (e.g. my Placement Group)
  type: string@type-completer-8 # Define the Placement Group Type. (e.g. spread)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/placement_groups")
  let body = {labels: $labels, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a PlacementGroup
#
# DELETE /placement_groups/{id}
export def "placement-groups delete" [
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
  let full_url = (build-url $base $"/placement_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a PlacementGroup
#
# GET /placement_groups/{id}
export def "placement-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/placement_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a PlacementGroup
#
# PUT /placement_groups/{id}
export def "placement-groups put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New PlacementGroup name (e.g. my Placement Group)
]: any -> record<placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/placement_groups/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all prices
#
# GET /pricing
export def "pricing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pricing: record<currency: string, floating_ip: record<price_monthly: record>, floating_ips: list<record>, image: record<price_per_gb_month: record>, load_balancer_types: list<record>, primary_ips: list<record>, server_backup: record<percentage: string>, server_types: list<record>, traffic: record<price_per_tb: record>, vat_rate: string, volume: record<price_per_gb_month: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pricing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Primary IPs
#
# GET /primary_ips
export def "primary-ips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --ip: string # Can be used to filter resources by their ip. The response will only contain the resources matching the specified ip. (e.g. 127.0.0.1)
  --qp-sort: string@sort-completer-2 # Can be used multiple times. Choices id id:asc id:desc created created:asc created:desc
]: nothing -> record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, primary_ips: table<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record, dns_ptr: list, id: int, ip: string, labels: record, name: string, protection: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar") (serialize-qp "ip" $ip "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/primary_ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Primary IP
#
# POST /primary_ips
export def "primary-ips post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assignee-id: int # ID of the resource the Primary IP should be assigned to. Omitted if it should not be assigned. (e.g. 17)
  assignee_type: string@assignee-type-completer # Resource type the Primary IP can be assigned to (e.g. server)
  --auto-delete: oneof<nothing, bool> # Delete the Primary IP when the Server it is assigned to is deleted. If omitted defaults to `false`. (e.g. false)
  --datacenter: string # ID or name of Datacenter the Primary IP will be bound to. Needs to be omitted if `assignee_id` is passed. (e.g. fsn1-dc8)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  name: string # e.g. my-ip
  type: string@type-completer-1 # Primary IP type
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/primary_ips")
  let body = {assignee_id: $assignee_id, assignee_type: $assignee_type, auto_delete: $auto_delete, datacenter: $datacenter, labels: $labels, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Primary IP
#
# DELETE /primary_ips/{id}
export def "primary-ips delete" [
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
  let full_url = (build-url $base $"/primary_ips/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Primary IP
#
# GET /primary_ips/{id}
export def "primary-ips get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/primary_ips/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Primary IP
#
# PUT /primary_ips/{id}
export def "primary-ips put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-delete: oneof<nothing, bool> # Delete this Primary IP when the resource it is assigned to is deleted (e.g. true)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New unique name to set (e.g. my-ip)
]: any -> record<primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/primary_ips/($id)")
  let body = {auto_delete: $auto_delete, labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a Primary IP to a resource
#
# POST /primary_ips/{id}/actions/assign
export def "primary-ips-actions-assign post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  assignee_id: int # ID of a resource of type `assignee_type` (e.g. 4711)
  assignee_type: string@assignee-type-completer # Type of resource assigning the Primary IP to (e.g. server)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/primary_ips/($id)/actions/assign")
  let body = {assignee_id: $assignee_id, assignee_type: $assignee_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change reverse DNS entry for a Primary IP
#
# POST /primary_ips/{id}/actions/change_dns_ptr
export def "primary-ips-actions-change-dns-ptr post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry, will reset to original default value if `null` (nullable, e.g. server02.example.com)
  ip: string # IP address for which to set the reverse DNS entry (e.g. 1.2.3.4)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/primary_ips/($id)/actions/change_dns_ptr")
  let body = {dns_ptr: $dns_ptr, ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Primary IP Protection
#
# POST /primary_ips/{id}/actions/change_protection
export def "primary-ips-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the Primary IP from being deleted (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/primary_ips/($id)/actions/change_protection")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a Primary IP from a resource
#
# POST /primary_ips/{id}/actions/unassign
export def "primary-ips-actions-unassign post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/primary_ips/($id)/actions/unassign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Server Types
#
# GET /server_types
export def "server-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter Server types by their name. The response will only contain the Server type matching the specified name.
]: nothing -> record<server_types: table<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: float, memory: float, name: string, prices: list, storage_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/server_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Server Type
#
# GET /server_types/{id}
export def "server-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: float, memory: float, name: string, prices: list<record>, storage_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/server_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Servers
#
# GET /servers
export def "servers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --status: string@status-completer-2 # Can be used multiple times. The response will only contain Server matching the status
]: nothing -> record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, servers: table<backup_window: string, created: string, datacenter: record, id: int, image: record, included_traffic: float, ingoing_traffic: float, iso: record, labels: record, load_balancers: list, locked: bool, name: string, outgoing_traffic: float, placement_group: record, primary_disk_size: float, private_net: list, protection: record, public_net: record, rescue_enabled: bool, server_type: record, status: string, volumes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Server
#
# POST /servers
# --firewalls item shape: {firewall?: int}
# --public_net shape: {enable_ipv4?: bool, enable_ipv6?: bool, ipv4?: int, ipv6?: int}
export def "servers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automount: oneof<nothing, bool> # Auto-mount Volumes after attach (e.g. false)
  --datacenter: string # ID or name of Datacenter to create Server in (must not be used together with location) (e.g. nbg1-dc3)
  --firewalls: list # Firewalls which should be applied on the Server's public network interface at creation time (e.g. [{firewall: 38}]) — item shape: {firewall?: int}
  image: string # ID or name of the Image the Server is created from (e.g. ubuntu-20.04)
  --labels: record # User-defined labels (key-value pairs)
  --location: string # ID or name of Location to create Server in (must not be used together with datacenter) (e.g. nbg1)
  name: string # Name of the Server to create (must be unique per Project and a valid hostname as per RFC 1123) (e.g. my-server)
  --networks: list # Network IDs which should be attached to the Server private network interface at the creation time (e.g. [456])
  --placement-group: int # ID of the Placement Group the server should be in (e.g. 1)
  --public-net: record # Public Network options — shape: {enable_ipv4?: bool, enable_ipv6?: bool, ipv4?: int, ipv6?: int}
  server_type: string # ID or name of the Server type this Server should be created with (e.g. cx11)
  --ssh-keys: list # SSH key IDs (`integer`) or names (`string`) which should be injected into the Server at creation time (e.g. [my-ssh-key])
  --start-after-create: oneof<nothing, bool> # Start Server right after creation. Defaults to true. (e.g. true)
  --user-data: string # Cloud-Init user data to use during Server creation. This field is limited to 32KiB. (e.g. #cloud-config runcmd: - [touch, /root/cloud-init-worked] )
  --volumes: list # Volume IDs which should be attached to the Server at the creation time. Volumes must be in the same Location. (e.g. [123])
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, next_actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, root_password: string, server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servers")
  let body = {automount: $automount, datacenter: $datacenter, firewalls: $firewalls, image: $image, labels: $labels, location: $location, name: $name, networks: $networks, placement_group: $placement_group, public_net: $public_net, server_type: $server_type, ssh_keys: $ssh_keys, start_after_create: $start_after_create, user_data: $user_data, volumes: $volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Server
#
# DELETE /servers/{id}
export def "servers delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Server
#
# GET /servers/{id}
export def "servers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Server
#
# PUT /servers/{id}
export def "servers put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New name to set (e.g. my-server)
]: any -> record<server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Server
#
# GET /servers/{id}/actions
export def "servers-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a Server to a Placement Group
#
# POST /servers/{id}/actions/add_to_placement_group
export def "servers-actions-add-to-placement-group post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  placement_group: int # ID of Placement Group the Server should be added to (e.g. 1)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/add_to_placement_group")
  let body = {placement_group: $placement_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach an ISO to a Server
#
# POST /servers/{id}/actions/attach_iso
export def "servers-actions-attach-iso post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  iso: string # ID or name of ISO to attach to the Server as listed in GET `/isos` (e.g. FreeBSD-11.0-RELEASE-amd64-dvd1)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/attach_iso")
  let body = {iso: $iso} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach a Server to a Network
#
# POST /servers/{id}/actions/attach_to_network
export def "servers-actions-attach-to-network post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alias-ips: list # Additional IPs to be assigned to this Server (e.g. [10.0.1.2])
  --ip: string # IP to request to be assigned to this Server; if you do not provide this then you will be auto assigned an IP address (e.g. 10.0.1.1)
  network: int # ID of an existing network to attach the Server to (e.g. 4711)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/attach_to_network")
  let body = {alias_ips: $alias_ips, ip: $ip, network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change alias IPs of a Network
#
# POST /servers/{id}/actions/change_alias_ips
export def "servers-actions-change-alias-ips post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alias_ips: list # New alias IPs to set for this Server (e.g. [10.0.1.2])
  network: int # ID of an existing Network already attached to the Server (e.g. 4711)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/change_alias_ips")
  let body = {alias_ips: $alias_ips, network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change reverse DNS entry for this Server
#
# POST /servers/{id}/actions/change_dns_ptr
export def "servers-actions-change-dns-ptr post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry, reset to original value if `null` (nullable, e.g. server01.example.com)
  ip: string # Primary IP address for which the reverse DNS entry should be set (e.g. 1.2.3.4)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/change_dns_ptr")
  let body = {dns_ptr: $dns_ptr, ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Server Protection
#
# POST /servers/{id}/actions/change_protection
export def "servers-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the Server from being deleted (currently delete and rebuild attribute needs to have the same value) (e.g. true)
  --rebuild: oneof<nothing, bool> # If true, prevents the Server from being rebuilt (currently delete and rebuild attribute needs to have the same value) (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/change_protection")
  let body = {delete: $delete, rebuild: $rebuild} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change the Type of a Server
#
# POST /servers/{id}/actions/change_type
export def "servers-actions-change-type post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  server_type: string # ID or name of Server type the Server should migrate to (e.g. cx11)
  --upgrade-disk: oneof<nothing, bool> # If false, do not upgrade the disk (this allows downgrading the Server type later) (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/change_type")
  let body = {server_type: $server_type, upgrade_disk: $upgrade_disk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Image from a Server
#
# POST /servers/{id}/actions/create_image
# --labels shape: {labelkey?: string}
export def "servers-actions-create-image post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the Image, will be auto-generated if not set (e.g. my image)
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  --type: string@type-completer-9 # Type of Image to create (default: `snapshot`) (e.g. snapshot)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/create_image")
  let body = {description: $description, labels: $labels, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detach a Server from a Network
#
# POST /servers/{id}/actions/detach_from_network
export def "servers-actions-detach-from-network post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  network: int # ID of an existing network to detach the Server from (e.g. 4711)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/detach_from_network")
  let body = {network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detach an ISO from a Server
#
# POST /servers/{id}/actions/detach_iso
export def "servers-actions-detach-iso post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/detach_iso")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Backups for a Server
#
# POST /servers/{id}/actions/disable_backup
export def "servers-actions-disable-backup post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/disable_backup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Rescue Mode for a Server
#
# POST /servers/{id}/actions/disable_rescue
export def "servers-actions-disable-rescue post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/disable_rescue")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable and Configure Backups for a Server
#
# POST /servers/{id}/actions/enable_backup
export def "servers-actions-enable-backup post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/enable_backup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Rescue Mode for a Server
#
# POST /servers/{id}/actions/enable_rescue
export def "servers-actions-enable-rescue post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ssh-keys: list # Array of SSH key IDs which should be injected into the rescue system. (e.g. [2323])
  --type: string@type-completer-10 # Type of rescue system to boot (default: `linux64`)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/enable_rescue")
  let body = {ssh_keys: $ssh_keys, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Power off a Server
#
# POST /servers/{id}/actions/poweroff
export def "servers-actions-poweroff post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/poweroff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Power on a Server
#
# POST /servers/{id}/actions/poweron
export def "servers-actions-poweron post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/poweron")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Soft-reboot a Server
#
# POST /servers/{id}/actions/reboot
export def "servers-actions-reboot post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/reboot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rebuild a Server from an Image
#
# POST /servers/{id}/actions/rebuild
export def "servers-actions-rebuild post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  image: string # ID or name of Image to rebuilt from. (e.g. ubuntu-20.04)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/rebuild")
  let body = {image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove from Placement Group
#
# POST /servers/{id}/actions/remove_from_placement_group
export def "servers-actions-remove-from-placement-group post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/remove_from_placement_group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Console for a Server
#
# POST /servers/{id}/actions/request_console
export def "servers-actions-request-console post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, password: string, wss_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/request_console")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset a Server
#
# POST /servers/{id}/actions/reset
export def "servers-actions-reset post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset root Password of a Server
#
# POST /servers/{id}/actions/reset_password
export def "servers-actions-reset-password post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/reset_password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shutdown a Server
#
# POST /servers/{id}/actions/shutdown
export def "servers-actions-shutdown post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Action for a Server
#
# GET /servers/{id}/actions/{action_id}
export def "servers-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/servers/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Metrics for a Server
#
# GET /servers/{id}/metrics
export def "servers-metrics get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-11 # Type of metrics to get
  --start: string # Start of period to get Metrics for (in ISO-8601 format)
  --end: string # End of period to get Metrics for (in ISO-8601 format)
  --step: string # Resolution of results in seconds
]: nothing -> record<metrics: record<end: string, start: string, step: float, time_series: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/servers/($id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all SSH keys
#
# GET /ssh_keys
export def "ssh-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-3 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --fingerprint: string # Can be used to filter SSH keys by their fingerprint. The response will only contain the SSH key matching the specified fingerprint.
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, ssh_keys: table<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "label_selector" $label_selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ssh_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an SSH key
#
# POST /ssh_keys
export def "ssh-keys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the SSH key (e.g. My ssh key)
  public_key: string # Public key (e.g. ssh-rsa AAAjjk76kgf...Xt)
]: any -> record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssh_keys")
  let body = {labels: $labels, name: $name, public_key: $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SSH key
#
# DELETE /ssh_keys/{id}
export def "ssh-keys delete" [
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
  let full_url = (build-url $base $"/ssh_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a SSH key
#
# GET /ssh_keys/{id}
export def "ssh-keys get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ssh_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SSH key
#
# PUT /ssh_keys/{id}
export def "ssh-keys put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New name Name to set (e.g. My ssh key)
]: any -> record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ssh_keys/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Volumes
#
# GET /volumes
export def "volumes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Can be used multiple times. The response will only contain Volumes matching the status.
  --qp-sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, volumes: table<created: string, format: string, id: int, labels: record, linux_device: string, location: record, name: string, protection: record, server: int, size: float, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "label_selector" $label_selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Volume
#
# POST /volumes
export def "volumes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automount: oneof<nothing, bool> # Auto-mount Volume after attach. `server` must be provided. (e.g. false)
  --format: string # Format Volume after creation. One of: `xfs`, `ext4` (e.g. xfs)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --location: string # Location to create the Volume in (can be omitted if Server is specified) (e.g. nbg1)
  name: string # Name of the volume (e.g. databases-storage)
  --server: int # Server to which to attach the Volume once it's created (Volume will be created in the same Location as the server)
  size: int # Size of the Volume in GB (e.g. 42)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, next_actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes")
  let body = {automount: $automount, format: $format, labels: $labels, location: $location, name: $name, server: $server, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Volume
#
# DELETE /volumes/{id}
export def "volumes delete" [
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
  let full_url = (build-url $base $"/volumes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Volume
#
# GET /volumes/{id}
export def "volumes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Volume
#
# PUT /volumes/{id}
# --labels shape: {labelkey?: string}
export def "volumes put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  name: string # New Volume name (e.g. database-storage)
]: any -> record<volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)")
  let body = {labels: $labels, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Actions for a Volume
#
# GET /volumes/{id}/actions
export def "volumes-actions list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volumes/($id)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach Volume to a Server
#
# POST /volumes/{id}/actions/attach
export def "volumes-actions-attach post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --automount: oneof<nothing, bool> # Auto-mount the Volume after attaching it (e.g. false)
  server: int # ID of the Server the Volume will be attached to (e.g. 43)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)/actions/attach")
  let body = {automount: $automount, server: $server} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Volume Protection
#
# POST /volumes/{id}/actions/change_protection
export def "volumes-actions-change-protection post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: oneof<nothing, bool> # If true, prevents the Volume from being deleted (e.g. true)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)/actions/change_protection")
  let body = {delete: $delete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detach Volume
#
# POST /volumes/{id}/actions/detach
export def "volumes-actions-detach post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)/actions/detach")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resize Volume
#
# POST /volumes/{id}/actions/resize
export def "volumes-actions-resize post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  size: float # New Volume size in GB (must be greater than current size) (e.g. 50)
]: any -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)/actions/resize")
  let body = {size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Action for a Volume
#
# GET /volumes/{id}/actions/{action_id}
export def "volumes-actions get" [
  id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($id)/actions/($action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
