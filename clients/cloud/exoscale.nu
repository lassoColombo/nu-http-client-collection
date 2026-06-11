# Auto-generated client for Exoscale API v2.0.0
# Source: https://openapi-v2.exoscale.com/source.json
# Auth: --token flag or $env.EXOSCALE_API_TOKEN

const BASE_URL = "https://api-ch-gva-2.exoscale.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EXOSCALE_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api-ch-gva-2.exoscale.com/v2" "https://api-ch-dk-2.exoscale.com/v2" "https://api-de-fra-1.exoscale.com/v2" "https://api-de-muc-1.exoscale.com/v2" "https://api-at-vie-1.exoscale.com/v2" "https://api-at-vie-2.exoscale.com/v2" "https://api-bg-sof-1.exoscale.com/v2" "https://api-hr-zag-1.exoscale.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def protocol-completer [] { ["tcp" "udp"] }
def strategy-completer [] { ["maglev-hash" "round-robin" "source-hash"] }
def target-version-completer [] { ["13" "14" "15" "16" "17" "18"] }
def authentication-completer [] { ["caching_sha2_password" "mysql_native_password"] }
def visibility-completer [] { ["private" "public"] }
def mode-completer [] { ["session" "statement" "transaction"] }
def addressfamily-completer [] { ["inet4" "inet6"] }
def public-ip-assignment-completer [] { ["dual" "inet4" "none"] }
def type-completer [] { ["A" "AAAA" "ALIAS" "CAA" "CNAME" "HINFO" "MX" "NAPTR" "NS" "POOL" "SRV" "SSHFP" "TXT" "URL"] }
def inference-engine-version-completer [] { ["0.12.0" "0.15.1" "0.16.0" "0.17.0" "0.18.0" "0.18.1" "0.19.0" "0.19.1" "0.20.0" "0.20.1" "0.20.2" "0.21.0" "0.22.0" "0.22.1"] }
def permission-completer [] { ["schema_registry_read" "schema_registry_write"] }
def public-ip-assignment-completer-1 [] { ["dual" "inet4"] }
def rescue-profile-completer [] { ["netboot" "netboot-efi"] }
def flow-direction-completer [] { ["egress" "ingress"] }
def protocol-completer-1 [] { ["ah" "esp" "gre" "icmp" "icmpv6" "ipip" "tcp" "udp"] }
def permission-completer-1 [] { ["admin" "read" "readwrite" "write"] }
def default-service-strategy-completer [] { ["allow" "deny"] }
def sort-order-completer [] { ["asc" "desc"] }
def period-completer [] { ["day" "hour" "month" "week" "year"] }
def method-completer [] { ["dump" "replication"] }
def cni-completer [] { ["calico" "cilium"] }
def level-completer [] { ["pro" "starter"] }
def usage-completer [] { ["encrypt-decrypt"] }
def boot-mode-completer [] { ["legacy" "uefi"] }
def type-completer-1 [] { ["datadog" "elasticsearch" "opensearch" "prometheus" "rsyslog"] }
def variant-completer [] { ["aiven" "timescale"] }
def synchronous-replication-completer [] { ["off" "quorum"] }
def version-completer [] { ["13" "14" "15" "16" "17" "18"] }
def integration-type-completer [] { ["datasource" "logs" "metrics"] }
def manager-type-completer [] { ["instance-pool"] }
def key-spec-completer [] { ["AES-256"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "load-balancer-service delete-load-balancer-service" } } | get name | first)
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

# Delete a Load Balancer Service
#
# DELETE /load-balancer/{id}/service/{service-id}
# operationId: delete-load-balancer-service
export def "load-balancer-service delete-load-balancer-service" [
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)/service/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Load Balancer Service
#
# PUT /load-balancer/{id}/service/{service-id}
# operationId: update-load-balancer-service
# --healthcheck shape: {mode?: "tcp"|"http"|"https", interval?: int, uri?: string, port?: int, timeout?: int, retries?: int, tls-sni?: string}
export def "load-balancer-service update-load-balancer-service" [
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Load Balancer Service name
  --description: string # Load Balancer Service description
  --protocol: string@protocol-completer # Network traffic protocol
  --strategy: string@strategy-completer # Load balancing strategy
  --port: int # Port exposed on the Load Balancer's public IP (format: int64)
  --target-port: int # Port on which the network traffic will be forwarded to on the receiving instance (format: int64)
  --healthcheck: record # Load Balancer Service healthcheck — shape: {mode?: "tcp"|"http"|"https", interval?: int, uri?: string, port?: int, timeout?: int, retries?: int, tls-sni?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)/service/($service_id)")
  let body = {name: $name, description: $description, protocol: $protocol, strategy: $strategy, port: $port, target-port: $target_port, healthcheck: $healthcheck} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Load Balancer Service details
#
# GET /load-balancer/{id}/service/{service-id}
# operationId: get-load-balancer-service
export def "load-balancer-service get-load-balancer-service" [
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, protocol: string, name: string, state: string, target_port: int, port: int, instance_pool: record<application_consistent_snapshot_enabled: bool, anti_affinity_groups: list<record>, description: string, public_ip_assignment: string, labels: record, security_groups: list<record>, elastic_ips: list<record>, name: string, instance_type: record<id: string>, min_available: int, private_networks: list<record>, template: record<id: string>, state: string, size: int, ssh_key: record<name: string>, instance_prefix: string, user_data: string, manager: record<id: string, type: string>, instances: list<record>, deploy_target: record<id: string>, ipv6_enabled: bool, id: string, disk_size: int, ssh_keys: list<record>>, strategy: string, healthcheck: record<mode: string, interval: int, uri: string, port: int, timeout: int, retries: int, tls_sni: string>, id: string, healthcheck_status: table<public_ip: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)/service/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Delete OpenSearch logs external integration endpoint
#
# DELETE /dbaas-external-endpoint-opensearch/{endpoint-id}
# operationId: delete-dbaas-external-endpoint-opensearch
export def "dbaas-external-endpoint-opensearch delete-dbaas-external-endpoint-opensearch" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-opensearch/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get OpenSearch Logs external integration endpoint settings
#
# GET /dbaas-external-endpoint-opensearch/{endpoint-id}
# operationId: get-dbaas-external-endpoint-opensearch
export def "dbaas-external-endpoint-opensearch get-dbaas-external-endpoint-opensearch" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, id: string, settings: record<url: string, index_prefix: string, index_days_max: int, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-opensearch/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update OpenSearch Logs external integration endpoint
#
# PUT /dbaas-external-endpoint-opensearch/{endpoint-id}
# operationId: update-dbaas-external-endpoint-opensearch
# --settings shape: {ca?: string, url?: string, index-prefix?: string, index-days-max?: int, timeout?: int}
export def "dbaas-external-endpoint-opensearch update-dbaas-external-endpoint-opensearch" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {ca?: string, url?: string, index-prefix?: string, index-days-max?: int, timeout?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-opensearch/($endpoint_id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get DBaaS OpenSearch ACL configuration
#
# GET /dbaas-opensearch/{name}/acl-config
# operationId: get-dbaas-opensearch-acl-config
export def "dbaas-opensearch-acl-config get-dbaas-opensearch-acl-config" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acls: table<rules: list, username: string>, acl_enabled: bool, extended_acl_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)/acl-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS OpenSearch ACL configuration
#
# PUT /dbaas-opensearch/{name}/acl-config
# operationId: update-dbaas-opensearch-acl-config
# --acls item shape: {rules?: list, username?: string}
export def "dbaas-opensearch-acl-config update-dbaas-opensearch-acl-config" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acls: list # List of OpenSearch ACLs — item shape: {rules?: list, username?: string}
  --acl-enabled: string@bool-completer # Enable OpenSearch ACLs. When disabled authenticated service users have unrestricted access.
  --extended-acl-enabled: string@bool-completer # Enable to enforce index rules in a limited fashion for requests that use the _mget, _msearch, and _bulk APIs
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)/acl-config")
  let body = {acls: $acls, acl-enabled: $acl_enabled, extended-acl-enabled: $extended_acl_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Scale an Instance Pool
#
# PUT /instance-pool/{id}:scale
# operationId: scale-instance-pool
export def "instance-pool scale-instance-pool" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  size: int # Number of managed Instances (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-pool/($id):scale")
  let body = {size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Snapshot of a Compute instance
#
# POST /instance/{id}:create-snapshot
# operationId: create-snapshot
export def "instance create-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):create-snapshot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a DBaaS Valkey migration
#
# POST /dbaas-valkey/{name}/migration/stop
# operationId: stop-dbaas-valkey-migration
export def "dbaas-valkey-migration-stop stop-dbaas-valkey-migration" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($name)/migration/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query the PTR DNS records for an elastic IP
#
# GET /reverse-dns/elastic-ip/{id}
# operationId: get-reverse-dns-elastic-ip
export def "reverse-dns-elastic-ip get-reverse-dns-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reverse-dns/elastic-ip/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update/Create the PTR DNS record for an elastic IP
#
# POST /reverse-dns/elastic-ip/{id}
# operationId: update-reverse-dns-elastic-ip
export def "reverse-dns-elastic-ip update-reverse-dns-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain-name: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reverse-dns/elastic-ip/($id)")
  let body = {domain-name: $domain_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the PTR DNS record for an elastic IP
#
# DELETE /reverse-dns/elastic-ip/{id}
# operationId: delete-reverse-dns-elastic-ip
export def "reverse-dns-elastic-ip delete-reverse-dns-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reverse-dns/elastic-ip/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Anti-affinity Groups
#
# GET /anti-affinity-group
# operationId: list-anti-affinity-groups
export def "anti-affinity-group list-anti-affinity-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<anti_affinity_groups: table<id: string, name: string, description: string, instances: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/anti-affinity-group")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Anti-affinity Group
#
# POST /anti-affinity-group
# operationId: create-anti-affinity-group
export def "anti-affinity-group create-anti-affinity-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Anti-affinity Group name
  --description: string # Anti-affinity Group description
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/anti-affinity-group")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve organization usage reports
#
# GET /usage-report
# operationId: get-usage-report
export def "usage-report get-usage-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string
]: nothing -> record<usage: table<from: string, to: string, product: string, variable: string, description: string, quantity: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usage-report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Events
#
# GET /event
# operationId: list-events
export def "event list-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # format: date-time
  --qp-to: string # format: date-time
]: nothing -> table<iam_user: record<sso: bool, two_factor_authentication: bool, email: string, id: string, role: record, pending: bool>, request_id: string, iam_role: record<description: string, labels: record, permissions: list, assume_role_policy: record, editable: bool, name: string, max_session_ttl: int, policy: record, id: string>, zone: string, get_params: record, body_params: record, status: int, source_ip: string, iam_api_key: record<name: string, key: string, role_id: string>, uri: string, elapsed_ms: int, timestamp: string, path_params: record, handler: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Security Group rule
#
# DELETE /security-group/{id}/rules/{rule-id}
# operationId: delete-rule-from-security-group
export def "security-group-rules delete-rule-from-security-group" [
  id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id)/rules/($rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Grafana maintenance update
#
# PUT /dbaas-grafana/{name}/maintenance/start
# operationId: start-dbaas-grafana-maintenance
export def "dbaas-grafana-maintenance-start start-dbaas-grafana-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Disable Key Rotation
#
# POST /kms-key/{id}/disable-key-rotation
# operationId: disable-kms-key-rotation
export def "kms-key-disable-key-rotation disable-kms-key-rotation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rotation: record<manual_count: int, automatic: bool, rotation_period: int, next_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/disable-key-rotation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check whether you can upgrade Postgres service to a newer version
#
# POST /dbaas-postgres/{service}/upgrade-check
# operationId: create-dbaas-pg-upgrade-check
export def "dbaas-postgres-upgrade-check create-dbaas-pg-upgrade-check" [
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  target_version: string@target-version-completer
]: any -> record<id: string, create_time: string, result: string, result_codes: table<code: string, dbname: string>, success: bool, task_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service)/upgrade-check")
  let body = {target-version: $target_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the credentials of a DBaaS mysql user
#
# PUT /dbaas-mysql/{service-name}/user/{username}/password/reset
# operationId: reset-dbaas-mysql-user-password
export def "dbaas-mysql-user-password-reset reset-dbaas-mysql-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
  --authentication: string@authentication-completer
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($service_name)/user/($username)/password/reset")
  let body = {password: $password, authentication: $authentication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get inference-engine Help
#
# GET /ai/help/inference-engine-parameters
# operationId: get-inference-engine-help
export def "ai-help-inference-engine-parameters get-inference-engine-help" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string
]: nothing -> record<parameters: table<description: string, allowed_values: list, default: string, name: string, section: string, type: string, flags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/help/inference-engine-parameters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Load Balancer
#
# POST /load-balancer
# operationId: create-load-balancer
export def "load-balancer create-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Load Balancer description
  name: string # Load Balancer name
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/load-balancer")
  let body = {description: $description, name: $name, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Load Balancers
#
# GET /load-balancer
# operationId: list-load-balancers
export def "load-balancer list-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<load_balancers: table<id: string, description: string, name: string, state: string, created_at: string, ip: string, services: list, labels: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/load-balancer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Security Group
#
# POST /security-group
# operationId: create-security-group
export def "security-group create-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Security Group name
  --description: string # Security Group description
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security-group")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Security Groups.
#
# GET /security-group
# operationId: list-security-groups
export def "security-group list-security-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string@visibility-completer
]: nothing -> record<security_groups: table<id: string, name: string, description: string, external_sources: list, rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/security-group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS PostgreSQL connection pool
#
# POST /dbaas-postgres/{service-name}/connection-pool
# operationId: create-dbaas-pg-connection-pool
export def "dbaas-postgres-connection-pool create-dbaas-pg-connection-pool" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  database_name: string
  --mode: string@mode-completer
  --size: int # format: int64
  --username: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/connection-pool")
  let body = {name: $name, database-name: $database_name, mode: $mode, size: $size, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a DBaaS MySQL service
#
# PUT /dbaas-mysql/{name}
# operationId: update-dbaas-service-mysql
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --mysql-settings shape: {net_write_timeout?: int, internal_tmp_mem_storage_engine?: "TempTable"|"MEMORY", sql_mode?: string, information_schema_stats_expiry?: int, sort_buffer_size?: int, innodb_thread_concurrency?: int, innodb_write_io_threads?: int, innodb_ft_min_token_size?: int, innodb_change_buffer_max_size?: int, innodb_flush_neighbors?: int, tmp_table_size?: int, slow_query_log?: bool, connect_timeout?: int, log_output?: "INSIGHTS"|"INSIGHTS,TABLE"|"NONE"|"TABLE", net_read_timeout?: int, innodb_lock_wait_timeout?: int, wait_timeout?: int, innodb_rollback_on_timeout?: bool, group_concat_max_len?: int, net_buffer_length?: int, innodb_print_all_deadlocks?: bool, innodb_online_alter_log_max_size?: int, interactive_timeout?: int, innodb_log_buffer_size?: int, max_allowed_packet?: int, max_heap_table_size?: int, innodb_ft_server_stopword_table?: string, innodb_read_io_threads?: int, sql_require_primary_key?: bool, default_time_zone?: string, long_query_time?: float}
# --migration shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
# --backup-schedule shape: {backup-hour?: int, backup-minute?: int}
export def "dbaas-mysql update-dbaas-service-mysql" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --plan: string # Subscription plan
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --mysql-settings: record # shape: {net_write_timeout?: int, internal_tmp_mem_storage_engine?: "TempTable"|"MEMORY", sql_mode?: string, information_schema_stats_expiry?: int, sort_buffer_size?: int, innodb_thread_concurrency?: int, innodb_write_io_threads?: int, innodb_ft_min_token_size?: int, innodb_change_buffer_max_size?: int, innodb_flush_neighbors?: int, tmp_table_size?: int, slow_query_log?: bool, connect_timeout?: int, log_output?: "INSIGHTS"|"INSIGHTS,TABLE"|"NONE"|"TABLE", net_read_timeout?: int, innodb_lock_wait_timeout?: int, wait_timeout?: int, innodb_rollback_on_timeout?: bool, group_concat_max_len?: int, net_buffer_length?: int, innodb_print_all_deadlocks?: bool, innodb_online_alter_log_max_size?: int, interactive_timeout?: int, innodb_log_buffer_size?: int, max_allowed_packet?: int, max_heap_table_size?: int, innodb_ft_server_stopword_table?: string, innodb_read_io_threads?: int, sql_require_primary_key?: bool, default_time_zone?: string, long_query_time?: float}
  --migration: record # Migrate data from existing server — shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
  --binlog-retention-period: int # The minimum amount of time in seconds to keep binlog entries before deletion. This may be extended for services that require binlog entries for longer than the default for example if using the MySQL Debezium Kafka connector. (format: int64)
  --backup-schedule: record # shape: {backup-hour?: int, backup-minute?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)")
  let body = {maintenance: $maintenance, plan: $plan, termination-protection: $termination_protection, ip-filter: $ip_filter, mysql-settings: $mysql_settings, migration: $migration, binlog-retention-period: $binlog_retention_period, backup-schedule: $backup_schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a DBaaS MySQL service
#
# GET /dbaas-mysql/{name}
# operationId: get-dbaas-service-mysql
export def "dbaas-mysql get-dbaas-service-mysql" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, node_count: int, connection_info: record<uri: list<string>, params: list<record>, standby: list<string>>, backup_schedule: record<backup_hour: int, backup_minute: int>, node_cpu_count: int, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, type: string, state: string, databases: list<string>, ip_filter: list<string>, backups: table<backup_name: string, backup_time: string, data_size: int>, termination_protection: bool, notifications: table<level: string, message: string, type: string, metadata: record>, components: table<component: string, host: string, port: int, route: string, usage: string>, mysql_settings: record<net_write_timeout: int, internal_tmp_mem_storage_engine: string, sql_mode: string, information_schema_stats_expiry: int, sort_buffer_size: int, innodb_thread_concurrency: int, innodb_write_io_threads: int, innodb_ft_min_token_size: int, innodb_change_buffer_max_size: int, innodb_flush_neighbors: int, tmp_table_size: int, slow_query_log: bool, connect_timeout: int, log_output: string, net_read_timeout: int, innodb_lock_wait_timeout: int, wait_timeout: int, innodb_rollback_on_timeout: bool, group_concat_max_len: int, net_buffer_length: int, innodb_print_all_deadlocks: bool, innodb_online_alter_log_max_size: int, interactive_timeout: int, innodb_log_buffer_size: int, max_allowed_packet: int, max_heap_table_size: int, innodb_ft_server_stopword_table: string, innodb_read_io_threads: int, sql_require_primary_key: bool, default_time_zone: string, long_query_time: float>, maintenance: record<dow: string, time: string, updates: list<record>>, disk_size: int, node_memory: int, uri: string, uri_params: record, version: string, created_at: string, plan: string, users: table<type: string, username: string, password: string, authentication: string>, binlog_retention_period: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS MySQL service
#
# POST /dbaas-mysql/{name}
# operationId: create-dbaas-service-mysql
# --backup-schedule shape: {backup-hour?: int, backup-minute?: int}
# --integrations item shape: {type: "read_replica", source-service?: string, dest-service?: string, settings?: record}
# --mysql-settings shape: {net_write_timeout?: int, internal_tmp_mem_storage_engine?: "TempTable"|"MEMORY", sql_mode?: string, information_schema_stats_expiry?: int, sort_buffer_size?: int, innodb_thread_concurrency?: int, innodb_write_io_threads?: int, innodb_ft_min_token_size?: int, innodb_change_buffer_max_size?: int, innodb_flush_neighbors?: int, tmp_table_size?: int, slow_query_log?: bool, connect_timeout?: int, log_output?: "INSIGHTS"|"INSIGHTS,TABLE"|"NONE"|"TABLE", net_read_timeout?: int, innodb_lock_wait_timeout?: int, wait_timeout?: int, innodb_rollback_on_timeout?: bool, group_concat_max_len?: int, net_buffer_length?: int, innodb_print_all_deadlocks?: bool, innodb_online_alter_log_max_size?: int, interactive_timeout?: int, innodb_log_buffer_size?: int, max_allowed_packet?: int, max_heap_table_size?: int, innodb_ft_server_stopword_table?: string, innodb_read_io_threads?: int, sql_require_primary_key?: bool, default_time_zone?: string, long_query_time?: float}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --migration shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
export def "dbaas-mysql create-dbaas-service-mysql" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backup-schedule: record # shape: {backup-hour?: int, backup-minute?: int}
  --integrations: list # Service integrations to be enabled when creating the service. — item shape: {type: "read_replica", source-service?: string, dest-service?: string, settings?: record}
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --fork-from-service: string
  --recovery-backup-time: string # ISO time of a backup to recover from for services that support arbitrary times
  --mysql-settings: record # shape: {net_write_timeout?: int, internal_tmp_mem_storage_engine?: "TempTable"|"MEMORY", sql_mode?: string, information_schema_stats_expiry?: int, sort_buffer_size?: int, innodb_thread_concurrency?: int, innodb_write_io_threads?: int, innodb_ft_min_token_size?: int, innodb_change_buffer_max_size?: int, innodb_flush_neighbors?: int, tmp_table_size?: int, slow_query_log?: bool, connect_timeout?: int, log_output?: "INSIGHTS"|"INSIGHTS,TABLE"|"NONE"|"TABLE", net_read_timeout?: int, innodb_lock_wait_timeout?: int, wait_timeout?: int, innodb_rollback_on_timeout?: bool, group_concat_max_len?: int, net_buffer_length?: int, innodb_print_all_deadlocks?: bool, innodb_online_alter_log_max_size?: int, interactive_timeout?: int, innodb_log_buffer_size?: int, max_allowed_packet?: int, max_heap_table_size?: int, innodb_ft_server_stopword_table?: string, innodb_read_io_threads?: int, sql_require_primary_key?: bool, default_time_zone?: string, long_query_time?: float}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --admin-username: string # Custom username for admin user. This must be set only when a new service is being created.
  --version: string # MySQL major version
  plan: string # Subscription plan
  --admin-password: string
  --migration: record # Migrate data from existing server — shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
  --binlog-retention-period: int # The minimum amount of time in seconds to keep binlog entries before deletion. This may be extended for services that require binlog entries for longer than the default for example if using the MySQL Debezium Kafka connector. (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)")
  let body = {backup-schedule: $backup_schedule, integrations: $integrations, ip-filter: $ip_filter, termination-protection: $termination_protection, fork-from-service: $fork_from_service, recovery-backup-time: $recovery_backup_time, mysql-settings: $mysql_settings, maintenance: $maintenance, admin-username: $admin_username, version: $version, plan: $plan, admin-password: $admin_password, migration: $migration, binlog-retention-period: $binlog_retention_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a MySQL service
#
# DELETE /dbaas-mysql/{name}
# operationId: delete-dbaas-service-mysql
export def "dbaas-mysql delete-dbaas-service-mysql" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach a Compute instance to a Private Network
#
# PUT /private-network/{id}:attach
# operationId: attach-instance-to-private-network
# --instance shape: {id?: string}
export def "private-network attach-instance-to-private-network" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # Static IP address lease for the corresponding network interface (format: ipv4)
  instance: record # Compute instance — shape: {id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id):attach")
  let body = {ip: $ip, instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Request generation of key/secret that allow caller to assume target role
#
# POST /iam-role/{id}/assume
# operationId: assume-iam-role
export def "iam-role-assume assume-iam-role" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ttl: int # TTL in seconds for the generated access key (cannot exceed the max TTL defined in the targeted assume role) (format: int64)
]: any -> record<key: string, name: string, org_id: string, role_id: string, secret: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/iam-role/($id)/assume")
  let body = {ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get KMS Key
#
# GET /kms-key/{id}
# operationId: get-kms-key
export def "kms-key get-kms-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, rotation: record<manual_count: int, automatic: bool, rotation_period: int, next_at: string>, revision: record<at: string, seq: int>, name: string, multi_zone: bool, source: string, usage: string, replicas_status: table<zone: string, last_applied_watermark: int, last_failure: record>, status: string, status_since: string, id: string, replicas: list<string>, material: record<version: int, created_at: string, automatic: bool>, origin_zone: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Thanos maintenance update
#
# PUT /dbaas-thanos/{name}/maintenance/start
# operationId: start-dbaas-thanos-maintenance
export def "dbaas-thanos-maintenance-start start-dbaas-thanos-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-thanos/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Delete ElasticSearch logs external integration endpoint
#
# DELETE /dbaas-external-endpoint-elasticsearch/{endpoint-id}
# operationId: delete-dbaas-external-endpoint-elasticsearch
export def "dbaas-external-endpoint-elasticsearch delete-dbaas-external-endpoint-elasticsearch" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-elasticsearch/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get ElasticSearch Logs external integration endpoint settings
#
# GET /dbaas-external-endpoint-elasticsearch/{endpoint-id}
# operationId: get-dbaas-external-endpoint-elasticsearch
export def "dbaas-external-endpoint-elasticsearch get-dbaas-external-endpoint-elasticsearch" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, id: string, settings: record<url: string, index_prefix: string, index_days_max: int, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-elasticsearch/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update ElasticSearch Logs external integration endpoint
#
# PUT /dbaas-external-endpoint-elasticsearch/{endpoint-id}
# operationId: update-dbaas-external-endpoint-elasticsearch
# --settings shape: {ca?: string, url?: string, index-prefix?: string, index-days-max?: int, timeout?: int}
export def "dbaas-external-endpoint-elasticsearch update-dbaas-external-endpoint-elasticsearch" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {ca?: string, url?: string, index-prefix?: string, index-days-max?: int, timeout?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-elasticsearch/($endpoint_id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Model
#
# POST /ai/model
# operationId: create-model
export def "ai-model create-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Model name
  --huggingface-token: string # Huggingface Token
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/model")
  let body = {name: $name, huggingface-token: $huggingface_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Models
#
# GET /ai/model
# operationId: list-models
export def "ai-model list-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string
]: nothing -> record<models: table<updated_at: string, name: string, state: string, id: string, model_size: int, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/model" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS MySQL user
#
# POST /dbaas-mysql/{service-name}/user
# operationId: create-dbaas-mysql-user
export def "dbaas-mysql-user create-dbaas-mysql-user" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  --authentication: string@authentication-completer
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($service_name)/user")
  let body = {username: $username, authentication: $authentication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DBaaS Service Types
#
# GET /dbaas-service-type
# operationId: list-dbaas-service-types
export def "dbaas-service-type list-dbaas-service-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dbaas_service_types: table<name: string, available_versions: list, default_version: string, description: string, plans: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-service-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Scale Deployment
#
# POST /ai/deployment/{id}/scale
# operationId: scale-deployment
export def "ai-deployment-scale scale-deployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  replicas: int # Number of replicas (>=0) (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/deployment/($id)/scale")
  let body = {replicas: $replicas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Instance Type details
#
# GET /instance-type/{id}
# operationId: get-instance-type
export def "instance-type get-instance-type" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, size: string, family: string, cpus: int, gpus: int, authorized: bool, memory: int, zones: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-type/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal the password used during instance creation or the latest password reset.
#
# GET /instance/{id}:password
# operationId: reveal-instance-password
export def "instance reveal-instance-password" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the active template for a given kube version and variant (standard | nvidia)
#
# GET /sks-template/{kube-version}/{variant}
# operationId: get-active-nodepool-template
export def "sks-template get-active-nodepool-template" [
  kube_version: string
  variant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_template: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-template/($kube_version)/($variant)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resize a Compute instance disk
#
# PUT /instance/{id}:resize-disk
# operationId: resize-instance-disk
export def "instance resize-instance-disk" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  disk_size: int # Instance disk size in GiB (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):resize-disk")
  let body = {disk-size: $disk_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List DBaaS services
#
# GET /dbaas-service
# operationId: list-dbaas-services
export def "dbaas-service list-dbaas-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dbaas_services: table<updated_at: string, node_count: int, node_cpu_count: int, integrations: list, zone: string, name: string, type: string, state: string, termination_protection: bool, notifications: list, disk_size: int, node_memory: int, created_at: string, plan: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Elastic IP
#
# POST /elastic-ip
# operationId: create-elastic-ip
# --healthcheck shape: {strikes-ok?: int, tls-skip-verify?: bool, tls-sni?: string, strikes-fail?: int, mode: "tcp"|"http"|"https", port: int, uri?: string, interval?: int, timeout?: int}
export def "elastic-ip create-elastic-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addressfamily: string@addressfamily-completer # Elastic IP address family (default: :inet4)
  --description: string # Elastic IP description
  --healthcheck: record # Elastic IP address healthcheck — shape: {strikes-ok?: int, tls-skip-verify?: bool, tls-sni?: string, strikes-fail?: int, mode: "tcp"|"http"|"https", port: int, uri?: string, interval?: int, timeout?: int}
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/elastic-ip")
  let body = {addressfamily: $addressfamily, description: $description, healthcheck: $healthcheck, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Elastic IPs
#
# GET /elastic-ip
# operationId: list-elastic-ips
export def "elastic-ip list-elastic-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<elastic_ips: table<id: string, ip: string, addressfamily: string, cidr: string, description: string, healthcheck: record, labels: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/elastic-ip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Zones
#
# GET /zone
# operationId: list-zones
export def "zone list-zones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<zones: table<name: string, api_endpoint: string, sos_endpoint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Instance Pools
#
# GET /instance-pool
# operationId: list-instance-pools
export def "instance-pool list-instance-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<instance_pools: table<application_consistent_snapshot_enabled: bool, anti_affinity_groups: list, description: string, public_ip_assignment: string, labels: record, security_groups: list, elastic_ips: list, name: string, instance_type: record, min_available: int, private_networks: list, template: record, state: string, size: int, ssh_key: record, instance_prefix: string, user_data: string, manager: record, instances: list, deploy_target: record, ipv6_enabled: bool, id: string, disk_size: int, ssh_keys: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance-pool")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Instance Pool
#
# POST /instance-pool
# operationId: create-instance-pool
# --anti-affinity-groups item shape: {id?: string}
# --security-groups item shape: {id?: string}
# --elastic-ips item shape: {id?: string}
# --instance-type shape: {id?: string}
# --private-networks item shape: {id?: string}
# --template shape: {id?: string}
# --ssh-key shape: {name?: string}
# --deploy-target shape: {id?: string}
# --ssh-keys item shape: {name?: string}
export def "instance-pool create-instance-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application-consistent-snapshot-enabled: string@bool-completer # Enable application consistent snapshots
  --anti-affinity-groups: list # Instance Pool Anti-affinity Groups — item shape: {id?: string}
  --description: string # Instance Pool description
  --public-ip-assignment: string@public-ip-assignment-completer # Determines public IP assignment of the Instances. Type `none` is final and can't be changed later on.
  --labels: record
  --security-groups: list # Instance Pool Security Groups — item shape: {id?: string}
  --elastic-ips: list # Instances Elastic IPs — item shape: {id?: string}
  name: string # Instance Pool name
  instance_type: record # Instance type reference — shape: {id?: string}
  --min-available: int # Minimum number of running Instances (format: int64)
  --private-networks: list # Instance Pool Private Networks — item shape: {id?: string}
  template: record # Template reference — shape: {id?: string}
  size: int # Number of Instances (format: int64)
  --ssh-key: record # SSH key reference — shape: {name?: string}
  --instance-prefix: string # Prefix to apply to Instances names (default: pool)
  --user-data: string # Instances Cloud-init user-data
  --deploy-target: record # Deploy target reference — shape: {id?: string}
  --ipv6-enabled: string@bool-completer # Enable IPv6. DEPRECATED: use `public-ip-assignments`.
  disk_size: int # Instances disk size in GiB (format: int64)
  --ssh-keys: list # Instances SSH Keys — item shape: {name?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance-pool")
  let body = {application-consistent-snapshot-enabled: $application_consistent_snapshot_enabled, anti-affinity-groups: $anti_affinity_groups, description: $description, public-ip-assignment: $public_ip_assignment, labels: $labels, security-groups: $security_groups, elastic-ips: $elastic_ips, name: $name, instance-type: $instance_type, min-available: $min_available, private-networks: $private_networks, template: $template, size: $size, ssh-key: $ssh_key, instance-prefix: $instance_prefix, user-data: $user_data, deploy-target: $deploy_target, ipv6-enabled: $ipv6_enabled, disk-size: $disk_size, ssh-keys: $ssh_keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Create RSyslog external integration endpoint
#
# POST /dbaas-external-endpoint-rsyslog/{name}
# operationId: create-dbaas-external-endpoint-rsyslog
# --settings shape: {format: "custom"|"rfc3164"|"rfc5424", key?: string, logline?: string, server: string, ca?: string, cert?: string, tls: bool, port: int, sd?: string, max-message-size?: int}
export def "dbaas-external-endpoint-rsyslog create-dbaas-external-endpoint-rsyslog" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {format: "custom"|"rfc3164"|"rfc5424", key?: string, logline?: string, server: string, ca?: string, cert?: string, tls: bool, port: int, sd?: string, max-message-size?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-rsyslog/($name)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a new Kubeconfig file for a SKS cluster
#
# POST /sks-cluster-kubeconfig/{id}
# operationId: generate-sks-cluster-kubeconfig
export def "sks-cluster-kubeconfig generate-sks-cluster-kubeconfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ttl: int # Validity in seconds of the Kubeconfig user certificate (default: 30 days) (format: int64)
  user: string # User name in the generated Kubeconfig. The certificate present in the Kubeconfig will also have this name set for the CN field.
  groups: list # List of roles. The certificate present in the Kubeconfig will have these roles set in the Org field.
]: any -> record<kubeconfig: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster-kubeconfig/($id)")
  let body = {ttl: $ttl, user: $user, groups: $groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List DNS domain records
#
# GET /dns-domain/{domain-id}/record
# operationId: list-dns-domain-records
export def "dns-domain-record list-dns-domain-records" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dns_domain_records: table<updated_at: string, content: string, name: string, type: string, ttl: int, priority: int, id: string, created_at: string, system_record: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($domain_id)/record")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create DNS domain record
#
# POST /dns-domain/{domain-id}/record
# operationId: create-dns-domain-record
export def "dns-domain-record create-dns-domain-record" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # DNS domain record name
  type: string@type-completer # DNS domain record type
  content: string # DNS domain record content
  --ttl: int # DNS domain record TTL (format: int64)
  --priority: int # DNS domain record priority (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($domain_id)/record")
  let body = {name: $name, type: $type, content: $content, ttl: $ttl, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get DBaaS CA Certificate
#
# GET /dbaas-ca-certificate
# operationId: get-dbaas-ca-certificate
export def "dbaas-ca-certificate get-dbaas-ca-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-ca-certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS Grafana settings
#
# GET /dbaas-settings-grafana
# operationId: get-dbaas-settings-grafana
export def "dbaas-settings-grafana get-dbaas-settings-grafana" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<grafana: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-grafana")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Deploy Targets
#
# GET /deploy-target
# operationId: list-deploy-targets
export def "deploy-target list-deploy-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deploy_targets: table<id: string, name: string, type: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploy-target")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Compute instance Types
#
# GET /instance-type
# operationId: list-instance-types
export def "instance-type list-instance-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<instance_types: table<id: string, size: string, family: string, cpus: int, gpus: int, authorized: bool, memory: int, zones: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Deployment
#
# POST /ai/deployment
# operationId: create-deployment
# --model shape: {name?: string, id?: string}
export def "ai-deployment create-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  gpu_count: int # Number of GPUs (1-8) (format: int64)
  --inference-engine-version: string@inference-engine-version-completer # Inference engine version (default: 0.22.1)
  name: string # Deployment name
  gpu_type: string # GPU type family (e.g., gpua5000, gpu3080ti)
  replicas: int # Number of replicas (>=1) (format: int64)
  --inference-engine-parameters: list # Optional extra inference engine server CLI args
  model: record # Model reference. Provide either id or name. — shape: {name?: string, id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/deployment")
  let body = {gpu-count: $gpu_count, inference-engine-version: $inference_engine_version, name: $name, gpu-type: $gpu_type, replicas: $replicas, inference-engine-parameters: $inference_engine_parameters, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Deployments
#
# GET /ai/deployment
# operationId: list-deployments
export def "ai-deployment list-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string
]: nothing -> record<deployments: table<gpu_count: int, updated_at: string, deployment_url: string, service_level: string, name: string, state: string, gpu_type: string, id: string, replicas: int, created_at: string, model: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/deployment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Retrieve the live-balance
#
# GET /live-balance
# operationId: get-live-balance
export def "live-balance get-live-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<balance: float, currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live-balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a DBaaS Postgres database
#
# DELETE /dbaas-postgres/{service-name}/database/{database-name}
# operationId: delete-dbaas-pg-database
export def "dbaas-postgres-database delete-dbaas-pg-database" [
  service_name: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/database/($database_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach block storage volume to an instance
#
# PUT /block-storage/{id}:attach
# operationId: attach-block-storage-volume-to-instance
# --instance shape: {id?: string}
export def "block-storage attach-block-storage-volume-to-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance: record # Target Instance — shape: {id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id):attach")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Enable KMS Key
#
# POST /kms-key/{id}/enable
# operationId: enable-kms-key
export def "kms-key-enable enable-kms-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a DBaaS PostgreSQL migration
#
# POST /dbaas-postgres/{name}/migration/stop
# operationId: stop-dbaas-pg-migration
export def "dbaas-postgres-migration-stop stop-dbaas-pg-migration" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($name)/migration/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a DBaaS Kafka service
#
# GET /dbaas-kafka/{name}
# operationId: get-dbaas-service-kafka
export def "dbaas-kafka get-dbaas-service-kafka" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, authentication_methods: record<certificate: bool, sasl: bool>, node_count: int, connection_info: record<nodes: list<string>, access_cert: string, access_key: string, connect_uri: string, rest_uri: string, registry_uri: string>, node_cpu_count: int, kafka_rest_enabled: bool, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, kafka_connect_enabled: bool, type: string, state: string, ip_filter: list<string>, schema_registry_settings: record<leader_eligibility: bool, topic_name: string>, backups: table<backup_name: string, backup_time: string, data_size: int>, kafka_rest_settings: record<producer_compression_type: string, name_strategy_validation: bool, name_strategy: string, consumer_enable_auto_commit: bool, producer_acks: string, consumer_request_max_bytes: int, producer_max_request_size: int, simpleconsumer_pool_size_max: int, producer_linger_ms: int, consumer_request_timeout_ms: int>, termination_protection: bool, notifications: table<level: string, message: string, type: string, metadata: record>, kafka_connect_settings: record<producer_buffer_memory: int, consumer_max_poll_interval_ms: int, producer_compression_type: string, connector_client_config_override_policy: string, offset_flush_interval_ms: int, scheduled_rebalance_max_delay_ms: int, consumer_fetch_max_bytes: int, consumer_max_partition_fetch_bytes: int, offset_flush_timeout_ms: int, consumer_auto_offset_reset: string, producer_max_request_size: int, producer_batch_size: int, session_timeout_ms: int, producer_linger_ms: int, consumer_isolation_level: string, consumer_max_poll_records: int>, components: table<component: string, host: string, kafka_authentication_method: string, port: int, route: string, usage: string>, maintenance: record<dow: string, time: string, updates: list<record>>, kafka_settings: record<sasl_oauthbearer_expected_audience: string, group_max_session_timeout_ms: int, log_flush_interval_messages: int, sasl_oauthbearer_jwks_endpoint_url: string, max_connections_per_ip: int, sasl_oauthbearer_expected_issuer: string, log_index_size_max_bytes: int, auto_create_topics_enable: bool, log_index_interval_bytes: int, replica_fetch_max_bytes: int, num_partitions: int, transaction_state_log_segment_bytes: int, replica_fetch_response_max_bytes: int, log_message_timestamp_type: string, connections_max_idle_ms: int, log_flush_interval_ms: int, log_preallocate: bool, log_segment_delete_delay_ms: int, message_max_bytes: int, group_initial_rebalance_delay_ms: int, log_local_retention_bytes: int, log_roll_jitter_ms: int, transaction_remove_expired_transaction_cleanup_interval_ms: int, transaction_partition_verification_enable: bool, default_replication_factor: int, log_roll_ms: int, producer_purgatory_purge_interval_requests: int, log_retention_bytes: int, min_insync_replicas: int, compression_type: string, log_message_timestamp_difference_max_ms: int, log_local_retention_ms: int, log_message_downconversion_enable: bool, sasl_oauthbearer_sub_claim_name: string, max_incremental_fetch_session_cache_slots: int, log_retention_hours: int, group_min_session_timeout_ms: int, socket_request_max_bytes: int, log_segment_bytes: int, log_cleanup_and_compaction: record<log_cleaner_delete_retention_ms: int, log_cleaner_max_compaction_lag_ms: int, log_cleaner_min_cleanable_ratio: float, log_cleaner_min_compaction_lag_ms: int, log_cleanup_policy: string>, offsets_retention_minutes: int, log_retention_ms: int>, disk_size: int, node_memory: int, uri: string, uri_params: record, schema_registry_enabled: bool, version: string, created_at: string, plan: string, users: table<type: string, username: string, password: string, access_cert: string, access_cert_expiry: string, access_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Kafka service
#
# POST /dbaas-kafka/{name}
# operationId: create-dbaas-service-kafka
# --authentication-methods shape: {certificate?: bool, sasl?: bool}
# --schema-registry-settings shape: {leader_eligibility?: bool, topic_name?: string}
# --kafka-rest-settings shape: {producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", name_strategy_validation?: bool, name_strategy?: "topic_name"|"record_name"|"topic_record_name", consumer_enable_auto_commit?: bool, producer_acks?: "all"|"-1"|"0"|"1", consumer_request_max_bytes?: int, producer_max_request_size?: int, simpleconsumer_pool_size_max?: int, producer_linger_ms?: int, consumer_request_timeout_ms?: "1000"|"15000"|"30000"}
# --kafka-connect-settings shape: {producer_buffer_memory?: int, consumer_max_poll_interval_ms?: int, producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", connector_client_config_override_policy?: "None"|"All", offset_flush_interval_ms?: int, scheduled_rebalance_max_delay_ms?: int, consumer_fetch_max_bytes?: int, consumer_max_partition_fetch_bytes?: int, offset_flush_timeout_ms?: int, consumer_auto_offset_reset?: "earliest"|"latest", producer_max_request_size?: int, producer_batch_size?: int, session_timeout_ms?: int, producer_linger_ms?: int, consumer_isolation_level?: "read_uncommitted"|"read_committed", consumer_max_poll_records?: int}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --kafka-settings shape: {sasl_oauthbearer_expected_audience?: string, group_max_session_timeout_ms?: int, log_flush_interval_messages?: int, sasl_oauthbearer_jwks_endpoint_url?: string, max_connections_per_ip?: int, sasl_oauthbearer_expected_issuer?: string, log_index_size_max_bytes?: int, auto_create_topics_enable?: bool, log_index_interval_bytes?: int, replica_fetch_max_bytes?: int, num_partitions?: int, transaction_state_log_segment_bytes?: int, replica_fetch_response_max_bytes?: int, log_message_timestamp_type?: "CreateTime"|"LogAppendTime", connections_max_idle_ms?: int, log_flush_interval_ms?: int, log_preallocate?: bool, log_segment_delete_delay_ms?: int, message_max_bytes?: int, group_initial_rebalance_delay_ms?: int, log_local_retention_bytes?: int, log_roll_jitter_ms?: int, transaction_remove_expired_transaction_cleanup_interval_ms?: int, transaction_partition_verification_enable?: bool, default_replication_factor?: int, log_roll_ms?: int, producer_purgatory_purge_interval_requests?: int, log_retention_bytes?: int, min_insync_replicas?: int, compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"uncompressed"|"producer", log_message_timestamp_difference_max_ms?: int, log_local_retention_ms?: int, log_message_downconversion_enable?: bool, sasl_oauthbearer_sub_claim_name?: string, max_incremental_fetch_session_cache_slots?: int, log_retention_hours?: int, group_min_session_timeout_ms?: int, socket_request_max_bytes?: int, log_segment_bytes?: int, log-cleanup-and-compaction?: record, offsets_retention_minutes?: int, log_retention_ms?: int}
export def "dbaas-kafka create-dbaas-service-kafka" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authentication-methods: record # Kafka authentication methods — shape: {certificate?: bool, sasl?: bool}
  --kafka-rest-enabled: string@bool-completer # Enable Kafka-REST service
  --kafka-connect-enabled: string@bool-completer # Allow clients to connect to kafka_connect from the public internet for service nodes that are in a project VPC or another type of private network
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --schema-registry-settings: record # shape: {leader_eligibility?: bool, topic_name?: string}
  --kafka-rest-settings: record # shape: {producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", name_strategy_validation?: bool, name_strategy?: "topic_name"|"record_name"|"topic_record_name", consumer_enable_auto_commit?: bool, producer_acks?: "all"|"-1"|"0"|"1", consumer_request_max_bytes?: int, producer_max_request_size?: int, simpleconsumer_pool_size_max?: int, producer_linger_ms?: int, consumer_request_timeout_ms?: "1000"|"15000"|"30000"}
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --kafka-connect-settings: record # shape: {producer_buffer_memory?: int, consumer_max_poll_interval_ms?: int, producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", connector_client_config_override_policy?: "None"|"All", offset_flush_interval_ms?: int, scheduled_rebalance_max_delay_ms?: int, consumer_fetch_max_bytes?: int, consumer_max_partition_fetch_bytes?: int, offset_flush_timeout_ms?: int, consumer_auto_offset_reset?: "earliest"|"latest", producer_max_request_size?: int, producer_batch_size?: int, session_timeout_ms?: int, producer_linger_ms?: int, consumer_isolation_level?: "read_uncommitted"|"read_committed", consumer_max_poll_records?: int}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --kafka-settings: record # shape: {sasl_oauthbearer_expected_audience?: string, group_max_session_timeout_ms?: int, log_flush_interval_messages?: int, sasl_oauthbearer_jwks_endpoint_url?: string, max_connections_per_ip?: int, sasl_oauthbearer_expected_issuer?: string, log_index_size_max_bytes?: int, auto_create_topics_enable?: bool, log_index_interval_bytes?: int, replica_fetch_max_bytes?: int, num_partitions?: int, transaction_state_log_segment_bytes?: int, replica_fetch_response_max_bytes?: int, log_message_timestamp_type?: "CreateTime"|"LogAppendTime", connections_max_idle_ms?: int, log_flush_interval_ms?: int, log_preallocate?: bool, log_segment_delete_delay_ms?: int, message_max_bytes?: int, group_initial_rebalance_delay_ms?: int, log_local_retention_bytes?: int, log_roll_jitter_ms?: int, transaction_remove_expired_transaction_cleanup_interval_ms?: int, transaction_partition_verification_enable?: bool, default_replication_factor?: int, log_roll_ms?: int, producer_purgatory_purge_interval_requests?: int, log_retention_bytes?: int, min_insync_replicas?: int, compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"uncompressed"|"producer", log_message_timestamp_difference_max_ms?: int, log_local_retention_ms?: int, log_message_downconversion_enable?: bool, sasl_oauthbearer_sub_claim_name?: string, max_incremental_fetch_session_cache_slots?: int, log_retention_hours?: int, group_min_session_timeout_ms?: int, socket_request_max_bytes?: int, log_segment_bytes?: int, log-cleanup-and-compaction?: record, offsets_retention_minutes?: int, log_retention_ms?: int}
  --schema-registry-enabled: string@bool-completer # Enable Schema-Registry service
  --version: string # Kafka major version
  plan: string # Subscription plan
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)")
  let body = {authentication-methods: $authentication_methods, kafka-rest-enabled: $kafka_rest_enabled, kafka-connect-enabled: $kafka_connect_enabled, ip-filter: $ip_filter, schema-registry-settings: $schema_registry_settings, kafka-rest-settings: $kafka_rest_settings, termination-protection: $termination_protection, kafka-connect-settings: $kafka_connect_settings, maintenance: $maintenance, kafka-settings: $kafka_settings, schema-registry-enabled: $schema_registry_enabled, version: $version, plan: $plan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a DBaaS Kafka service
#
# PUT /dbaas-kafka/{name}
# operationId: update-dbaas-service-kafka
# --authentication-methods shape: {certificate?: bool, sasl?: bool}
# --schema-registry-settings shape: {leader_eligibility?: bool, topic_name?: string}
# --kafka-rest-settings shape: {producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", name_strategy_validation?: bool, name_strategy?: "topic_name"|"record_name"|"topic_record_name", consumer_enable_auto_commit?: bool, producer_acks?: "all"|"-1"|"0"|"1", consumer_request_max_bytes?: int, producer_max_request_size?: int, simpleconsumer_pool_size_max?: int, producer_linger_ms?: int, consumer_request_timeout_ms?: "1000"|"15000"|"30000"}
# --kafka-connect-settings shape: {producer_buffer_memory?: int, consumer_max_poll_interval_ms?: int, producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", connector_client_config_override_policy?: "None"|"All", offset_flush_interval_ms?: int, scheduled_rebalance_max_delay_ms?: int, consumer_fetch_max_bytes?: int, consumer_max_partition_fetch_bytes?: int, offset_flush_timeout_ms?: int, consumer_auto_offset_reset?: "earliest"|"latest", producer_max_request_size?: int, producer_batch_size?: int, session_timeout_ms?: int, producer_linger_ms?: int, consumer_isolation_level?: "read_uncommitted"|"read_committed", consumer_max_poll_records?: int}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --kafka-settings shape: {sasl_oauthbearer_expected_audience?: string, group_max_session_timeout_ms?: int, log_flush_interval_messages?: int, sasl_oauthbearer_jwks_endpoint_url?: string, max_connections_per_ip?: int, sasl_oauthbearer_expected_issuer?: string, log_index_size_max_bytes?: int, auto_create_topics_enable?: bool, log_index_interval_bytes?: int, replica_fetch_max_bytes?: int, num_partitions?: int, transaction_state_log_segment_bytes?: int, replica_fetch_response_max_bytes?: int, log_message_timestamp_type?: "CreateTime"|"LogAppendTime", connections_max_idle_ms?: int, log_flush_interval_ms?: int, log_preallocate?: bool, log_segment_delete_delay_ms?: int, message_max_bytes?: int, group_initial_rebalance_delay_ms?: int, log_local_retention_bytes?: int, log_roll_jitter_ms?: int, transaction_remove_expired_transaction_cleanup_interval_ms?: int, transaction_partition_verification_enable?: bool, default_replication_factor?: int, log_roll_ms?: int, producer_purgatory_purge_interval_requests?: int, log_retention_bytes?: int, min_insync_replicas?: int, compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"uncompressed"|"producer", log_message_timestamp_difference_max_ms?: int, log_local_retention_ms?: int, log_message_downconversion_enable?: bool, sasl_oauthbearer_sub_claim_name?: string, max_incremental_fetch_session_cache_slots?: int, log_retention_hours?: int, group_min_session_timeout_ms?: int, socket_request_max_bytes?: int, log_segment_bytes?: int, log-cleanup-and-compaction?: record, offsets_retention_minutes?: int, log_retention_ms?: int}
export def "dbaas-kafka update-dbaas-service-kafka" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authentication-methods: record # Kafka authentication methods — shape: {certificate?: bool, sasl?: bool}
  --kafka-rest-enabled: string@bool-completer # Enable Kafka-REST service
  --kafka-connect-enabled: string@bool-completer # Allow clients to connect to kafka_connect from the public internet for service nodes that are in a project VPC or another type of private network
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --schema-registry-settings: record # shape: {leader_eligibility?: bool, topic_name?: string}
  --kafka-rest-settings: record # shape: {producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", name_strategy_validation?: bool, name_strategy?: "topic_name"|"record_name"|"topic_record_name", consumer_enable_auto_commit?: bool, producer_acks?: "all"|"-1"|"0"|"1", consumer_request_max_bytes?: int, producer_max_request_size?: int, simpleconsumer_pool_size_max?: int, producer_linger_ms?: int, consumer_request_timeout_ms?: "1000"|"15000"|"30000"}
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --kafka-connect-settings: record # shape: {producer_buffer_memory?: int, consumer_max_poll_interval_ms?: int, producer_compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"none", connector_client_config_override_policy?: "None"|"All", offset_flush_interval_ms?: int, scheduled_rebalance_max_delay_ms?: int, consumer_fetch_max_bytes?: int, consumer_max_partition_fetch_bytes?: int, offset_flush_timeout_ms?: int, consumer_auto_offset_reset?: "earliest"|"latest", producer_max_request_size?: int, producer_batch_size?: int, session_timeout_ms?: int, producer_linger_ms?: int, consumer_isolation_level?: "read_uncommitted"|"read_committed", consumer_max_poll_records?: int}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --kafka-settings: record # shape: {sasl_oauthbearer_expected_audience?: string, group_max_session_timeout_ms?: int, log_flush_interval_messages?: int, sasl_oauthbearer_jwks_endpoint_url?: string, max_connections_per_ip?: int, sasl_oauthbearer_expected_issuer?: string, log_index_size_max_bytes?: int, auto_create_topics_enable?: bool, log_index_interval_bytes?: int, replica_fetch_max_bytes?: int, num_partitions?: int, transaction_state_log_segment_bytes?: int, replica_fetch_response_max_bytes?: int, log_message_timestamp_type?: "CreateTime"|"LogAppendTime", connections_max_idle_ms?: int, log_flush_interval_ms?: int, log_preallocate?: bool, log_segment_delete_delay_ms?: int, message_max_bytes?: int, group_initial_rebalance_delay_ms?: int, log_local_retention_bytes?: int, log_roll_jitter_ms?: int, transaction_remove_expired_transaction_cleanup_interval_ms?: int, transaction_partition_verification_enable?: bool, default_replication_factor?: int, log_roll_ms?: int, producer_purgatory_purge_interval_requests?: int, log_retention_bytes?: int, min_insync_replicas?: int, compression_type?: "gzip"|"snappy"|"lz4"|"zstd"|"uncompressed"|"producer", log_message_timestamp_difference_max_ms?: int, log_local_retention_ms?: int, log_message_downconversion_enable?: bool, sasl_oauthbearer_sub_claim_name?: string, max_incremental_fetch_session_cache_slots?: int, log_retention_hours?: int, group_min_session_timeout_ms?: int, socket_request_max_bytes?: int, log_segment_bytes?: int, log-cleanup-and-compaction?: record, offsets_retention_minutes?: int, log_retention_ms?: int}
  --schema-registry-enabled: string@bool-completer # Enable Schema-Registry service
  --version: string # Kafka major version
  --plan: string # Subscription plan
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)")
  let body = {authentication-methods: $authentication_methods, kafka-rest-enabled: $kafka_rest_enabled, kafka-connect-enabled: $kafka_connect_enabled, ip-filter: $ip_filter, schema-registry-settings: $schema_registry_settings, kafka-rest-settings: $kafka_rest_settings, termination-protection: $termination_protection, kafka-connect-settings: $kafka_connect_settings, maintenance: $maintenance, kafka-settings: $kafka_settings, schema-registry-enabled: $schema_registry_enabled, version: $version, plan: $plan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Kafka service
#
# DELETE /dbaas-kafka/{name}
# operationId: delete-dbaas-service-kafka
export def "dbaas-kafka delete-dbaas-service-kafka" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset a compute instance password
#
# PUT /instance/{id}:reset-password
# operationId: reset-instance-password
export def "instance reset-instance-password" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):reset-password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a Kafka Schema Registry ACL entry
#
# POST /dbaas-kafka/{name}/schema-registry/acl-config
# operationId: create-dbaas-kafka-schema-registry-acl-config
export def "dbaas-kafka-schema-registry-acl-config create-dbaas-kafka-schema-registry-acl-config" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  username: string # Kafka username or username pattern
  resource: string # Kafka Schema Registry name or pattern
  permission: string@permission-completer # Kafka Schema Registry permission
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)/schema-registry/acl-config")
  let body = {id: $id, username: $username, resource: $resource, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the IP address of an instance attached to a managed private network
#
# PUT /private-network/{id}:update-ip
# operationId: update-private-network-instance-ip
# --instance shape: {id: string}
export def "private-network update-private-network-instance-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ip: string # Static IP address lease for the corresponding network interface (format: ipv4)
  --instance: record # shape: {id: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id):update-ip")
  let body = {ip: $ip, instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an SKS Nodepool
#
# PUT /sks-cluster/{id}/nodepool/{sks-nodepool-id}
# operationId: update-sks-nodepool
# --anti-affinity-groups item shape: {id?: string}
# --security-groups item shape: {id?: string}
# --instance-type shape: {id?: string}
# --private-networks item shape: {id?: string}
# --kubelet-image-gc shape: {high-threshold?: int, low-threshold?: int, min-age?: string}
# --deploy-target shape: {id?: string}
export def "sks-cluster-nodepool update-sks-nodepool" [
  id: string
  sks_nodepool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anti-affinity-groups: list # Nodepool Anti-affinity Groups — item shape: {id?: string}
  --description: string # Nodepool description
  --public-ip-assignment: string@public-ip-assignment-completer-1 # Configures public IP assignment of the Instances with:  * IPv4 (`inet4`) addressing only; * both IPv4 and IPv6 (`dual`) addressing.
  --labels: record
  --taints: record
  --security-groups: list # Nodepool Security Groups — item shape: {id?: string}
  --name: string # Nodepool name, lowercase only
  --instance-type: record # Instance type reference — shape: {id?: string}
  --private-networks: list # Nodepool Private Networks — item shape: {id?: string}
  --kubelet-image-gc: record # Kubelet image GC options — shape: {high-threshold?: int, low-threshold?: int, min-age?: string}
  --instance-prefix: string # Prefix to apply to managed instances names (default: pool), lowercase only
  --deploy-target: record # Deploy target reference — shape: {id?: string}
  --disk-size: int # Nodepool instances disk size in GiB (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/nodepool/($sks_nodepool_id)")
  let body = {anti-affinity-groups: $anti_affinity_groups, description: $description, public-ip-assignment: $public_ip_assignment, labels: $labels, taints: $taints, security-groups: $security_groups, name: $name, instance-type: $instance_type, private-networks: $private_networks, kubelet-image-gc: $kubelet_image_gc, instance-prefix: $instance_prefix, deploy-target: $deploy_target, disk-size: $disk_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve SKS Nodepool details
#
# GET /sks-cluster/{id}/nodepool/{sks-nodepool-id}
# operationId: get-sks-nodepool
export def "sks-cluster-nodepool get-sks-nodepool" [
  id: string
  sks_nodepool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<anti_affinity_groups: table<id: string>, description: string, public_ip_assignment: string, labels: record, taints: record, security_groups: table<id: string>, name: string, instance_type: record<id: string>, private_networks: table<id: string>, template: record<id: string>, state: string, size: int, kubelet_image_gc: record<high_threshold: int, low_threshold: int, min_age: string>, instance_pool: record<id: string>, instance_prefix: string, deploy_target: record<id: string>, addons: list<string>, id: string, disk_size: int, version: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/nodepool/($sks_nodepool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an SKS Nodepool
#
# DELETE /sks-cluster/{id}/nodepool/{sks-nodepool-id}
# operationId: delete-sks-nodepool
export def "sks-cluster-nodepool delete-sks-nodepool" [
  id: string
  sks_nodepool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/nodepool/($sks_nodepool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a block storage snapshot, data will be unrecoverable
#
# DELETE /block-storage-snapshot/{id}
# operationId: delete-block-storage-snapshot
export def "block-storage-snapshot delete-block-storage-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage-snapshot/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update block storage volume snapshot
#
# PUT /block-storage-snapshot/{id}
# operationId: update-block-storage-snapshot
export def "block-storage-snapshot update-block-storage-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Snapshot name (nullable)
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage-snapshot/($id)")
  let body = {name: $name, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve block storage snapshot details
#
# GET /block-storage-snapshot/{id}
# operationId: get-block-storage-snapshot
export def "block-storage-snapshot get-block-storage-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, size: int, volume_size: int, created_at: string, state: string, labels: record, block_storage_volume: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage-snapshot/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] List KMS Key Rotations
#
# GET /kms-key/{id}/list-key-rotations
# operationId: list-kms-key-rotations
export def "kms-key-list-key-rotations list-kms-key-rotations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rotations: table<version: int, rotated_at: string, automatic: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/list-key-rotations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Postgres user
#
# POST /dbaas-postgres/{service-name}/user
# operationId: create-dbaas-postgres-user
export def "dbaas-postgres-user create-dbaas-postgres-user" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  --allow-replication: string@bool-completer
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/user")
  let body = {username: $username, allow-replication: $allow_replication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] List all DBaaS connections between services and external endpoints
#
# GET /dbaas-external-integrations/{service-name}
# operationId: list-dbaas-external-integrations
export def "dbaas-external-integrations list-dbaas-external-integrations" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<external_integrations: table<description: string, dest_endpoint_name: string, dest_endpoint_id: string, integration_id: string, status: string, source_service_name: string, source_service_type: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-integrations/($service_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get a DBaaS external integration
#
# GET /dbaas-external-integration/{integration-id}
# operationId: get-dbaas-external-integration
export def "dbaas-external-integration get-dbaas-external-integration" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, dest_endpoint_name: string, dest_endpoint_id: string, integration_id: string, status: string, source_service_name: string, source_service_type: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-integration/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Instance Pool
#
# DELETE /instance-pool/{id}
# operationId: delete-instance-pool
export def "instance-pool delete-instance-pool" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-pool/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Instance Pool details
#
# GET /instance-pool/{id}
# operationId: get-instance-pool
export def "instance-pool get-instance-pool" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_consistent_snapshot_enabled: bool, anti_affinity_groups: table<id: string>, description: string, public_ip_assignment: string, labels: record, security_groups: table<id: string>, elastic_ips: table<id: string>, name: string, instance_type: record<id: string>, min_available: int, private_networks: table<id: string>, template: record<id: string>, state: string, size: int, ssh_key: record<name: string>, instance_prefix: string, user_data: string, manager: record<id: string, type: string>, instances: table<id: string>, deploy_target: record<id: string>, ipv6_enabled: bool, id: string, disk_size: int, ssh_keys: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-pool/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Instance Pool
#
# PUT /instance-pool/{id}
# operationId: update-instance-pool
# --anti-affinity-groups item shape: {id?: string}
# --security-groups item shape: {id?: string}
# --elastic-ips item shape: {id?: string}
# --instance-type shape: {id?: string}
# --private-networks item shape: {id?: string}
# --template shape: {id?: string}
# --ssh-key shape: {name?: string}
# --deploy-target shape: {id?: string}
# --ssh-keys item shape: {name?: string}
export def "instance-pool update-instance-pool" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application-consistent-snapshot-enabled: string@bool-completer # Enable application consistent snapshots
  --anti-affinity-groups: list # Instance Pool Anti-affinity Groups (nullable) — item shape: {id?: string}
  --description: string # Instance Pool description
  --public-ip-assignment: string@public-ip-assignment-completer-1 # Determines public IP assignment of the Instances.
  --labels: record
  --security-groups: list # Instance Pool Security Groups (nullable) — item shape: {id?: string}
  --elastic-ips: list # Instances Elastic IPs (nullable) — item shape: {id?: string}
  --name: string # Instance Pool name
  --instance-type: record # Instance type reference — shape: {id?: string}
  --min-available: int # Minimum number of running Instances (nullable, format: int64)
  --private-networks: list # Instance Pool Private Networks (nullable) — item shape: {id?: string}
  --template: record # Template reference — shape: {id?: string}
  --ssh-key: record # SSH key reference — shape: {name?: string}
  --instance-prefix: string # Prefix to apply to Instances names (default: pool) (nullable)
  --user-data: string # Instances Cloud-init user-data (nullable)
  --deploy-target: record # Deploy target reference — shape: {id?: string}
  --ipv6-enabled: string@bool-completer # Enable IPv6. DEPRECATED: use `public-ip-assignments`.
  --disk-size: int # Instances disk size in GiB (format: int64)
  --ssh-keys: list # Instances SSH keys (nullable) — item shape: {name?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-pool/($id)")
  let body = {application-consistent-snapshot-enabled: $application_consistent_snapshot_enabled, anti-affinity-groups: $anti_affinity_groups, description: $description, public-ip-assignment: $public_ip_assignment, labels: $labels, security-groups: $security_groups, elastic-ips: $elastic_ips, name: $name, instance-type: $instance_type, min-available: $min_available, private-networks: $private_networks, template: $template, ssh-key: $ssh_key, instance-prefix: $instance_prefix, user-data: $user_data, deploy-target: $deploy_target, ipv6-enabled: $ipv6_enabled, disk-size: $disk_size, ssh-keys: $ssh_keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] List available external endpoint types and their schemas for DBaaS external integrations
#
# GET /dbaas-external-endpoint-types
# operationId: list-dbaas-external-endpoint-types
export def "dbaas-external-endpoint-types list-dbaas-external-endpoint-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<endpoint_types: table<type: string, service_types: list, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-external-endpoint-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete AI API Key
#
# DELETE /ai/api-key/{id}
# operationId: delete-ai-api-key
export def "ai-api-key delete-ai-api-key" [
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
  let full_url = (build-url $base $"/ai/api-key/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get AI API Key
#
# GET /ai/api-key/{id}
# operationId: get-ai-api-key
export def "ai-api-key get-ai-api-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, name: string, scope: string, id: string, org_uuid: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/api-key/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update AI API Key
#
# PATCH /ai/api-key/{id}
# operationId: update-ai-api-key
export def "ai-api-key update-ai-api-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Human-readable name for the AI API key
  --scope: string # Key scope: 'public' for all deployments, or a specific deployment UUID
]: any -> record<updated_at: string, name: string, scope: string, id: string, org_uuid: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/api-key/($id)")
  let body = {name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Private Networks
#
# GET /private-network
# operationId: list-private-networks
export def "private-network list-private-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<private_networks: table<description: string, labels: record, name: string, start_ip: string, leases: list, id: string, vni: int, netmask: string, options: record, end_ip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private-network")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Private Network
#
# POST /private-network
# operationId: create-private-network
# --options shape: {routers?: list, dns-servers?: list, ntp-servers?: list, domain-search?: list}
export def "private-network create-private-network" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Private Network name
  --description: string # Private Network description
  --netmask: string # Private Network netmask (format: ipv4)
  --start-ip: string # Private Network start IP address (format: ipv4)
  --end-ip: string # Private Network end IP address (format: ipv4)
  --labels: record
  --options: record # Private Network DHCP Options — shape: {routers?: list, dns-servers?: list, ntp-servers?: list, domain-search?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private-network")
  let body = {name: $name, description: $description, netmask: $netmask, start-ip: $start_ip, end-ip: $end_ip, labels: $labels, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Create a VPC
#
# POST /vpc
# operationId: create-vpc
export def "vpc create-vpc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # VPC name
  --description: string # VPC description
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vpc")
  let body = {name: $name, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] List VPCs
#
# GET /vpc
# operationId: list-vpcs
export def "vpc list-vpcs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<vpcs: table<id: string, name: string, description: string, created_at: string, labels: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vpc")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate AI API Key
#
# POST /ai/api-key/{id}/rotate
# operationId: rotate-ai-api-key
export def "ai-api-key-rotate rotate-ai-api-key" [
  id: string
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
  let full_url = (build-url $base $"/ai/api-key/($id)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a Compute instance
#
# PUT /instance/{id}:start
# operationId: start-instance
export def "instance start-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rescue-profile: string@rescue-profile-completer # Boot in Rescue Mode, using named profile (supported: netboot, netboot-efi)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):start")
  let body = {rescue-profile: $rescue_profile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable tpm for the instance.
#
# POST /instance/{id}:enable-tpm
# operationId: enable-tpm
export def "instance enable-tpm" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):enable-tpm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an organization
#
# GET /organization
# operationId: get-organization
export def "organization get-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, address: string, postcode: string, city: string, country: string, balance: float, currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Security Group details
#
# GET /security-group/{id}
# operationId: get-security-group
export def "security-group get-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, external_sources: list<string>, rules: table<description: string, start_port: int, protocol: string, icmp: record, end_port: int, security_group: record, id: string, network: string, flow_direction: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Security Group
#
# DELETE /security-group/{id}
# operationId: delete-security-group
export def "security-group delete-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the certificate for a SKS cluster authority
#
# GET /sks-cluster/{id}/authority/{authority}/cert
# operationId: get-sks-cluster-authority-cert
export def "sks-cluster-authority-cert get-sks-cluster-authority-cert" [
  id: string
  authority: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cacert: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/authority/($authority)/cert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a Snapshot
#
# POST /snapshot/{id}:export
# operationId: export-snapshot
export def "snapshot export-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snapshot/($id):export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment
#
# GET /ai/deployment/{id}
# operationId: get-deployment
export def "ai-deployment get-deployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gpu_count: int, updated_at: string, deployment_url: string, service_level: string, inference_engine_version: string, name: string, state: string, gpu_type: string, id: string, replicas: int, state_details: string, created_at: string, inference_engine_parameters: list<string>, model: record<name: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/deployment/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Deployment
#
# PATCH /ai/deployment/{id}
# operationId: update-deployment
export def "ai-deployment update-deployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inference-engine-version: string@inference-engine-version-completer # Inference engine version (default: 0.22.1)
  --name: string # Deployment name
  --inference-engine-parameters: list # Optional extra inference engine server CLI args
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/deployment/($id)")
  let body = {inference-engine-version: $inference_engine_version, name: $name, inference-engine-parameters: $inference_engine_parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Deployment
#
# DELETE /ai/deployment/{id}
# operationId: delete-deployment
export def "ai-deployment delete-deployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/deployment/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal the secrets for DBaaS Kafka Connect
#
# GET /dbaas-kafka/{service-name}/connect/password/reveal
# operationId: reveal-dbaas-kafka-connect-password
export def "dbaas-kafka-connect-password-reveal reveal-dbaas-kafka-connect-password" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($service_name)/connect/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Enable Key Rotation
#
# POST /kms-key/{id}/enable-key-rotation
# operationId: enable-kms-key-rotation
export def "kms-key-enable-key-rotation enable-kms-key-rotation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rotation-period: int # default: 365
]: any -> record<rotation: record<manual_count: int, automatic: bool, rotation_period: int, next_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/enable-key-rotation")
  let body = {rotation-period: $rotation_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset an Elastic IP field to its default value
#
# DELETE /elastic-ip/{id}/{field}
# operationId: reset-elastic-ip-field
export def "elastic-ip reset-elastic-ip-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/elastic-ip/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Resource Quota
#
# GET /quota/{entity}
# operationId: get-quota
export def "quota get-quota" [
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resource: string, usage: int, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quota/($entity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resources that are scheduled to be removed in future kubernetes releases
#
# GET /sks-cluster-deprecated-resources/{id}
# operationId: list-sks-cluster-deprecated-resources
export def "sks-cluster-deprecated-resources list-sks-cluster-deprecated-resources" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<group: string, version: string, resource: string, subresource: string, removed_release: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster-deprecated-resources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve block storage volume details
#
# GET /block-storage/{id}
# operationId: get-block-storage-volume
export def "block-storage get-block-storage-volume" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<labels: record, instance: record<id: string>, name: string, state: string, size: int, blocksize: int, block_storage_snapshots: table<id: string>, id: string, encrypted: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update block storage volume
#
# PUT /block-storage/{id}
# operationId: update-block-storage-volume
export def "block-storage update-block-storage-volume" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Volume name (nullable)
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id)")
  let body = {name: $name, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a block storage volume, data will be unrecoverable
#
# DELETE /block-storage/{id}
# operationId: delete-block-storage-volume
export def "block-storage delete-block-storage-volume" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a DBaaS OpenSearch user
#
# DELETE /dbaas-opensearch/{service-name}/user/{username}
# operationId: delete-dbaas-opensearch-user
export def "dbaas-opensearch-user delete-dbaas-opensearch-user" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($service_name)/user/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get Prometheus external integration endpoint settings
#
# GET /dbaas-external-endpoint-prometheus/{endpoint-id}
# operationId: get-dbaas-external-endpoint-prometheus
export def "dbaas-external-endpoint-prometheus get-dbaas-external-endpoint-prometheus" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, id: string, settings: record<basic_auth_username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-prometheus/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Delete Prometheus external integration endpoint
#
# DELETE /dbaas-external-endpoint-prometheus/{endpoint-id}
# operationId: delete-dbaas-external-endpoint-prometheus
export def "dbaas-external-endpoint-prometheus delete-dbaas-external-endpoint-prometheus" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-prometheus/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update Prometheus external integration endpoint
#
# PUT /dbaas-external-endpoint-prometheus/{endpoint-id}
# operationId: update-dbaas-external-endpoint-prometheus
# --settings shape: {basic-auth-password?: string, basic-auth-username?: string}
export def "dbaas-external-endpoint-prometheus update-dbaas-external-endpoint-prometheus" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {basic-auth-password?: string, basic-auth-username?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-prometheus/($endpoint_id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a block storage snapshot
#
# POST /block-storage/{id}:create-snapshot
# operationId: create-block-storage-snapshot
export def "block-storage create-block-storage-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Snapshot name
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id):create-snapshot")
  let body = {name: $name, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detach a Compute instance from a Private Network
#
# PUT /private-network/{id}:detach
# operationId: detach-instance-from-private-network
# --instance shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, private-networks?: list, template?: record, state?: "expunging"|"starting"|"destroying"|"running"|"stopping"|"stopped"|"migrating"|"error"|"destroyed", secureboot-enabled?: bool, ssh-key?: record, user-data?: string, manager?: record, tpm-enabled?: bool, deploy-target?: record, snapshots?: list, disk-size?: int, ssh-keys?: list}
export def "private-network detach-instance-from-private-network" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance: record # Instance — shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, private-networks?: list, template?: record, state?: "expunging"|"starting"|"destroying"|"running"|"stopping"|"stopped"|"migrating"|"error"|"destroyed", secureboot-enabled?: bool, ssh-key?: record, user-data?: string, manager?: record, tpm-enabled?: bool, deploy-target?: record, snapshots?: list, disk-size?: int, ssh-keys?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id):detach")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Private Network
#
# PUT /private-network/{id}
# operationId: update-private-network
# --options shape: {routers?: list, dns-servers?: list, ntp-servers?: list, domain-search?: list}
export def "private-network update-private-network" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Private Network name
  --description: string # Private Network description
  --netmask: string # Private Network netmask (format: ipv4)
  --start-ip: string # Private Network start IP address (format: ipv4)
  --end-ip: string # Private Network end IP address (format: ipv4)
  --labels: record
  --options: record # Private Network DHCP Options — shape: {routers?: list, dns-servers?: list, ntp-servers?: list, domain-search?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id)")
  let body = {name: $name, description: $description, netmask: $netmask, start-ip: $start_ip, end-ip: $end_ip, labels: $labels, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Private Network details
#
# GET /private-network/{id}
# operationId: get-private-network
export def "private-network get-private-network" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, labels: record, name: string, start_ip: string, leases: table<ip: string, instance_id: string>, id: string, vni: int, netmask: string, options: record<routers: list<string>, dns_servers: list<string>, ntp_servers: list<string>, domain_search: list<string>>, end_ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Private Network
#
# DELETE /private-network/{id}
# operationId: delete-private-network
export def "private-network delete-private-network" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Instance Types
#
# GET /ai/instance-type
# operationId: list-ai-instance-types
export def "ai-instance-type list-ai-instance-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<instance_types: table<family: string, authorized: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/instance-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset a Load Balancer field to its default value
#
# DELETE /load-balancer/{id}/{field}
# operationId: reset-load-balancer-field
export def "load-balancer reset-load-balancer-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Scale a Compute instance to a new Instance Type
#
# PUT /instance/{id}:scale
# operationId: scale-instance
# --instance-type shape: {id?: string}
export def "instance scale-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance_type: record # Instance type reference — shape: {id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):scale")
  let body = {instance-type: $instance_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new API key
#
# POST /api-key
# operationId: create-api-key
export def "api-key create-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_id: string # IAM API Key Role ID (format: uuid)
  name: string # IAM API Key Name
]: any -> record<name: string, key: string, secret: string, role_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-key")
  let body = {role-id: $role_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List API keys
#
# GET /api-key
# operationId: list-api-keys
export def "api-key list-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_keys: table<name: string, key: string, role_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List block storage snapshots
#
# GET /block-storage-snapshot
# operationId: list-block-storage-snapshots
export def "block-storage-snapshot list-block-storage-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<block_storage_snapshots: table<id: string, name: string, size: int, volume_size: int, created_at: string, state: string, labels: record, block_storage_volume: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/block-storage-snapshot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List DNS domains
#
# GET /dns-domain
# operationId: list-dns-domains
export def "dns-domain list-dns-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dns_domains: table<id: string, created_at: string, unicode_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dns-domain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create DNS domain
#
# POST /dns-domain
# operationId: create-dns-domain
export def "dns-domain create-dns-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --unicode-name: string # Domain name
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dns-domain")
  let body = {unicode-name: $unicode_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop a Compute instance
#
# PUT /instance/{id}:stop
# operationId: stop-instance
export def "instance stop-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve DNS domain record details
#
# GET /dns-domain/{domain-id}/record/{record-id}
# operationId: get-dns-domain-record
export def "dns-domain-record get-dns-domain-record" [
  domain_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, content: string, name: string, type: string, ttl: int, priority: int, id: string, created_at: string, system_record: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($domain_id)/record/($record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update DNS domain record
#
# PUT /dns-domain/{domain-id}/record/{record-id}
# operationId: update-dns-domain-record
export def "dns-domain-record update-dns-domain-record" [
  domain_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # DNS domain record name
  --content: string # DNS domain record content
  --ttl: int # DNS domain record TTL (format: int64)
  --priority: int # DNS domain record priority (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($domain_id)/record/($record_id)")
  let body = {name: $name, content: $content, ttl: $ttl, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete DNS domain record
#
# DELETE /dns-domain/{domain-id}/record/{record-id}
# operationId: delete-dns-domain-record
export def "dns-domain-record delete-dns-domain-record" [
  domain_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($domain_id)/record/($record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Kafka user
#
# POST /dbaas-kafka/{service-name}/user
# operationId: create-dbaas-kafka-user
export def "dbaas-kafka-user create-dbaas-kafka-user" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($service_name)/user")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the credentials of a DBaaS Valkey user
#
# PUT /dbaas-valkey/{service-name}/user/{username}/password/reset
# operationId: reset-dbaas-valkey-user-password
export def "dbaas-valkey-user-password-reset reset-dbaas-valkey-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($service_name)/user/($username)/password/reset")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Manage Datadog integration settings
#
# POST /dbaas-external-integration-settings-datadog/{integration-id}
# operationId: update-dbaas-external-integration-settings-datadog
# --settings shape: {datadog-dbm-enabled?: bool, datadog-pgbouncer-enabled?: bool}
export def "dbaas-external-integration-settings-datadog update-dbaas-external-integration-settings-datadog" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {datadog-dbm-enabled?: bool, datadog-pgbouncer-enabled?: bool}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-integration-settings-datadog/($integration_id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get Datadog integration settings
#
# GET /dbaas-external-integration-settings-datadog/{integration-id}
# operationId: get-dbaas-external-integration-settings-datadog
export def "dbaas-external-integration-settings-datadog get-dbaas-external-integration-settings-datadog" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<datadog_dbm_enabled: bool, datadog_pgbouncer_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-integration-settings-datadog/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach a Compute instance to a Security Group
#
# PUT /security-group/{id}:attach
# operationId: attach-instance-to-security-group
# --instance shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, private-networks?: list, template?: record, state?: "expunging"|"starting"|"destroying"|"running"|"stopping"|"stopped"|"migrating"|"error"|"destroyed", secureboot-enabled?: bool, ssh-key?: record, user-data?: string, manager?: record, tpm-enabled?: bool, deploy-target?: record, snapshots?: list, disk-size?: int, ssh-keys?: list}
export def "security-group attach-instance-to-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance: record # Instance — shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, private-networks?: list, template?: record, state?: "expunging"|"starting"|"destroying"|"running"|"stopping"|"stopped"|"migrating"|"error"|"destroyed", secureboot-enabled?: bool, ssh-key?: record, user-data?: string, manager?: record, tpm-enabled?: bool, deploy-target?: record, snapshots?: list, disk-size?: int, ssh-keys?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id):attach")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Snapshot
#
# DELETE /snapshot/{id}
# operationId: delete-snapshot
export def "snapshot delete-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snapshot/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Snapshot details
#
# GET /snapshot/{id}
# operationId: get-snapshot
export def "snapshot get-snapshot" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, created_at: string, state: string, size: int, export: record<presigned_url: string, md5sum: string>, instance: record<application_consistent_snapshot_enabled: bool, anti_affinity_groups: list<record>, public_ip_assignment: string, labels: record, security_groups: list<record>, elastic_ips: list<record>, name: string, instance_type: record<id: string, size: string, family: string, cpus: int, gpus: int, authorized: bool, memory: int, zones: list>, private_networks: list<record>, template: record<application_consistent_snapshot_enabled: bool, maintainer: string, description: string, ssh_key_enabled: bool, family: string, name: string, default_user: string, size: int, password_enabled: bool, build: string, checksum: string, boot_mode: string, id: string, zones: list, url: string, version: string, created_at: string, visibility: string>, state: string, secureboot_enabled: bool, ssh_key: record<name: string, fingerprint: string>, user_data: string, mac_address: string, manager: record<id: string, type: string>, tpm_enabled: bool, deploy_target: record<id: string>, ipv6_address: string, id: string, snapshots: list<record>, disk_size: int, disk_encrypted: bool, ssh_keys: list<record>, created_at: string, public_ip: string>, application_consistent: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snapshot/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Scale a SKS Nodepool
#
# PUT /sks-cluster/{id}/nodepool/{sks-nodepool-id}:scale
# operationId: scale-sks-nodepool
export def "sks-cluster-nodepool scale-sks-nodepool" [
  id: string
  sks_nodepool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  size: int # Number of instances (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/nodepool/($sks_nodepool_id):scale")
  let body = {size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get DBaaS MySQL settings
#
# GET /dbaas-settings-mysql
# operationId: get-dbaas-settings-mysql
export def "dbaas-settings-mysql get-dbaas-settings-mysql" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<mysql: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-mysql")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upgrade a SKS cluster to pro
#
# PUT /sks-cluster/{id}/upgrade-service-level
# operationId: upgrade-sks-cluster-service-level
export def "sks-cluster-upgrade-service-level upgrade-sks-cluster-service-level" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/upgrade-service-level")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS Valkey settings
#
# GET /dbaas-settings-valkey
# operationId: get-dbaas-settings-valkey
export def "dbaas-settings-valkey get-dbaas-settings-valkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<valkey: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-valkey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an API key
#
# DELETE /api-key/{id}
# operationId: delete-api-key
export def "api-key delete-api-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api-key/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API key
#
# GET /api-key/{id}
# operationId: get-api-key
export def "api-key get-api-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, role_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api-key/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset a Load Balancer Service field to its default value
#
# DELETE /load-balancer/{id}/service/{service-id}/{field}
# operationId: reset-load-balancer-service-field
export def "load-balancer-service reset-load-balancer-service-field" [
  id: string
  service_id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)/service/($service_id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Postgres database
#
# POST /dbaas-postgres/{service-name}/database
# operationId: create-dbaas-pg-database
export def "dbaas-postgres-database create-dbaas-pg-database" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  database_name: string
  --lc-collate: string # Default string sort order (LC_COLLATE) for PostgreSQL database
  --lc-ctype: string # Default character classification (LC_CTYPE) for PostgreSQL database
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/database")
  let body = {database-name: $database_name, lc-collate: $lc_collate, lc-ctype: $lc_ctype} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Rotate Key
#
# POST /kms-key/{id}/rotate
# operationId: rotate-kms-key
export def "kms-key-rotate rotate-kms-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rotation: record<manual_count: int, automatic: bool, rotation_period: int, next_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS Thanos settings
#
# GET /dbaas-settings-thanos
# operationId: get-dbaas-settings-thanos
export def "dbaas-settings-thanos get-dbaas-settings-thanos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<thanos: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-thanos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Security Group rule
#
# POST /security-group/{id}/rules
# operationId: add-rule-to-security-group
# --security-group shape: {name?: string, visibility?: "private"|"public"}
# --icmp shape: {code?: int, type?: int}
export def "security-group-rules add-rule-to-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  flow_direction: string@flow-direction-completer # Network flow direction to match
  --description: string # Security Group rule description
  --network: string # CIDR-formatted network allowed
  --security-group: record # Security Group — shape: {name?: string, visibility?: "private"|"public"}
  protocol: string@protocol-completer-1 # Network protocol
  --icmp: record # ICMP details (default: -1 (ANY)) — shape: {code?: int, type?: int}
  --start-port: int # Start port of the range (format: int64)
  --end-port: int # End port of the range (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id)/rules")
  let body = {flow-direction: $flow_direction, description: $description, network: $network, security-group: $security_group, protocol: $protocol, icmp: $icmp, start-port: $start_port, end-port: $end_port} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a DBaaS OpenSearch user
#
# POST /dbaas-opensearch/{service-name}/user
# operationId: create-dbaas-opensearch-user
export def "dbaas-opensearch-user create-dbaas-opensearch-user" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($service_name)/user")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get DBaaS integration types
#
# GET /dbaas-integration-types
# operationId: list-dbaas-integration-types
export def "dbaas-integration-types list-dbaas-integration-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dbaas_integration_types: table<type: string, source_description: string, source_service_types: list, dest_description: string, dest_service_types: list, settings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-integration-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Retrieve organization environmental impact reports
#
# GET /env-impact/{period}
# operationId: get-env-impact
export def "env-impact get-env-impact" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: table<value: string, amount: float, unit: string>, products: table<value: string, metadata: list, impacts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-impact/($period)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a DBaaS Postgres user
#
# DELETE /dbaas-postgres/{service-name}/user/{username}
# operationId: delete-dbaas-postgres-user
export def "dbaas-postgres-user delete-dbaas-postgres-user" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/user/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set instance destruction protection
#
# PUT /instance/{id}:add-protection
# operationId: add-instance-protection
export def "instance add-instance-protection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):add-protection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update access control for one service user
#
# PUT /dbaas-postgres/{service-name}/user/{username}/allow-replication
# operationId: update-dbaas-postgres-allow-replication
export def "dbaas-postgres-user-allow-replication update-dbaas-postgres-allow-replication" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-replication: string@bool-completer
]: any -> record<users: table<username: string, allow_replication: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/user/($username)/allow-replication")
  let body = {allow-replication: $allow_replication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update IAM Role
#
# PUT /iam-role/{id}
# operationId: update-iam-role
# --assume-role-policy shape: {rules?: list}
export def "iam-role update-iam-role" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # IAM Role description
  --permissions: list # IAM Role permissions
  --labels: record
  --max-session-ttl: int # Maximum TTL requester is allowed to ask for when assuming a role (format: int64)
  --assume-role-policy: record # Assume Role Policy — shape: {rules?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/iam-role/($id)")
  let body = {description: $description, permissions: $permissions, labels: $labels, max-session-ttl: $max_session_ttl, assume-role-policy: $assume_role_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve IAM Role
#
# GET /iam-role/{id}
# operationId: get-iam-role
export def "iam-role get-iam-role" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, labels: record, permissions: list<string>, assume_role_policy: record<rules: list<record>>, editable: bool, name: string, max_session_ttl: int, policy: record<default_service_strategy: string, services: record>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/iam-role/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete IAM Role
#
# DELETE /iam-role/{id}
# operationId: delete-iam-role
export def "iam-role delete-iam-role" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/iam-role/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset Instance field
#
# DELETE /instance/{id}/{field}
# operationId: reset-instance-field
export def "instance reset-instance-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset an Instance Pool field to its default value
#
# DELETE /instance-pool/{id}/{field}
# operationId: reset-instance-pool-field
export def "instance-pool reset-instance-pool-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-pool/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove instance destruction protection
#
# PUT /instance/{id}:remove-protection
# operationId: remove-instance-protection
export def "instance remove-instance-protection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):remove-protection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a Kafka topic ACL entry
#
# POST /dbaas-kafka/{name}/topic/acl-config
# operationId: create-dbaas-kafka-topic-acl-config
export def "dbaas-kafka-topic-acl-config create-dbaas-kafka-topic-acl-config" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  username: string # Kafka username or username pattern
  topic: string # Kafka topic name or pattern
  permission: string@permission-completer-1 # Kafka permission
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)/topic/acl-config")
  let body = {id: $id, username: $username, topic: $topic, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Snapshots
#
# GET /snapshot
# operationId: list-snapshots
export def "snapshot list-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<snapshots: table<id: string, name: string, created_at: string, state: string, size: int, export: record, instance: record, application_consistent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snapshot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Operation details
#
# GET /operation/{id}
# operationId: get-operation
export def "operation get-operation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/operation/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve DNS domain zone file
#
# GET /dns-domain/{id}/zone
# operationId: get-dns-domain-zone-file
export def "dns-domain-zone get-dns-domain-zone-file" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<zone_file: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($id)/zone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create OpenSearch Logs external integration endpoint
#
# POST /dbaas-external-endpoint-opensearch/{name}
# operationId: create-dbaas-external-endpoint-opensearch
# --settings shape: {ca?: string, url: string, index-prefix: string, index-days-max?: int, timeout?: int}
export def "dbaas-external-endpoint-opensearch create-dbaas-external-endpoint-opensearch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {ca?: string, url: string, index-prefix: string, index-days-max?: int, timeout?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-opensearch/($name)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a DBaaS MySQL database
#
# DELETE /dbaas-mysql/{service-name}/database/{database-name}
# operationId: delete-dbaas-mysql-database
export def "dbaas-mysql-database delete-dbaas-mysql-database" [
  service_name: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($service_name)/database/($database_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an external source from a Security Group
#
# PUT /security-group/{id}:remove-source
# operationId: remove-external-source-from-security-group
export def "security-group remove-external-source-from-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cidr: string # CIDR-formatted network to remove
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id):remove-source")
  let body = {cidr: $cidr} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve IAM Organization Policy
#
# GET /iam-organization-policy
# operationId: get-iam-organization-policy
export def "iam-organization-policy get-iam-organization-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<default_service_strategy: string, services: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iam-organization-policy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update IAM Organization Policy
#
# PUT /iam-organization-policy
# operationId: update-iam-organization-policy
export def "iam-organization-policy update-iam-organization-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  default_service_strategy: string@default-service-strategy-completer # IAM default service strategy
  services: record # IAM services
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iam-organization-policy")
  let body = {default-service-strategy: $default_service_strategy, services: $services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get logs of DBaaS service
#
# POST /dbaas-service-logs/{service-name}
# operationId: get-dbaas-service-logs
export def "dbaas-service-logs get-dbaas-service-logs" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # How many log entries to receive at most, up to 500 (default: 100) (format: int64)
  --sort-order: string@sort-order-completer
  --offset: string # Opaque offset identifier
]: any -> record<offset: string, first_log_offset: string, logs: table<unit: string, time: string, message: string, node: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-service-logs/($service_name)")
  let body = {limit: $limit, sort-order: $sort_order, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Decrypt
#
# POST /kms-key/{id}/decrypt
# operationId: decrypt
export def "kms-key-decrypt decrypt" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encryption-context: string # nullable, format: byte
  ciphertext: string # format: byte
]: any -> record<plaintext: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/decrypt")
  let body = {encryption-context: $encryption_context, ciphertext: $ciphertext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Template
#
# DELETE /template/{id}
# operationId: delete-template
export def "template delete-template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a Template from a zone to another
#
# POST /template/{id}
# operationId: copy-template
# --target-zone shape: {name?: "ch-dk-2"|"de-muc-1"|"ch-gva-2"|"at-vie-1"|"de-fra-1"|"bg-sof-1"|"at-vie-2"|"hr-zag-1"}
export def "template copy-template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  target_zone: record # Zone — shape: {name?: "ch-dk-2"|"de-muc-1"|"ch-gva-2"|"at-vie-1"|"de-fra-1"|"bg-sof-1"|"at-vie-2"|"hr-zag-1"}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/($id)")
  let body = {target-zone: $target_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update template attributes
#
# PUT /template/{id}
# operationId: update-template
export def "template update-template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Template name
  --description: string # Template Description
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Template details
#
# GET /template/{id}
# operationId: get-template
export def "template get-template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_consistent_snapshot_enabled: bool, maintainer: string, description: string, ssh_key_enabled: bool, family: string, name: string, default_user: string, size: int, password_enabled: bool, build: string, checksum: string, boot_mode: string, id: string, zones: list<string>, url: string, version: string, created_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate PostgreSQL maintenance update
#
# PUT /dbaas-postgres/{name}/maintenance/start
# operationId: start-dbaas-pg-maintenance
export def "dbaas-postgres-maintenance-start start-dbaas-pg-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal the secrets of a DBaaS Grafana user
#
# GET /dbaas-grafana/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-grafana-user-password
export def "dbaas-grafana-user-password-reveal reveal-dbaas-grafana-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a User's IAM role
#
# PUT /user/{id}
# operationId: update-user-role
# --role shape: {description?: string, labels?: record, permissions?: list, assume-role-policy?: record, editable?: bool, name?: string, max-session-ttl?: int, policy?: record}
export def "user update-user-role" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: record # IAM Role — shape: {description?: string, labels?: record, permissions?: list, assume-role-policy?: record, editable?: bool, name?: string, max-session-ttl?: int, policy?: record}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User
#
# DELETE /user/{id}
# operationId: delete-user
export def "user delete-user" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update/Create the PTR DNS record for an instance
#
# POST /reverse-dns/instance/{id}
# operationId: update-reverse-dns-instance
export def "reverse-dns-instance update-reverse-dns-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain-name: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reverse-dns/instance/($id)")
  let body = {domain-name: $domain_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query the PTR DNS records for an instance
#
# GET /reverse-dns/instance/{id}
# operationId: get-reverse-dns-instance
export def "reverse-dns-instance get-reverse-dns-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reverse-dns/instance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the PTR DNS record for an instance
#
# DELETE /reverse-dns/instance/{id}
# operationId: delete-reverse-dns-instance
export def "reverse-dns-instance delete-reverse-dns-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reverse-dns/instance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evict Instance Pool members
#
# PUT /instance-pool/{id}:evict
# operationId: evict-instance-pool-members
export def "instance-pool evict-instance-pool-members" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --instances: list
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance-pool/($id):evict")
  let body = {instances: $instances} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate Exoscale CSI credentials
#
# PUT /sks-cluster/{id}/rotate-csi-credentials
# operationId: rotate-sks-csi-credentials
export def "sks-cluster-rotate-csi-credentials rotate-sks-csi-credentials" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/rotate-csi-credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset the credentials of a DBaaS Grafana user
#
# PUT /dbaas-grafana/{service-name}/user/{username}/password/reset
# operationId: reset-dbaas-grafana-user-password
export def "dbaas-grafana-user-password-reset reset-dbaas-grafana-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($service_name)/user/($username)/password/reset")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detach a Compute instance from a Security Group
#
# PUT /security-group/{id}:detach
# operationId: detach-instance-from-security-group
# --instance shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, private-networks?: list, template?: record, state?: "expunging"|"starting"|"destroying"|"running"|"stopping"|"stopped"|"migrating"|"error"|"destroyed", secureboot-enabled?: bool, ssh-key?: record, user-data?: string, manager?: record, tpm-enabled?: bool, deploy-target?: record, snapshots?: list, disk-size?: int, ssh-keys?: list}
export def "security-group detach-instance-from-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance: record # Instance — shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, private-networks?: list, template?: record, state?: "expunging"|"starting"|"destroying"|"running"|"stopping"|"stopped"|"migrating"|"error"|"destroyed", secureboot-enabled?: bool, ssh-key?: record, user-data?: string, manager?: record, tpm-enabled?: bool, deploy-target?: record, snapshots?: list, disk-size?: int, ssh-keys?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id):detach")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evict Nodepool members
#
# PUT /sks-cluster/{id}/nodepool/{sks-nodepool-id}:evict
# operationId: evict-sks-nodepool-members
export def "sks-cluster-nodepool evict-sks-nodepool-members" [
  id: string
  sks_nodepool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --instances: list
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/nodepool/($sks_nodepool_id):evict")
  let body = {instances: $instances} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update access control for one DBaaS Valkey service user
#
# PUT /dbaas-valkey/{service-name}/user/{username}
# operationId: update-dbaas-valkey-user-access-control
# --access-control shape: {categories?: list, channels?: list, commands?: list, keys?: list}
export def "dbaas-valkey-user update-dbaas-valkey-user-access-control" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-control: record # shape: {categories?: list, channels?: list, commands?: list, keys?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($service_name)/user/($username)")
  let body = {access-control: $access_control} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a DBaaS Valkey user
#
# DELETE /dbaas-valkey/{service-name}/user/{username}
# operationId: delete-dbaas-valkey-user
export def "dbaas-valkey-user delete-dbaas-valkey-user" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($service_name)/user/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Disable KMS Key
#
# POST /kms-key/{id}/disable
# operationId: disable-kms-key
export def "kms-key-disable disable-kms-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Kafka ACL entry
#
# DELETE /dbaas-kafka/{name}/schema-registry/acl-config/{acl-id}
# operationId: delete-dbaas-kafka-schema-registry-acl-config
export def "dbaas-kafka-schema-registry-acl-config delete-dbaas-kafka-schema-registry-acl-config" [
  name: string
  acl_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)/schema-registry/acl-config/($acl_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete DNS Domain
#
# DELETE /dns-domain/{id}
# operationId: delete-dns-domain
export def "dns-domain delete-dns-domain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve DNS domain details
#
# GET /dns-domain/{id}
# operationId: get-dns-domain
export def "dns-domain get-dns-domain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: string, unicode_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dns-domain/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resize a block storage volume
#
# PUT /block-storage/{id}:resize-volume
# operationId: resize-block-storage-volume
export def "block-storage resize-block-storage-volume" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  size: int # Volume size in GiB (format: int64)
]: any -> record<labels: record, instance: record<id: string>, name: string, state: string, size: int, blocksize: int, block_storage_snapshots: table<id: string>, id: string, encrypted: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id):resize-volume")
  let body = {size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a DBaaS kafka user
#
# DELETE /dbaas-kafka/{service-name}/user/{username}
# operationId: delete-dbaas-kafka-user
export def "dbaas-kafka-user delete-dbaas-kafka-user" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($service_name)/user/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a DBaaS service type
#
# GET /dbaas-service-type/{service-type-name}
# operationId: get-dbaas-service-type
export def "dbaas-service-type get-dbaas-service-type" [
  service_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, available_versions: list<string>, default_version: string, description: string, plans: table<node_count: int, backup_config: record, node_cpu_count: int, family: string, disk_space: int, authorized: bool, name: string, max_memory_percent: int, zones: list, node_memory: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-service-type/($service_type_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an external source as a member of a Security Group
#
# PUT /security-group/{id}:add-source
# operationId: add-external-source-to-security-group
export def "security-group add-external-source-to-security-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cidr: string # CIDR-formatted network to add
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security-group/($id):add-source")
  let body = {cidr: $cidr} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Create DataDog external integration endpoint
#
# POST /dbaas-external-endpoint-datadog/{name}
# operationId: create-dbaas-external-endpoint-datadog
# --settings shape: {datadog-api-key: string, site: "us3.datadoghq.com"|"ddog-gov.com"|"datadoghq.eu"|"us5.datadoghq.com"|"ap1.datadoghq.com"|"datadoghq.com", datadog-tags?: list, disable-consumer-stats?: bool, kafka-consumer-check-instances?: int, kafka-consumer-stats-timeout?: int, max-partition-contexts?: int}
export def "dbaas-external-endpoint-datadog create-dbaas-external-endpoint-datadog" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {datadog-api-key: string, site: "us3.datadoghq.com"|"ddog-gov.com"|"datadoghq.eu"|"us5.datadoghq.com"|"ap1.datadoghq.com"|"datadoghq.com", datadog-tags?: list, disable-consumer-stats?: bool, kafka-consumer-check-instances?: int, kafka-consumer-stats-timeout?: int, max-partition-contexts?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-datadog/($name)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initiate MySQL maintenance update
#
# PUT /dbaas-mysql/{name}/maintenance/start
# operationId: start-dbaas-mysql-maintenance
export def "dbaas-mysql-maintenance-start start-dbaas-mysql-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset the credentials of a DBaaS OpenSearch user
#
# PUT /dbaas-opensearch/{service-name}/user/{username}/password/reset
# operationId: reset-dbaas-opensearch-user-password
export def "dbaas-opensearch-user-password-reset reset-dbaas-opensearch-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($service_name)/user/($username)/password/reset")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Model
#
# DELETE /ai/model/{id}
# operationId: delete-model
export def "ai-model delete-model" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/model/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model
#
# GET /ai/model/{id}
# operationId: get-model
export def "ai-model get-model" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, name: string, state: string, id: string, model_size: int, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/model/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SOS Buckets Usage
#
# GET /sos-buckets-usage
# operationId: list-sos-buckets-usage
export def "sos-buckets-usage list-sos-buckets-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sos_buckets_usage: table<name: string, created_at: string, zone_name: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sos-buckets-usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset a Compute instance to a base/target template
#
# PUT /instance/{id}:reset
# operationId: reset-instance
# --template shape: {id?: string}
export def "instance reset-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template: record # Template reference — shape: {id?: string}
  --disk-size: int # Instance disk size in GiB (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):reset")
  let body = {template: $template, disk-size: $disk_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reveal the secrets of a DBaaS MySQL user
#
# GET /dbaas-mysql/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-mysql-user-password
export def "dbaas-mysql-user-password-reveal reveal-dbaas-mysql-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a SSH key
#
# DELETE /ssh-key/{name}
# operationId: delete-ssh-key
export def "ssh-key delete-ssh-key" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ssh-key/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve SSH key details
#
# GET /ssh-key/{name}
# operationId: get-ssh-key
export def "ssh-key get-ssh-key" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ssh-key/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics of DBaaS service
#
# POST /dbaas-service-metrics/{service-name}
# operationId: get-dbaas-service-metrics
export def "dbaas-service-metrics get-dbaas-service-metrics" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string@period-completer # Metrics time period (default: hour)
]: any -> record<metrics: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-service-metrics/($service_name)")
  let body = {period: $period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Deploy Target details
#
# GET /deploy-target/{id}
# operationId: get-deploy-target
export def "deploy-target get-deploy-target" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deploy-target/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detach a Compute instance from an Elastic IP
#
# PUT /elastic-ip/{id}:detach
# operationId: detach-instance-from-elastic-ip
# --instance shape: {id?: string}
export def "elastic-ip detach-instance-from-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance: record # Target Instance — shape: {id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/elastic-ip/($id):detach")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Temporarily enable writes for MySQL services in read-only mode due to filled up storage
#
# PUT /dbaas-mysql/{name}/enable/writes
# operationId: enable-dbaas-mysql-writes
export def "dbaas-mysql-enable-writes enable-dbaas-mysql-writes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)/enable/writes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal the secrets of a DBaaS Kafka user
#
# GET /dbaas-kafka/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-kafka-user-password
export def "dbaas-kafka-user-password-reveal reveal-dbaas-kafka-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string, access_cert: string, access_cert_expiry: string, access_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Encrypt
#
# POST /kms-key/{id}/encrypt
# operationId: encrypt
export def "kms-key-encrypt encrypt" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encryption-context: string # nullable, format: byte
  plaintext: string # format: byte
]: any -> record<ciphertext: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/encrypt")
  let body = {encryption-context: $encryption_context, plaintext: $plaintext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a DBaaS task to check migration
#
# POST /dbaas-task-migration-check/{service}
# operationId: create-dbaas-task-migration-check
export def "dbaas-task-migration-check create-dbaas-task-migration-check" [
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_service_uri: string # Service URI of the source MySQL or PostgreSQL database with admin credentials.
  --method: string@method-completer
  --ignore-dbs: string # Comma-separated list of databases, which should be ignored during migration (supported by MySQL only at the moment)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-task-migration-check/($service)")
  let body = {source-service-uri: $source_service_uri, method: $method, ignore-dbs: $ignore_dbs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete DataDog external integration endpoint
#
# DELETE /dbaas-external-endpoint-datadog/{endpoint-id}
# operationId: delete-dbaas-external-endpoint-datadog
export def "dbaas-external-endpoint-datadog delete-dbaas-external-endpoint-datadog" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-datadog/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get DataDog external endpoint settings
#
# GET /dbaas-external-endpoint-datadog/{endpoint-id}
# operationId: get-dbaas-external-endpoint-datadog
export def "dbaas-external-endpoint-datadog get-dbaas-external-endpoint-datadog" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, id: string, settings: record<site: string, datadog_tags: list<record>, disable_consumer_stats: bool, kafka_consumer_check_instances: int, kafka_consumer_stats_timeout: int, max_partition_contexts: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-datadog/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update DataDog external integration endpoint
#
# PUT /dbaas-external-endpoint-datadog/{endpoint-id}
# operationId: update-dbaas-external-endpoint-datadog
# --settings shape: {datadog-api-key: string, site?: "us3.datadoghq.com"|"ddog-gov.com"|"datadoghq.eu"|"us5.datadoghq.com"|"ap1.datadoghq.com"|"datadoghq.com", datadog-tags?: list, disable-consumer-stats?: bool, kafka-consumer-check-instances?: int, kafka-consumer-stats-timeout?: int, max-partition-contexts?: int}
export def "dbaas-external-endpoint-datadog update-dbaas-external-endpoint-datadog" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {datadog-api-key: string, site?: "us3.datadoghq.com"|"ddog-gov.com"|"datadoghq.eu"|"us5.datadoghq.com"|"ap1.datadoghq.com"|"datadoghq.com", datadog-tags?: list, disable-consumer-stats?: bool, kafka-consumer-check-instances?: int, kafka-consumer-stats-timeout?: int, max-partition-contexts?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-datadog/($endpoint_id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a Load Balancer Service
#
# POST /load-balancer/{id}/service
# operationId: add-service-to-load-balancer
# --instance-pool shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, description?: string, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, min-available?: int, private-networks?: list, template?: record, size?: int, ssh-key?: record, instance-prefix?: string, user-data?: string, manager?: record, deploy-target?: record, ipv6-enabled?: bool, disk-size?: int, ssh-keys?: list}
# --healthcheck shape: {mode?: "tcp"|"http"|"https", interval?: int, uri?: string, port?: int, timeout?: int, retries?: int, tls-sni?: string}
export def "load-balancer-service add-service-to-load-balancer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Load Balancer Service name
  --description: string # Load Balancer Service description
  instance_pool: record # Instance Pool — shape: {application-consistent-snapshot-enabled?: bool, anti-affinity-groups?: list, description?: string, public-ip-assignment?: "inet4"|"dual"|"none", labels?: record, security-groups?: list, elastic-ips?: list, name?: string, instance-type?: record, min-available?: int, private-networks?: list, template?: record, size?: int, ssh-key?: record, instance-prefix?: string, user-data?: string, manager?: record, deploy-target?: record, ipv6-enabled?: bool, disk-size?: int, ssh-keys?: list}
  protocol: string@protocol-completer # Network traffic protocol
  strategy: string@strategy-completer # Load balancing strategy
  port: int # Port exposed on the Load Balancer's public IP (format: int64)
  target_port: int # Port on which the network traffic will be forwarded to on the receiving instance (format: int64)
  healthcheck: record # Load Balancer Service healthcheck — shape: {mode?: "tcp"|"http"|"https", interval?: int, uri?: string, port?: int, timeout?: int, retries?: int, tls-sni?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)/service")
  let body = {name: $name, description: $description, instance-pool: $instance_pool, protocol: $protocol, strategy: $strategy, port: $port, target-port: $target_port, healthcheck: $healthcheck} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List SSH keys
#
# GET /ssh-key
# operationId: list-ssh-keys
export def "ssh-key list-ssh-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ssh_keys: table<name: string, fingerprint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssh-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import SSH key
#
# POST /ssh-key
# operationId: register-ssh-key
export def "ssh-key register-ssh-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # SSH key name
  public_key: string # Public key value
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssh-key")
  let body = {name: $name, public-key: $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Promote a Snapshot to a Template
#
# POST /snapshot/{id}:promote
# operationId: promote-snapshot-to-template
export def "snapshot promote-snapshot-to-template" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Template name
  --description: string # Template description
  --default-user: string # Template default user
  --ssh-key-enabled: string@bool-completer # Enable SSH key-based login in the template
  --password-enabled: string@bool-completer # Enable password-based login in the template
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snapshot/($id):promote")
  let body = {name: $name, description: $description, default-user: $default_user, ssh-key-enabled: $ssh_key_enabled, password-enabled: $password_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an SKS cluster
#
# POST /sks-cluster
# operationId: create-sks-cluster
# --networking shape: {cluster-cidr?: string, service-cluster-ip-range?: string, node-cidr-mask-size-ipv4?: int, node-cidr-mask-size-ipv6?: int}
# --oidc shape: {client-id: string, issuer-url: string, username-claim?: string, username-prefix?: string, groups-claim?: string, groups-prefix?: string, required-claim?: record}
# --audit shape: {endpoint: string, bearer-token: string, initial-backoff?: string}
export def "sks-cluster create-sks-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Cluster description (nullable)
  --labels: record
  --cni: string@cni-completer # Cluster CNI
  --auto-upgrade: string@bool-completer # Enable auto upgrade of the control plane to the latest patch version available
  --networking: record # Cluster networking configuration. — shape: {cluster-cidr?: string, service-cluster-ip-range?: string, node-cidr-mask-size-ipv4?: int, node-cidr-mask-size-ipv6?: int}
  --oidc: record # SKS Cluster OpenID config map — shape: {client-id: string, issuer-url: string, username-claim?: string, username-prefix?: string, groups-claim?: string, groups-prefix?: string, required-claim?: record}
  name: string # Cluster name
  --create-default-security-group: string@bool-completer # Creates an ad-hoc security group based on the choice of the selected CNI (nullable)
  --enable-kube-proxy: string@bool-completer # Indicates whether to deploy the Kubernetes network proxy. When unspecified, defaults to `true` unless Cilium CNI is selected
  level: string@level-completer # Cluster service level
  --feature-gates: list # A list of Kubernetes-only Alpha features to enable for API server component
  --addons: list # Cluster addons
  --audit: record # Kubernetes Audit parameters — shape: {endpoint: string, bearer-token: string, initial-backoff?: string}
  version: string # Control plane Kubernetes version
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sks-cluster")
  let body = {description: $description, labels: $labels, cni: $cni, auto-upgrade: $auto_upgrade, networking: $networking, oidc: $oidc, name: $name, create-default-security-group: $create_default_security_group, enable-kube-proxy: $enable_kube_proxy, level: $level, feature-gates: $feature_gates, addons: $addons, audit: $audit, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List SKS clusters
#
# GET /sks-cluster
# operationId: list-sks-clusters
export def "sks-cluster list-sks-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sks_clusters: table<description: string, labels: record, cni: string, auto_upgrade: bool, name: string, enable_operators_ca: bool, default_security_group_id: string, state: string, enable_kube_proxy: bool, nodepools: list, level: string, feature_gates: list, addons: list, id: string, audit: record, version: string, created_at: string, endpoint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sks-cluster")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detach block storage volume
#
# PUT /block-storage/{id}:detach
# operationId: detach-block-storage-volume
export def "block-storage detach-block-storage-volume" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/block-storage/($id):detach")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create Prometheus external integration endpoint
#
# POST /dbaas-external-endpoint-prometheus/{name}
# operationId: create-dbaas-external-endpoint-prometheus
# --settings shape: {basic-auth-password?: string, basic-auth-username?: string}
export def "dbaas-external-endpoint-prometheus create-dbaas-external-endpoint-prometheus" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {basic-auth-password?: string, basic-auth-username?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-prometheus/($name)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve signed url valid for 60 seconds to connect via console-proxy websocket to VM VNC console.
#
# GET /console/{id}
# operationId: get-console-proxy-url
export def "console get-console-proxy-url" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string, host: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/console/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Delete a DBaaS Integration
#
# DELETE /dbaas-integration/{id}
# operationId: delete-dbaas-integration
export def "dbaas-integration delete-dbaas-integration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-integration/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update a existing DBaaS integration
#
# PUT /dbaas-integration/{id}
# operationId: update-dbaas-integration
export def "dbaas-integration update-dbaas-integration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: record # Integration settings
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-integration/($id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get a DBaaS Integration
#
# GET /dbaas-integration/{id}
# operationId: get-dbaas-integration
export def "dbaas-integration get-dbaas-integration" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-integration/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach a Compute instance to an Elastic IP
#
# PUT /elastic-ip/{id}:attach
# operationId: attach-instance-to-elastic-ip
# --instance shape: {id?: string}
export def "elastic-ip attach-instance-to-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instance: record # Target Instance — shape: {id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/elastic-ip/($id):attach")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SKS cluster
#
# DELETE /sks-cluster/{id}
# operationId: delete-sks-cluster
export def "sks-cluster delete-sks-cluster" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve SKS cluster details
#
# GET /sks-cluster/{id}
# operationId: get-sks-cluster
export def "sks-cluster get-sks-cluster" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, labels: record, cni: string, auto_upgrade: bool, name: string, enable_operators_ca: bool, default_security_group_id: string, state: string, enable_kube_proxy: bool, nodepools: table<anti_affinity_groups: list, description: string, public_ip_assignment: string, labels: record, taints: record, security_groups: list, name: string, instance_type: record, private_networks: list, template: record, state: string, size: int, kubelet_image_gc: record, instance_pool: record, instance_prefix: string, deploy_target: record, addons: list, id: string, disk_size: int, version: string, created_at: string>, level: string, feature_gates: list<string>, addons: list<string>, id: string, audit: record<endpoint: string, enabled: bool, initial_backoff: string>, version: string, created_at: string, endpoint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SKS cluster
#
# PUT /sks-cluster/{id}
# operationId: update-sks-cluster
# --oidc shape: {client-id: string, issuer-url: string, username-claim?: string, username-prefix?: string, groups-claim?: string, groups-prefix?: string, required-claim?: record}
# --audit shape: {endpoint?: string, bearer-token?: string, initial-backoff?: string, enabled?: bool}
export def "sks-cluster update-sks-cluster" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Cluster description (nullable)
  --labels: record
  --auto-upgrade: string@bool-completer # Enable auto upgrade of the control plane to the latest patch version available
  --oidc: record # SKS Cluster OpenID config map — shape: {client-id: string, issuer-url: string, username-claim?: string, username-prefix?: string, groups-claim?: string, groups-prefix?: string, required-claim?: record}
  --name: string # Cluster name
  --enable-operators-ca: string@bool-completer # Add or remove the operators certificate authority (CA) from the list of trusted CAs of the api server. The default value is true
  --feature-gates: list # A list of Kubernetes-only Alpha features to enable for API server component (nullable)
  --addons: list # Cluster addons
  --audit: record # Kubernetes Audit parameters — shape: {endpoint?: string, bearer-token?: string, initial-backoff?: string, enabled?: bool}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)")
  let body = {description: $description, labels: $labels, auto-upgrade: $auto_upgrade, oidc: $oidc, name: $name, enable-operators-ca: $enable_operators_ca, feature-gates: $feature_gates, addons: $addons, audit: $audit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Organization Quotas
#
# GET /quota
# operationId: list-quotas
export def "quota list-quotas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<quotas: table<resource: string, usage: int, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get DBaaS integration settings
#
# GET /dbaas-integration-settings/{integration-type}/{source-type}/{dest-type}
# operationId: list-dbaas-integration-settings
export def "dbaas-integration-settings list-dbaas-integration-settings" [
  integration_type: string
  source_type: string
  dest_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<properties: record, additionalProperties: bool, type: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-integration-settings/($integration_type)/($source_type)/($dest_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal the secrets of a DBaaS Thanos user
#
# GET /dbaas-thanos/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-thanos-user-password
export def "dbaas-thanos-user-password-reveal reveal-dbaas-thanos-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-thanos/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS PostgreSQL settings
#
# GET /dbaas-settings-pg
# operationId: get-dbaas-settings-pg
export def "dbaas-settings-pg get-dbaas-settings-pg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<pg: record<properties: record, additionalProperties: bool, type: string, title: string>, pglookout: record<properties: record, additionalProperties: bool, type: string, title: string>, pgbouncer: record<properties: record, additionalProperties: bool, type: string, title: string>, timescaledb: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-pg")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Elastic IP
#
# PUT /elastic-ip/{id}
# operationId: update-elastic-ip
# --healthcheck shape: {strikes-ok?: int, tls-skip-verify?: bool, tls-sni?: string, strikes-fail?: int, mode: "tcp"|"http"|"https", port: int, uri?: string, interval?: int, timeout?: int}
export def "elastic-ip update-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Elastic IP description
  --healthcheck: record # Elastic IP address healthcheck — shape: {strikes-ok?: int, tls-skip-verify?: bool, tls-sni?: string, strikes-fail?: int, mode: "tcp"|"http"|"https", port: int, uri?: string, interval?: int, timeout?: int}
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/elastic-ip/($id)")
  let body = {description: $description, healthcheck: $healthcheck, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Elastic IP details
#
# GET /elastic-ip/{id}
# operationId: get-elastic-ip
export def "elastic-ip get-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, ip: string, addressfamily: string, cidr: string, description: string, healthcheck: record<strikes_ok: int, tls_skip_verify: bool, tls_sni: string, strikes_fail: int, mode: string, port: int, uri: string, interval: int, timeout: int>, labels: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/elastic-ip/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Elastic IP
#
# DELETE /elastic-ip/{id}
# operationId: delete-elastic-ip
export def "elastic-ip delete-elastic-ip" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/elastic-ip/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the latest inspection result
#
# GET /sks-cluster/{id}/inspection
# operationId: get-sks-cluster-inspection
export def "sks-cluster-inspection get-sks-cluster-inspection" [
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
  let full_url = (build-url $base $"/sks-cluster/($id)/inspection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Valkey service
#
# DELETE /dbaas-valkey/{name}
# operationId: delete-dbaas-service-valkey
export def "dbaas-valkey delete-dbaas-service-valkey" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a DBaaS Valkey service
#
# GET /dbaas-valkey/{name}
# operationId: get-dbaas-service-valkey
export def "dbaas-valkey get-dbaas-service-valkey" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, node_count: int, connection_info: record<uri: list<string>, password: string, slave: list<string>>, node_cpu_count: int, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, type: string, state: string, valkey_settings: record<ssl: bool, lfu_log_factor: int, frequent_snapshots: bool, maxmemory_policy: string, io_threads: int, lfu_decay_time: int, pubsub_client_output_buffer_limit: int, active_expire_effort: int, notify_keyspace_events: string, persistence: string, timeout: int, acl_channels_default: string, number_of_databases: int>, ip_filter: list<string>, backups: table<backup_name: string, backup_time: string, data_size: int>, termination_protection: bool, notifications: table<level: string, message: string, type: string, metadata: record>, components: table<component: string, host: string, port: int, route: string, ssl: bool, usage: string>, maintenance: record<dow: string, time: string, updates: list<record>>, disk_size: int, node_memory: int, uri: string, uri_params: record, version: string, created_at: string, plan: string, users: table<type: string, username: string, password: string, access_control: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Valkey service
#
# POST /dbaas-valkey/{name}
# operationId: create-dbaas-service-valkey
# --valkey-settings shape: {ssl?: bool, lfu_log_factor?: int, frequent_snapshots?: bool, maxmemory_policy?: "noeviction"|"allkeys-lru"|"volatile-lru"|"allkeys-random"|"volatile-random"|"volatile-ttl"|"volatile-lfu"|"allkeys-lfu", io_threads?: int, lfu_decay_time?: int, pubsub_client_output_buffer_limit?: int, active_expire_effort?: int, notify_keyspace_events?: string, persistence?: "off"|"rdb", timeout?: int, acl_channels_default?: "allchannels"|"resetchannels", number_of_databases?: int}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --migration shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
export def "dbaas-valkey create-dbaas-service-valkey" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --valkey-settings: record # shape: {ssl?: bool, lfu_log_factor?: int, frequent_snapshots?: bool, maxmemory_policy?: "noeviction"|"allkeys-lru"|"volatile-lru"|"allkeys-random"|"volatile-random"|"volatile-ttl"|"volatile-lfu"|"allkeys-lfu", io_threads?: int, lfu_decay_time?: int, pubsub_client_output_buffer_limit?: int, active_expire_effort?: int, notify_keyspace_events?: string, persistence?: "off"|"rdb", timeout?: int, acl_channels_default?: "allchannels"|"resetchannels", number_of_databases?: int}
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --fork-from-service: string
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --version: string # Valkey major version
  --recovery-backup-name: string # Name of a backup to recover from for services that support backup names
  plan: string # Subscription plan
  --migration: record # Migrate data from existing server — shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($name)")
  let body = {valkey-settings: $valkey_settings, ip-filter: $ip_filter, termination-protection: $termination_protection, fork-from-service: $fork_from_service, maintenance: $maintenance, version: $version, recovery-backup-name: $recovery_backup_name, plan: $plan, migration: $migration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a DBaaS Valkey service
#
# PUT /dbaas-valkey/{name}
# operationId: update-dbaas-service-valkey
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --migration shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
# --valkey-settings shape: {ssl?: bool, lfu_log_factor?: int, frequent_snapshots?: bool, maxmemory_policy?: "noeviction"|"allkeys-lru"|"volatile-lru"|"allkeys-random"|"volatile-random"|"volatile-ttl"|"volatile-lfu"|"allkeys-lfu", io_threads?: int, lfu_decay_time?: int, pubsub_client_output_buffer_limit?: int, active_expire_effort?: int, notify_keyspace_events?: string, persistence?: "off"|"rdb", timeout?: int, acl_channels_default?: "allchannels"|"resetchannels", number_of_databases?: int}
export def "dbaas-valkey update-dbaas-service-valkey" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --plan: string # Subscription plan
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --migration: record # Migrate data from existing server — shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
  --valkey-settings: record # shape: {ssl?: bool, lfu_log_factor?: int, frequent_snapshots?: bool, maxmemory_policy?: "noeviction"|"allkeys-lru"|"volatile-lru"|"allkeys-random"|"volatile-random"|"volatile-ttl"|"volatile-lfu"|"allkeys-lfu", io_threads?: int, lfu_decay_time?: int, pubsub_client_output_buffer_limit?: int, active_expire_effort?: int, notify_keyspace_events?: string, persistence?: "off"|"rdb", timeout?: int, acl_channels_default?: "allchannels"|"resetchannels", number_of_databases?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($name)")
  let body = {maintenance: $maintenance, plan: $plan, termination-protection: $termination_protection, ip-filter: $ip_filter, migration: $migration, valkey-settings: $valkey_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Compute instance
#
# DELETE /instance/{id}
# operationId: delete-instance
export def "instance delete-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Compute instance
#
# PUT /instance/{id}
# operationId: update-instance
export def "instance update-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Instance name
  --user-data: string # Instance Cloud-init user-data (base64 encoded)
  --public-ip-assignment: string@public-ip-assignment-completer
  --labels: record
  --application-consistent-snapshot-enabled: string@bool-completer # Enable/Disable Application Consistent Snapshot for Instance
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id)")
  let body = {name: $name, user-data: $user_data, public-ip-assignment: $public_ip_assignment, labels: $labels, application-consistent-snapshot-enabled: $application_consistent_snapshot_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Compute instance details
#
# GET /instance/{id}
# operationId: get-instance
export def "instance get-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_consistent_snapshot_enabled: bool, anti_affinity_groups: table<id: string>, public_ip_assignment: string, labels: record, security_groups: table<id: string>, elastic_ips: table<id: string>, name: string, instance_type: record<id: string, size: string, family: string, cpus: int, gpus: int, authorized: bool, memory: int, zones: list<string>>, private_networks: table<id: string, mac_address: string>, template: record<application_consistent_snapshot_enabled: bool, maintainer: string, description: string, ssh_key_enabled: bool, family: string, name: string, default_user: string, size: int, password_enabled: bool, build: string, checksum: string, boot_mode: string, id: string, zones: list<string>, url: string, version: string, created_at: string, visibility: string>, state: string, secureboot_enabled: bool, ssh_key: record<name: string, fingerprint: string>, user_data: string, mac_address: string, manager: record<id: string, type: string>, tpm_enabled: bool, deploy_target: record<id: string>, ipv6_address: string, id: string, snapshots: table<id: string>, disk_size: int, disk_encrypted: bool, ssh_keys: table<name: string, fingerprint: string>, created_at: string, public_ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a DBaaS MySQL migration
#
# POST /dbaas-mysql/{name}/migration/stop
# operationId: stop-dbaas-mysql-migration
export def "dbaas-mysql-migration-stop stop-dbaas-mysql-migration" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($name)/migration/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] List available external endpoints for integrations
#
# GET /dbaas-external-endpoints
# operationId: list-dbaas-external-endpoints
export def "dbaas-external-endpoints list-dbaas-external-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dbaas_endpoints: table<name: string, type: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-external-endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Kafka maintenance update
#
# PUT /dbaas-kafka/{name}/maintenance/start
# operationId: start-dbaas-kafka-maintenance
export def "dbaas-kafka-maintenance-start start-dbaas-kafka-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Exoscale CCM credentials
#
# PUT /sks-cluster/{id}/rotate-ccm-credentials
# operationId: rotate-sks-ccm-credentials
export def "sks-cluster-rotate-ccm-credentials rotate-sks-ccm-credentials" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/rotate-ccm-credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a DBaaS PostgreSQL connection pool
#
# PUT /dbaas-postgres/{service-name}/connection-pool/{connection-pool-name}
# operationId: update-dbaas-pg-connection-pool
export def "dbaas-postgres-connection-pool update-dbaas-pg-connection-pool" [
  service_name: string
  connection_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --database-name: string
  --mode: string@mode-completer
  --size: int # format: int64
  --username: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/connection-pool/($connection_pool_name)")
  let body = {database-name: $database_name, mode: $mode, size: $size, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a DBaaS PostgreSQL connection pool
#
# DELETE /dbaas-postgres/{service-name}/connection-pool/{connection-pool-name}
# operationId: delete-dbaas-pg-connection-pool
export def "dbaas-postgres-connection-pool delete-dbaas-pg-connection-pool" [
  service_name: string
  connection_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/connection-pool/($connection_pool_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create KMS Key
#
# POST /kms-key
# operationId: create-kms-key
export def "kms-key create-kms-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --usage: string@usage-completer # default: encrypt-decrypt
  --multi-zone: string@bool-completer # default: false
]: any -> record<description: string, revision: record<at: string, seq: int>, name: string, multi_zone: bool, source: string, usage: string, status: string, status_since: string, id: string, origin_zone: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kms-key")
  let body = {name: $name, description: $description, usage: $usage, multi-zone: $multi_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] List KMS Keys
#
# GET /kms-key
# operationId: list-kms-keys
export def "kms-key list-kms-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kms_keys: table<description: string, rotation: record, revision: record, name: string, multi_zone: bool, source: string, usage: string, status: string, status_since: string, id: string, replicas: list, material: record, origin_zone: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kms-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a DBaaS Thanos service
#
# GET /dbaas-thanos/{name}
# operationId: get-dbaas-service-thanos
export def "dbaas-thanos get-dbaas-service-thanos" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<updated_at: string, node_count: int, connection_info: record<query_frontend_uri: string, query_uri: string, receiver_remote_write_uri: string, ruler_uri: string>, node_cpu_count: int, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, type: string, state: string, ip_filter: list<string>, backups: table<backup_name: string, backup_time: string, data_size: int>, termination_protection: bool, notifications: table<level: string, message: string, type: string, metadata: record>, components: table<component: string, host: string, port: int, route: string, ssl: bool, usage: string>, maintenance: record<dow: string, time: string, updates: list<record>>, disk_size: int, node_memory: int, uri: string, uri_params: record, thanos_settings: record<compactor: record<retention_days: int>, query: record<query_default_evaluation_interval: string, query_lookback_delta: string, query_metadata_default_time_range: string, query_timeout: string, store_limits_request_samples: int, store_limits_request_series: int>, query_frontend: record<query_range_align_range_with_step: bool>>, created_at: string, plan: string, users: table<type: string, username: string, password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-thanos/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Thanos service
#
# POST /dbaas-thanos/{name}
# operationId: create-dbaas-service-thanos
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --thanos-settings shape: {compactor?: record, query?: record, query-frontend?: record}
export def "dbaas-thanos create-dbaas-service-thanos" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  plan: string # Subscription plan
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --ip-filter: list # Allowed CIDR address blocks for incoming connections
  --thanos-settings: record # shape: {compactor?: record, query?: record, query-frontend?: record}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-thanos/($name)")
  let body = {maintenance: $maintenance, plan: $plan, termination-protection: $termination_protection, ip-filter: $ip_filter, thanos-settings: $thanos_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a DBaaS Thanos service
#
# PUT /dbaas-thanos/{name}
# operationId: update-dbaas-service-thanos
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --thanos-settings shape: {compactor?: record, query?: record, query-frontend?: record}
export def "dbaas-thanos update-dbaas-service-thanos" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --plan: string # Subscription plan
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --ip-filter: list # Allowed CIDR address blocks for incoming connections
  --thanos-settings: record # shape: {compactor?: record, query?: record, query-frontend?: record}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-thanos/($name)")
  let body = {maintenance: $maintenance, plan: $plan, termination-protection: $termination_protection, ip-filter: $ip_filter, thanos-settings: $thanos_settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Thanos service
#
# DELETE /dbaas-thanos/{name}
# operationId: delete-dbaas-service-thanos
export def "dbaas-thanos delete-dbaas-service-thanos" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-thanos/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update IAM Role Policy
#
# PUT /iam-role/{id}:policy
# operationId: update-iam-role-policy
export def "iam-role update-iam-role-policy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  default_service_strategy: string@default-service-strategy-completer # IAM default service strategy
  services: record # IAM services
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/iam-role/($id):policy")
  let body = {default-service-strategy: $default_service_strategy, services: $services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a DBaaS migration status
#
# GET /dbaas-migration-status/{name}
# operationId: get-dbaas-migration-status
export def "dbaas-migration-status get-dbaas-migration-status" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, method: string, status: string, details: table<dbname: string, error: string, method: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-migration-status/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a DBaaS MySQL user
#
# DELETE /dbaas-mysql/{service-name}/user/{username}
# operationId: delete-dbaas-mysql-user
export def "dbaas-mysql-user delete-dbaas-mysql-user" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($service_name)/user/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Karpenter NodePool manifest with minimal configuration for an SKS cluster
#
# PUT /sks-cluster/{id}/generate-karpenter-nodepool
# operationId: generate-sks-karpenter-nodepool
export def "sks-cluster-generate-karpenter-nodepool generate-sks-karpenter-nodepool" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nodepool: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/generate-karpenter-nodepool")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Load Balancer
#
# PUT /load-balancer/{id}
# operationId: update-load-balancer
export def "load-balancer update-load-balancer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Load Balancer name
  --description: string # Load Balancer description
  --labels: record
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)")
  let body = {name: $name, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Load Balancer
#
# DELETE /load-balancer/{id}
# operationId: delete-load-balancer
export def "load-balancer delete-load-balancer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Load Balancer details
#
# GET /load-balancer/{id}
# operationId: get-load-balancer
export def "load-balancer get-load-balancer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, description: string, name: string, state: string, created_at: string, ip: string, services: table<description: string, protocol: string, name: string, state: string, target_port: int, port: int, instance_pool: record, strategy: string, healthcheck: record, id: string, healthcheck_status: list>, labels: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/load-balancer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a DBaaS service
#
# DELETE /dbaas-service/{name}
# operationId: delete-dbaas-service
export def "dbaas-service delete-dbaas-service" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-service/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS MySQL database
#
# POST /dbaas-mysql/{service-name}/database
# operationId: create-dbaas-mysql-database
export def "dbaas-mysql-database create-dbaas-mysql-database" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  database_name: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-mysql/($service_name)/database")
  let body = {database-name: $database_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Templates
#
# GET /template
# operationId: list-templates
export def "template list-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string@visibility-completer
  --family: string
]: nothing -> record<templates: table<application_consistent_snapshot_enabled: bool, maintainer: string, description: string, ssh_key_enabled: bool, family: string, name: string, default_user: string, size: int, password_enabled: bool, build: string, checksum: string, boot_mode: string, id: string, zones: list, url: string, version: string, created_at: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility" $visibility "scalar") (serialize-qp "family" $family "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a Template
#
# POST /template
# operationId: register-template
export def "template register-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application-consistent-snapshot-enabled: string@bool-completer # Template with support for Application Consistent Snapshots
  --maintainer: string # Template maintainer
  --description: string # Template description
  --ssh-key-enabled: string@bool-completer # Enable SSH key-based login
  name: string # Template name
  --default-user: string # Template default user
  --size: int # Template size (format: int64)
  --password-enabled: string@bool-completer # Enable password-based login
  --build: string # Template build
  checksum: string # Template MD5 checksum
  --boot-mode: string@boot-mode-completer # Boot mode (default: legacy)
  --body-url: string # Template source URL
  --version: string # Template version
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/template")
  let body = {application-consistent-snapshot-enabled: $application_consistent_snapshot_enabled, maintainer: $maintainer, description: $description, ssh-key-enabled: $ssh_key_enabled, name: $name, default-user: $default_user, size: $size, password-enabled: $password_enabled, build: $build, checksum: $checksum, boot-mode: $boot_mode, url: $body_url, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reboot a Compute instance
#
# PUT /instance/{id}:reboot
# operationId: reboot-instance
export def "instance reboot-instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($id):reboot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS Kafka settings
#
# GET /dbaas-settings-kafka
# operationId: get-dbaas-settings-kafka
export def "dbaas-settings-kafka get-dbaas-settings-kafka" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<kafka: record<properties: record, additionalProperties: bool, type: string, title: string>, kafka_connect: record<properties: record, additionalProperties: bool, type: string, title: string>, kafka_rest: record<properties: record, additionalProperties: bool, type: string, title: string>, schema_registry: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-kafka")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal the secrets of a DBaaS Postgres user
#
# GET /dbaas-postgres/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-postgres-user-password
export def "dbaas-postgres-user-password-reveal reveal-dbaas-postgres-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset IAM Organization Policy
#
# POST /iam-organization-policy:reset
# operationId: reset-iam-organization-policy
export def "iam-organization-policy-reset reset-iam-organization-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iam-organization-policy:reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS OpenSearch settings
#
# GET /dbaas-settings-opensearch
# operationId: get-dbaas-settings-opensearch
export def "dbaas-settings-opensearch get-dbaas-settings-opensearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<settings: record<opensearch: record<properties: record, additionalProperties: bool, type: string, title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-settings-opensearch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create a new DBaaS connection between a DBaaS service and an external service
#
# PUT /dbaas-external-endpoint/{source-service-name}/attach
# operationId: attach-dbaas-service-to-endpoint
export def "dbaas-external-endpoint-attach attach-dbaas-service-to-endpoint" [
  source_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dest_endpoint_id: string # External endpoint id (format: uuid)
  type: string@type-completer-1
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint/($source_service_name)/attach")
  let body = {dest-endpoint-id: $dest_endpoint_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Schedule KMS Key Deletion
#
# POST /kms-key/{id}/schedule-deletion
# operationId: schedule-kms-key-deletion
export def "kms-key-schedule-deletion schedule-kms-key-deletion" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay-days: int # Number of days to wait until deletion is final. (default: 30)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/schedule-deletion")
  let body = {delay-days: $delay_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Grafana service
#
# DELETE /dbaas-grafana/{name}
# operationId: delete-dbaas-service-grafana
export def "dbaas-grafana delete-dbaas-service-grafana" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a DBaaS Grafana service
#
# GET /dbaas-grafana/{name}
# operationId: get-dbaas-service-grafana
export def "dbaas-grafana get-dbaas-service-grafana" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, updated_at: string, node_count: int, connection_info: record<uri: string, username: string, password: string>, node_cpu_count: int, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, type: string, state: string, grafana_settings: record<allow_embedding: bool, cookie_samesite: string, dashboard_previews_enabled: bool, metrics_enabled: bool, auth_azuread: record<allow_sign_up: bool, allowed_domains: list, allowed_groups: list, auth_url: string, client_id: string, client_secret: string, token_url: string>, alerting_enabled: bool, wal: bool, unified_alerting_enabled: bool, auth_github: record<allow_sign_up: bool, allowed_organizations: list, auto_login: bool, client_id: string, client_secret: string, skip_org_role_sync: bool, team_ids: list>, user_auto_assign_org: bool, dataproxy_send_user_header: bool, google_analytics_ua_id: string, dashboards_versions_to_keep: int, editors_can_admin: bool, smtp_server: record<from_address: string, from_name: string, host: string, password: string, port: int, skip_verify: bool, starttls_policy: string, username: string>, auth_gitlab: record<allow_sign_up: bool, allowed_groups: list, api_url: string, auth_url: string, client_id: string, client_secret: string, token_url: string>, alerting_nodata_or_nullvalues: string, auth_basic_enabled: bool, date_formats: record<default_timezone: string, full_date: string, interval_day: string, interval_hour: string, interval_minute: string, interval_month: string, interval_second: string, interval_year: string>, service_log: bool, disable_gravatar: bool, user_auto_assign_org_role: string, dataproxy_timeout: int, viewers_can_edit: bool, dashboards_min_refresh_interval: string, auth_google: record<allow_sign_up: bool, allowed_domains: list, client_id: string, client_secret: string>, oauth_allow_insecure_email_lookup: bool, alerting_max_annotations_to_keep: int, auth_generic_oauth: record<scopes: list, allowed_domains: list, allowed_organizations: list, token_url: string, name: string, auth_url: string, api_url: string, auto_login: bool, client_id: string, client_secret: string, allow_sign_up: bool>, custom_domain: string, alerting_error_or_timeout: string>, ip_filter: list<string>, backups: table<backup_name: string, backup_time: string, data_size: int>, termination_protection: bool, notifications: table<level: string, message: string, type: string, metadata: record>, components: table<component: string, host: string, port: int, route: string, usage: string>, maintenance: record<dow: string, time: string, updates: list<record>>, disk_size: int, node_memory: int, uri: string, uri_params: record, version: string, created_at: string, plan: string, users: table<type: string, username: string, password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a DBaaS Grafana service
#
# PUT /dbaas-grafana/{name}
# operationId: update-dbaas-service-grafana
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --grafana-settings shape: {allow_embedding?: bool, cookie_samesite?: "lax"|"strict"|"none", dashboard_previews_enabled?: bool, metrics_enabled?: bool, auth_azuread?: record, alerting_enabled?: bool, wal?: bool, unified_alerting_enabled?: bool, auth_github?: record, user_auto_assign_org?: bool, dataproxy_send_user_header?: bool, google_analytics_ua_id?: string, dashboards_versions_to_keep?: int, editors_can_admin?: bool, smtp_server?: record, auth_gitlab?: record, alerting_nodata_or_nullvalues?: "alerting"|"no_data"|"keep_state"|"ok", auth_basic_enabled?: bool, date_formats?: record, service_log?: bool, disable_gravatar?: bool, user_auto_assign_org_role?: "Viewer"|"Admin"|"Editor", dataproxy_timeout?: int, viewers_can_edit?: bool, dashboards_min_refresh_interval?: string, auth_google?: record, oauth_allow_insecure_email_lookup?: bool, alerting_max_annotations_to_keep?: int, auth_generic_oauth?: record, custom_domain?: string, alerting_error_or_timeout?: "alerting"|"keep_state"}
export def "dbaas-grafana update-dbaas-service-grafana" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --plan: string # Subscription plan
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --grafana-settings: record # shape: {allow_embedding?: bool, cookie_samesite?: "lax"|"strict"|"none", dashboard_previews_enabled?: bool, metrics_enabled?: bool, auth_azuread?: record, alerting_enabled?: bool, wal?: bool, unified_alerting_enabled?: bool, auth_github?: record, user_auto_assign_org?: bool, dataproxy_send_user_header?: bool, google_analytics_ua_id?: string, dashboards_versions_to_keep?: int, editors_can_admin?: bool, smtp_server?: record, auth_gitlab?: record, alerting_nodata_or_nullvalues?: "alerting"|"no_data"|"keep_state"|"ok", auth_basic_enabled?: bool, date_formats?: record, service_log?: bool, disable_gravatar?: bool, user_auto_assign_org_role?: "Viewer"|"Admin"|"Editor", dataproxy_timeout?: int, viewers_can_edit?: bool, dashboards_min_refresh_interval?: string, auth_google?: record, oauth_allow_insecure_email_lookup?: bool, alerting_max_annotations_to_keep?: int, auth_generic_oauth?: record, custom_domain?: string, alerting_error_or_timeout?: "alerting"|"keep_state"}
  --ip-filter: list # Allowed CIDR address blocks for incoming connections
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($name)")
  let body = {maintenance: $maintenance, plan: $plan, termination-protection: $termination_protection, grafana-settings: $grafana_settings, ip-filter: $ip_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a DBaaS Grafana service
#
# POST /dbaas-grafana/{name}
# operationId: create-dbaas-service-grafana
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --grafana-settings shape: {allow_embedding?: bool, cookie_samesite?: "lax"|"strict"|"none", dashboard_previews_enabled?: bool, metrics_enabled?: bool, auth_azuread?: record, alerting_enabled?: bool, wal?: bool, unified_alerting_enabled?: bool, auth_github?: record, user_auto_assign_org?: bool, dataproxy_send_user_header?: bool, google_analytics_ua_id?: string, dashboards_versions_to_keep?: int, editors_can_admin?: bool, smtp_server?: record, auth_gitlab?: record, alerting_nodata_or_nullvalues?: "alerting"|"no_data"|"keep_state"|"ok", auth_basic_enabled?: bool, date_formats?: record, service_log?: bool, disable_gravatar?: bool, user_auto_assign_org_role?: "Viewer"|"Admin"|"Editor", dataproxy_timeout?: int, viewers_can_edit?: bool, dashboards_min_refresh_interval?: string, auth_google?: record, oauth_allow_insecure_email_lookup?: bool, alerting_max_annotations_to_keep?: int, auth_generic_oauth?: record, custom_domain?: string, alerting_error_or_timeout?: "alerting"|"keep_state"}
export def "dbaas-grafana create-dbaas-service-grafana" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  plan: string # Subscription plan
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --fork-from-service: string
  --grafana-settings: record # shape: {allow_embedding?: bool, cookie_samesite?: "lax"|"strict"|"none", dashboard_previews_enabled?: bool, metrics_enabled?: bool, auth_azuread?: record, alerting_enabled?: bool, wal?: bool, unified_alerting_enabled?: bool, auth_github?: record, user_auto_assign_org?: bool, dataproxy_send_user_header?: bool, google_analytics_ua_id?: string, dashboards_versions_to_keep?: int, editors_can_admin?: bool, smtp_server?: record, auth_gitlab?: record, alerting_nodata_or_nullvalues?: "alerting"|"no_data"|"keep_state"|"ok", auth_basic_enabled?: bool, date_formats?: record, service_log?: bool, disable_gravatar?: bool, user_auto_assign_org_role?: "Viewer"|"Admin"|"Editor", dataproxy_timeout?: int, viewers_can_edit?: bool, dashboards_min_refresh_interval?: string, auth_google?: record, oauth_allow_insecure_email_lookup?: bool, alerting_max_annotations_to_keep?: int, auth_generic_oauth?: record, custom_domain?: string, alerting_error_or_timeout?: "alerting"|"keep_state"}
  --ip-filter: list # Allowed CIDR address blocks for incoming connections
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-grafana/($name)")
  let body = {maintenance: $maintenance, plan: $plan, termination-protection: $termination_protection, fork-from-service: $fork_from_service, grafana-settings: $grafana_settings, ip-filter: $ip_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete RSyslog external integration endpoint
#
# DELETE /dbaas-external-endpoint-rsyslog/{endpoint-id}
# operationId: delete-dbaas-external-endpoint-rsyslog
export def "dbaas-external-endpoint-rsyslog delete-dbaas-external-endpoint-rsyslog" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-rsyslog/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update RSyslog external integration endpoint
#
# PUT /dbaas-external-endpoint-rsyslog/{endpoint-id}
# operationId: update-dbaas-external-endpoint-rsyslog
# --settings shape: {format?: "custom"|"rfc3164"|"rfc5424", key?: string, logline?: string, server?: string, ca?: string, cert?: string, tls?: bool, port?: int, sd?: string, max-message-size?: int}
export def "dbaas-external-endpoint-rsyslog update-dbaas-external-endpoint-rsyslog" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {format?: "custom"|"rfc3164"|"rfc5424", key?: string, logline?: string, server?: string, ca?: string, cert?: string, tls?: bool, port?: int, sd?: string, max-message-size?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-rsyslog/($endpoint_id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get RSyslog external integration endpoint settings
#
# GET /dbaas-external-endpoint-rsyslog/{endpoint-id}
# operationId: get-dbaas-external-endpoint-rsyslog
export def "dbaas-external-endpoint-rsyslog get-dbaas-external-endpoint-rsyslog" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, id: string, settings: record<server: string, port: int, tls: bool, format: string, logline: string, sd: string, max_message_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-rsyslog/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Karpenter ExoscaleNodeClass manifest for an SKS cluster, including its default security group and feature flags if present
#
# PUT /sks-cluster/{id}/generate-karpenter-exoscale-nodeclass
# operationId: generate-sks-karpenter-exoscale-nodeclass
export def "sks-cluster-generate-karpenter-exoscale-nodeclass generate-sks-karpenter-exoscale-nodeclass" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<exoscale_nodeclass: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/generate-karpenter-exoscale-nodeclass")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new SKS Nodepool
#
# POST /sks-cluster/{id}/nodepool
# operationId: create-sks-nodepool
# --anti-affinity-groups item shape: {id?: string}
# --security-groups item shape: {id?: string}
# --instance-type shape: {id?: string}
# --private-networks item shape: {id?: string}
# --kubelet-image-gc shape: {high-threshold?: int, low-threshold?: int, min-age?: string}
# --deploy-target shape: {id?: string}
export def "sks-cluster-nodepool create-sks-nodepool" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anti-affinity-groups: list # Nodepool Anti-affinity Groups — item shape: {id?: string}
  --description: string # Nodepool description
  --public-ip-assignment: string@public-ip-assignment-completer-1 # Configures public IP assignment of the Instances with:  * IPv4 (`inet4`) addressing only (default); * both IPv4 and IPv6 (`dual`) addressing.
  --labels: record
  --taints: record
  --security-groups: list # Nodepool Security Groups — item shape: {id?: string}
  name: string # Nodepool name, lowercase only
  instance_type: record # Instance type reference — shape: {id?: string}
  --private-networks: list # Nodepool Private Networks — item shape: {id?: string}
  size: int # Number of instances (format: int64)
  --kubelet-image-gc: record # Kubelet image GC options — shape: {high-threshold?: int, low-threshold?: int, min-age?: string}
  --instance-prefix: string # Prefix to apply to instances names (default: pool), lowercase only
  --deploy-target: record # Deploy target reference — shape: {id?: string}
  --addons: list # Nodepool addons
  disk_size: int # Nodepool instances disk size in GiB (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/nodepool")
  let body = {anti-affinity-groups: $anti_affinity_groups, description: $description, public-ip-assignment: $public_ip_assignment, labels: $labels, taints: $taints, security-groups: $security_groups, name: $name, instance-type: $instance_type, private-networks: $private_networks, size: $size, kubelet-image-gc: $kubelet_image_gc, instance-prefix: $instance_prefix, deploy-target: $deploy_target, addons: $addons, disk-size: $disk_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Create ElasticSearch Logs external integration endpoint
#
# POST /dbaas-external-endpoint-elasticsearch/{name}
# operationId: create-dbaas-external-endpoint-elasticsearch
# --settings shape: {ca?: string, url: string, index-prefix: string, index-days-max?: int, timeout?: int}
export def "dbaas-external-endpoint-elasticsearch create-dbaas-external-endpoint-elasticsearch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record # shape: {ca?: string, url: string, index-prefix: string, index-days-max?: int, timeout?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint-elasticsearch/($name)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reveal AI API Key
#
# GET /ai/api-key/{id}/reveal
# operationId: reveal-ai-api-key
export def "ai-api-key-reveal reveal-ai-api-key" [
  id: string
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
  let full_url = (build-url $base $"/ai/api-key/($id)/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate OpenSearch maintenance update
#
# PUT /dbaas-opensearch/{name}/maintenance/start
# operationId: start-dbaas-opensearch-maintenance
export def "dbaas-opensearch-maintenance-start start-dbaas-opensearch-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get DBaaS kafka ACL configuration
#
# GET /dbaas-kafka/{name}/acl-config
# operationId: get-dbaas-kafka-acl-config
export def "dbaas-kafka-acl-config get-dbaas-kafka-acl-config" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<topic_acl: table<id: string, username: string, topic: string, permission: string>, schema_registry_acl: table<id: string, username: string, resource: string, permission: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)/acl-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset the credentials of a DBaaS Kafka user
#
# PUT /dbaas-kafka/{service-name}/user/{username}/password/reset
# operationId: reset-dbaas-kafka-user-password
export def "dbaas-kafka-user-password-reset reset-dbaas-kafka-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($service_name)/user/($username)/password/reset")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI API Keys
#
# GET /ai/api-key
# operationId: list-ai-api-keys
export def "ai-api-key list-ai-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ai_api_keys: table<updated_at: string, name: string, scope: string, id: string, org_uuid: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/api-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create AI API Key
#
# POST /ai/api-key
# operationId: create-ai-api-key
export def "ai-api-key create-ai-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Human-readable name for the AI API key
  scope: string # Key scope: 'public' for all deployments, or a specific deployment UUID
]: any -> record<updated_at: string, name: string, scope: string, id: string, org_uuid: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/api-key")
  let body = {name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Re-encrypt
#
# POST /kms-key/{id}/re-encrypt
# operationId: re-encrypt
# --source shape: {key: string, encryption-context?: string, ciphertext: string}
# --destination shape: {key: string, encryption-context?: string}
export def "kms-key-re-encrypt re-encrypt" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: record # shape: {key: string, encryption-context?: string, ciphertext: string}
  destination: record # shape: {key: string, encryption-context?: string}
]: any -> record<ciphertext: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/re-encrypt")
  let body = {source: $body_source, destination: $destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reveal the secrets of a DBaaS OpenSearch user
#
# GET /dbaas-opensearch/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-opensearch-user-password
export def "dbaas-opensearch-user-password-reveal reveal-dbaas-opensearch-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Valkey maintenance update
#
# PUT /dbaas-valkey/{name}/maintenance/start
# operationId: start-dbaas-valkey-maintenance
export def "dbaas-valkey-maintenance-start start-dbaas-valkey-maintenance" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($name)/maintenance/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS OpenSearch service
#
# POST /dbaas-opensearch/{name}
# operationId: create-dbaas-service-opensearch
# --index-patterns item shape: {max-index-count?: int, sorting-algorithm?: "alphabetical"|"creation_date", pattern?: string}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --index-template shape: {mapping-nested-objects-limit?: int, number-of-replicas?: int, number-of-shards?: int}
# --opensearch-settings shape: {thread_pool_search_throttled_size?: int, thread_pool_analyze_size?: int, thread_pool_get_size?: int, thread_pool_get_queue_size?: int, indices_memory_max_index_buffer_size?: int, indices_recovery_max_concurrent_file_chunks?: int, indices_queries_cache_size?: int, search_backpressure?: record, shard_indexing_pressure?: record, knn_memory_circuit_breaker_enabled?: bool, thread_pool_search_size?: int, indices_memory_min_index_buffer_size?: int, indices_recovery_max_bytes_per_sec?: int, http_max_initial_line_length?: int, enable_security_audit?: bool, thread_pool_write_queue_size?: int, script_max_compilations_rate?: string, search_max_buckets?: int, reindex_remote_whitelist?: list, override_main_response_version?: bool, http_max_header_size?: int, email-sender?: record, indices_fielddata_cache_size?: int, action_destructive_requires_name?: bool, plugins_alerting_filter_by_backend_roles?: bool, indices_memory_index_buffer_size?: int, thread_pool_force_merge_size?: int, auth_failure_listeners?: record, ism-history?: record, cluster_routing_allocation_node_concurrent_recoveries?: int, thread_pool_analyze_queue_size?: int, action_auto_create_index_enabled?: bool, http_max_content_length?: int, thread_pool_write_size?: int, thread_pool_search_queue_size?: int, knn_memory_circuit_breaker_limit?: int, indices_query_bool_max_clause_count?: int, thread_pool_search_throttled_queue_size?: int, cluster_max_shards_per_node?: int}
# --opensearch-dashboards shape: {opensearch-request-timeout?: int, enabled?: bool, max-old-space-size?: int}
export def "dbaas-opensearch create-dbaas-service-opensearch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-index-count: int # Maximum number of indexes to keep before deleting the oldest one (nullable, format: int64)
  --keep-index-refresh-interval: string@bool-completer # Aiven automation resets index.refresh_interval to default value for every index to be sure that indices are always visible to search. If it doesn't fit your case, you can disable this by setting up this flag to true.
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --fork-from-service: string
  --index-patterns: list # Allows you to create glob style patterns and set a max number of indexes matching this pattern you want to keep. Creating indexes exceeding this value will cause the oldest one to get deleted. You could for example create a pattern looking like 'logs.?' and then create index logs.1, logs.2 etc, it will delete logs.1 once you create logs.6. Do note 'logs.?' does not apply to logs.10. Note: Setting max_index_count to 0 will do nothing and the pattern gets ignored. — item shape: {max-index-count?: int, sorting-algorithm?: "alphabetical"|"creation_date", pattern?: string}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --index-template: record # Template settings for all new indexes — shape: {mapping-nested-objects-limit?: int, number-of-replicas?: int, number-of-shards?: int}
  --opensearch-settings: record # shape: {thread_pool_search_throttled_size?: int, thread_pool_analyze_size?: int, thread_pool_get_size?: int, thread_pool_get_queue_size?: int, indices_memory_max_index_buffer_size?: int, indices_recovery_max_concurrent_file_chunks?: int, indices_queries_cache_size?: int, search_backpressure?: record, shard_indexing_pressure?: record, knn_memory_circuit_breaker_enabled?: bool, thread_pool_search_size?: int, indices_memory_min_index_buffer_size?: int, indices_recovery_max_bytes_per_sec?: int, http_max_initial_line_length?: int, enable_security_audit?: bool, thread_pool_write_queue_size?: int, script_max_compilations_rate?: string, search_max_buckets?: int, reindex_remote_whitelist?: list, override_main_response_version?: bool, http_max_header_size?: int, email-sender?: record, indices_fielddata_cache_size?: int, action_destructive_requires_name?: bool, plugins_alerting_filter_by_backend_roles?: bool, indices_memory_index_buffer_size?: int, thread_pool_force_merge_size?: int, auth_failure_listeners?: record, ism-history?: record, cluster_routing_allocation_node_concurrent_recoveries?: int, thread_pool_analyze_queue_size?: int, action_auto_create_index_enabled?: bool, http_max_content_length?: int, thread_pool_write_size?: int, thread_pool_search_queue_size?: int, knn_memory_circuit_breaker_limit?: int, indices_query_bool_max_clause_count?: int, thread_pool_search_throttled_queue_size?: int, cluster_max_shards_per_node?: int}
  --version: string # OpenSearch major version
  --recovery-backup-name: string # Name of a backup to recover from for services that support backup names
  plan: string # Subscription plan
  --opensearch-dashboards: record # OpenSearch Dashboards settings — shape: {opensearch-request-timeout?: int, enabled?: bool, max-old-space-size?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)")
  let body = {max-index-count: $max_index_count, keep-index-refresh-interval: $keep_index_refresh_interval, ip-filter: $ip_filter, termination-protection: $termination_protection, fork-from-service: $fork_from_service, index-patterns: $index_patterns, maintenance: $maintenance, index-template: $index_template, opensearch-settings: $opensearch_settings, version: $version, recovery-backup-name: $recovery_backup_name, plan: $plan, opensearch-dashboards: $opensearch_dashboards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a DBaaS OpenSearch service
#
# GET /dbaas-opensearch/{name}
# operationId: get-dbaas-service-opensearch
export def "dbaas-opensearch get-dbaas-service-opensearch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, max_index_count: int, updated_at: string, node_count: int, connection_info: record<uri: list<string>, username: string, password: string, dashboard_uri: string>, node_cpu_count: int, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, keep_index_refresh_interval: bool, type: string, state: string, ip_filter: list<string>, backups: table<backup_name: string, backup_time: string, data_size: int>, termination_protection: bool, notifications: table<level: string, message: string, type: string, metadata: record>, components: table<component: string, host: string, port: int, route: string, usage: string>, index_patterns: table<max_index_count: int, sorting_algorithm: string, pattern: string>, maintenance: record<dow: string, time: string, updates: list<record>>, index_template: record<mapping_nested_objects_limit: int, number_of_replicas: int, number_of_shards: int>, disk_size: int, node_memory: int, uri: string, opensearch_settings: record<thread_pool_search_throttled_size: int, thread_pool_analyze_size: int, thread_pool_get_size: int, thread_pool_get_queue_size: int, indices_memory_max_index_buffer_size: int, indices_recovery_max_concurrent_file_chunks: int, indices_queries_cache_size: int, search_backpressure: record<mode: string, node_duress: record, search_shard_task: record, search_task: record>, shard_indexing_pressure: record<primary_parameter: record, operating_factor: record, enforced: bool, enabled: bool>, knn_memory_circuit_breaker_enabled: bool, thread_pool_search_size: int, indices_memory_min_index_buffer_size: int, indices_recovery_max_bytes_per_sec: int, http_max_initial_line_length: int, enable_security_audit: bool, thread_pool_write_queue_size: int, script_max_compilations_rate: string, search_max_buckets: int, reindex_remote_whitelist: list<string>, override_main_response_version: bool, http_max_header_size: int, email_sender: record<email_sender_name: string, email_sender_password: string, email_sender_username: string>, indices_fielddata_cache_size: int, action_destructive_requires_name: bool, plugins_alerting_filter_by_backend_roles: bool, indices_memory_index_buffer_size: int, thread_pool_force_merge_size: int, auth_failure_listeners: record<internal_authentication_backend_limiting: record, ip_rate_limiting: record>, ism_history: record<ism_enabled: bool, ism_history_enabled: bool, ism_history_max_age: int, ism_history_max_docs: int, ism_history_rollover_check_period: int, ism_history_rollover_retention_period: int>, cluster_routing_allocation_node_concurrent_recoveries: int, thread_pool_analyze_queue_size: int, action_auto_create_index_enabled: bool, http_max_content_length: int, thread_pool_write_size: int, thread_pool_search_queue_size: int, knn_memory_circuit_breaker_limit: int, indices_query_bool_max_clause_count: int, thread_pool_search_throttled_queue_size: int, cluster_max_shards_per_node: int>, uri_params: record, version: string, created_at: string, plan: string, opensearch_dashboards: record<opensearch_request_timeout: int, enabled: bool, max_old_space_size: int>, users: table<type: string, username: string, password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a OpenSearch service
#
# DELETE /dbaas-opensearch/{name}
# operationId: delete-dbaas-service-opensearch
export def "dbaas-opensearch delete-dbaas-service-opensearch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a DBaaS OpenSearch service
#
# PUT /dbaas-opensearch/{name}
# operationId: update-dbaas-service-opensearch
# --index-patterns item shape: {max-index-count?: int, sorting-algorithm?: "alphabetical"|"creation_date", pattern?: string}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --index-template shape: {mapping-nested-objects-limit?: int, number-of-replicas?: int, number-of-shards?: int}
# --opensearch-settings shape: {thread_pool_search_throttled_size?: int, thread_pool_analyze_size?: int, thread_pool_get_size?: int, thread_pool_get_queue_size?: int, indices_memory_max_index_buffer_size?: int, indices_recovery_max_concurrent_file_chunks?: int, indices_queries_cache_size?: int, search_backpressure?: record, shard_indexing_pressure?: record, knn_memory_circuit_breaker_enabled?: bool, thread_pool_search_size?: int, indices_memory_min_index_buffer_size?: int, indices_recovery_max_bytes_per_sec?: int, http_max_initial_line_length?: int, enable_security_audit?: bool, thread_pool_write_queue_size?: int, script_max_compilations_rate?: string, search_max_buckets?: int, reindex_remote_whitelist?: list, override_main_response_version?: bool, http_max_header_size?: int, email-sender?: record, indices_fielddata_cache_size?: int, action_destructive_requires_name?: bool, plugins_alerting_filter_by_backend_roles?: bool, indices_memory_index_buffer_size?: int, thread_pool_force_merge_size?: int, auth_failure_listeners?: record, ism-history?: record, cluster_routing_allocation_node_concurrent_recoveries?: int, thread_pool_analyze_queue_size?: int, action_auto_create_index_enabled?: bool, http_max_content_length?: int, thread_pool_write_size?: int, thread_pool_search_queue_size?: int, knn_memory_circuit_breaker_limit?: int, indices_query_bool_max_clause_count?: int, thread_pool_search_throttled_queue_size?: int, cluster_max_shards_per_node?: int}
# --opensearch-dashboards shape: {opensearch-request-timeout?: int, enabled?: bool, max-old-space-size?: int}
export def "dbaas-opensearch update-dbaas-service-opensearch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-index-count: int # Maximum number of indexes to keep before deleting the oldest one (nullable, format: int64)
  --keep-index-refresh-interval: string@bool-completer # Aiven automation resets index.refresh_interval to default value for every index to be sure that indices are always visible to search. If it doesn't fit your case, you can disable this by setting up this flag to true.
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --index-patterns: list # Allows you to create glob style patterns and set a max number of indexes matching this pattern you want to keep. Creating indexes exceeding this value will cause the oldest one to get deleted. You could for example create a pattern looking like 'logs.?' and then create index logs.1, logs.2 etc, it will delete logs.1 once you create logs.6. Do note 'logs.?' does not apply to logs.10. Note: Setting max_index_count to 0 will do nothing and the pattern gets ignored. — item shape: {max-index-count?: int, sorting-algorithm?: "alphabetical"|"creation_date", pattern?: string}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --index-template: record # Template settings for all new indexes — shape: {mapping-nested-objects-limit?: int, number-of-replicas?: int, number-of-shards?: int}
  --opensearch-settings: record # shape: {thread_pool_search_throttled_size?: int, thread_pool_analyze_size?: int, thread_pool_get_size?: int, thread_pool_get_queue_size?: int, indices_memory_max_index_buffer_size?: int, indices_recovery_max_concurrent_file_chunks?: int, indices_queries_cache_size?: int, search_backpressure?: record, shard_indexing_pressure?: record, knn_memory_circuit_breaker_enabled?: bool, thread_pool_search_size?: int, indices_memory_min_index_buffer_size?: int, indices_recovery_max_bytes_per_sec?: int, http_max_initial_line_length?: int, enable_security_audit?: bool, thread_pool_write_queue_size?: int, script_max_compilations_rate?: string, search_max_buckets?: int, reindex_remote_whitelist?: list, override_main_response_version?: bool, http_max_header_size?: int, email-sender?: record, indices_fielddata_cache_size?: int, action_destructive_requires_name?: bool, plugins_alerting_filter_by_backend_roles?: bool, indices_memory_index_buffer_size?: int, thread_pool_force_merge_size?: int, auth_failure_listeners?: record, ism-history?: record, cluster_routing_allocation_node_concurrent_recoveries?: int, thread_pool_analyze_queue_size?: int, action_auto_create_index_enabled?: bool, http_max_content_length?: int, thread_pool_write_size?: int, thread_pool_search_queue_size?: int, knn_memory_circuit_breaker_limit?: int, indices_query_bool_max_clause_count?: int, thread_pool_search_throttled_queue_size?: int, cluster_max_shards_per_node?: int}
  --version: string # Version
  --plan: string # Subscription plan
  --opensearch-dashboards: record # OpenSearch Dashboards settings — shape: {opensearch-request-timeout?: int, enabled?: bool, max-old-space-size?: int}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-opensearch/($name)")
  let body = {max-index-count: $max_index_count, keep-index-refresh-interval: $keep_index_refresh_interval, ip-filter: $ip_filter, termination-protection: $termination_protection, index-patterns: $index_patterns, maintenance: $maintenance, index-template: $index_template, opensearch-settings: $opensearch_settings, version: $version, plan: $plan, opensearch-dashboards: $opensearch_dashboards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Detach a DBaaS external integration from a service
#
# PUT /dbaas-external-endpoint/{source-service-name}/detach
# operationId: detach-dbaas-service-from-endpoint
export def "dbaas-external-endpoint-detach detach-dbaas-service-from-endpoint" [
  source_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  integration_id: string # External Integration ID (format: uuid)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-external-endpoint/($source_service_name)/detach")
  let body = {integration-id: $integration_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reveal the secrets of a DBaaS Valkey user
#
# GET /dbaas-valkey/{service-name}/user/{username}/password/reveal
# operationId: reveal-dbaas-valkey-user-password
export def "dbaas-valkey-user-password-reveal reveal-dbaas-valkey-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($service_name)/user/($username)/password/reveal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Organization Consumption Quota
#
# GET /ai/quota
# operationId: get-user-org-consumption-quota
export def "ai-quota get-user-org-consumption-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<quota_uom_per_minute: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a DBaaS PostgreSQL service
#
# PUT /dbaas-postgres/{name}
# operationId: update-dbaas-service-pg
# --pgbouncer-settings shape: {min_pool_size?: int, ignore_startup_parameters?: list, server_lifetime?: int, autodb_pool_mode?: "transaction"|"session"|"statement", server_idle_timeout?: int, autodb_max_db_connections?: int, max_prepared_statements?: int, server_reset_query_always?: bool, autodb_pool_size?: int, autodb_idle_timeout?: int}
# --backup-schedule shape: {backup-hour?: int, backup-minute?: int}
# --timescaledb-settings shape: {max_background_workers?: int}
# --pgaudit-settings shape: {role?: string, log_parameter?: bool, log_rows?: bool, log_level?: "debug1"|"debug2"|"debug3"|"debug4"|"debug5"|"info"|"notice"|"warning"|"log", log_relation?: bool, log_statement_once?: bool, log_max_string_length?: int, log_catalog?: bool, log_nested_statements?: bool, log_statement?: bool, log_client?: bool, feature_enabled?: bool, log?: list, log_parameter_max_size?: int}
# --pglookout-settings shape: {max_failover_replication_time_lag?: int}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --pg-settings shape: {track_activity_query_size?: int, timezone?: string, track_io_timing?: "off"|"on", pg_stat_monitor.pgsm_enable_query_plan?: bool, max_files_per_process?: int, pg_stat_monitor.pgsm_max_buckets?: int, io_max_concurrency?: int, wal?: record, default_toast_compression?: "lz4"|"pglz", deadlock_timeout?: int, idle_in_transaction_session_timeout?: int, max_pred_locks_per_transaction?: int, max_replication_slots?: int, max_sync_workers_per_subscription?: int, autovacuum?: record, max_parallel_workers_per_gather?: int, io_combine_limit?: int, password_encryption?: "md5"|"scram-sha-256", io_workers?: int, pg_partman_bgw.interval?: int, log_line_prefix?: "'pid=%p,user=%u,db=%d,app=%a,client=%h '"|"'pid=%p,user=%u,db=%d,app=%a,client=%h,txid=%x,qid=%Q '"|"'%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '"|"'%m [%p] %q[user=%u,db=%d,app=%a] '", log_temp_files?: int, max_locks_per_transaction?: int, track_commit_timestamp?: "off"|"on", track_functions?: "all"|"pl"|"none", io_max_combine_limit?: int, io_method?: "worker"|"sync"|"io_uring", max_stack_depth?: int, max_parallel_workers?: int, pg_partman_bgw.role?: string, max_logical_replication_workers?: int, max_prepared_transactions?: int, max_worker_processes?: int, pg_stat_statements.track?: "all"|"top"|"none", temp_file_limit?: int, log_error_verbosity?: "TERSE"|"DEFAULT"|"VERBOSE", log_min_duration_statement?: int, max_standby_streaming_delay?: int, jit?: bool, max_standby_archive_delay?: int, bg-writer?: record}
# --migration shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
export def "dbaas-postgres update-dbaas-service-pg" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pgbouncer-settings: record # System-wide settings for pgbouncer. — shape: {min_pool_size?: int, ignore_startup_parameters?: list, server_lifetime?: int, autodb_pool_mode?: "transaction"|"session"|"statement", server_idle_timeout?: int, autodb_max_db_connections?: int, max_prepared_statements?: int, server_reset_query_always?: bool, autodb_pool_size?: int, autodb_idle_timeout?: int}
  --backup-schedule: record # shape: {backup-hour?: int, backup-minute?: int}
  --variant: string@variant-completer
  --timescaledb-settings: record # System-wide settings for the timescaledb extension — shape: {max_background_workers?: int}
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --pgaudit-settings: record # System-wide settings for the pgaudit extension. — shape: {role?: string, log_parameter?: bool, log_rows?: bool, log_level?: "debug1"|"debug2"|"debug3"|"debug4"|"debug5"|"info"|"notice"|"warning"|"log", log_relation?: bool, log_statement_once?: bool, log_max_string_length?: int, log_catalog?: bool, log_nested_statements?: bool, log_statement?: bool, log_client?: bool, feature_enabled?: bool, log?: list, log_parameter_max_size?: int}
  --synchronous-replication: string@synchronous-replication-completer
  --pglookout-settings: record # System-wide settings for pglookout. — shape: {max_failover_replication_time_lag?: int}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --version: string # Version
  --plan: string # Subscription plan
  --work-mem: int # Sets the maximum amount of memory to be used by a query operation (such as a sort or hash table) before writing to temporary disk files, in MB. Default is 1MB + 0.075% of total RAM (up to 32MB). (format: int64)
  --shared-buffers-percentage: int # Percentage of total RAM that the database server uses for shared memory buffers. Valid range is 20-60 (float), which corresponds to 20% - 60%. This setting adjusts the shared_buffers configuration value. (format: int64)
  --pg-settings: record # shape: {track_activity_query_size?: int, timezone?: string, track_io_timing?: "off"|"on", pg_stat_monitor.pgsm_enable_query_plan?: bool, max_files_per_process?: int, pg_stat_monitor.pgsm_max_buckets?: int, io_max_concurrency?: int, wal?: record, default_toast_compression?: "lz4"|"pglz", deadlock_timeout?: int, idle_in_transaction_session_timeout?: int, max_pred_locks_per_transaction?: int, max_replication_slots?: int, max_sync_workers_per_subscription?: int, autovacuum?: record, max_parallel_workers_per_gather?: int, io_combine_limit?: int, password_encryption?: "md5"|"scram-sha-256", io_workers?: int, pg_partman_bgw.interval?: int, log_line_prefix?: "'pid=%p,user=%u,db=%d,app=%a,client=%h '"|"'pid=%p,user=%u,db=%d,app=%a,client=%h,txid=%x,qid=%Q '"|"'%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '"|"'%m [%p] %q[user=%u,db=%d,app=%a] '", log_temp_files?: int, max_locks_per_transaction?: int, track_commit_timestamp?: "off"|"on", track_functions?: "all"|"pl"|"none", io_max_combine_limit?: int, io_method?: "worker"|"sync"|"io_uring", max_stack_depth?: int, max_parallel_workers?: int, pg_partman_bgw.role?: string, max_logical_replication_workers?: int, max_prepared_transactions?: int, max_worker_processes?: int, pg_stat_statements.track?: "all"|"top"|"none", temp_file_limit?: int, log_error_verbosity?: "TERSE"|"DEFAULT"|"VERBOSE", log_min_duration_statement?: int, max_standby_streaming_delay?: int, jit?: bool, max_standby_archive_delay?: int, bg-writer?: record}
  --migration: record # Migrate data from existing server — shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($name)")
  let body = {pgbouncer-settings: $pgbouncer_settings, backup-schedule: $backup_schedule, variant: $variant, timescaledb-settings: $timescaledb_settings, ip-filter: $ip_filter, termination-protection: $termination_protection, pgaudit-settings: $pgaudit_settings, synchronous-replication: $synchronous_replication, pglookout-settings: $pglookout_settings, maintenance: $maintenance, version: $version, plan: $plan, work-mem: $work_mem, shared-buffers-percentage: $shared_buffers_percentage, pg-settings: $pg_settings, migration: $migration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a DBaaS PostgreSQL service
#
# GET /dbaas-postgres/{name}
# operationId: get-dbaas-service-pg
export def "dbaas-postgres get-dbaas-service-pg" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pgbouncer_settings: record<min_pool_size: int, ignore_startup_parameters: list<string>, server_lifetime: int, autodb_pool_mode: string, server_idle_timeout: int, autodb_max_db_connections: int, max_prepared_statements: int, server_reset_query_always: bool, autodb_pool_size: int, autodb_idle_timeout: int>, updated_at: string, node_count: int, connection_info: record<uri: list<string>, params: list<record>, standby: list<string>, syncing: list<string>>, backup_schedule: record<backup_hour: int, backup_minute: int>, node_cpu_count: int, prometheus_uri: record<host: string, port: int>, integrations: table<description: string, settings: record, type: string, is_enabled: bool, source: string, is_active: bool, status: string, id: string, dest: string>, zone: string, node_states: table<name: string, progress_updates: list, role: string, state: string>, name: string, connection_pools: table<connection_uri: string, database: string, mode: string, name: string, size: int, username: string>, type: string, state: string, timescaledb_settings: record<max_background_workers: int>, databases: list<string>, ip_filter: list<string>, backups: table<backup_name: string, backup_time: string, data_size: int>, termination_protection: bool, pgaudit_settings: record<role: string, log_parameter: bool, log_rows: bool, log_level: string, log_relation: bool, log_statement_once: bool, log_max_string_length: int, log_catalog: bool, log_nested_statements: bool, log_statement: bool, log_client: bool, feature_enabled: bool, log: list<string>, log_parameter_max_size: int>, notifications: table<level: string, message: string, type: string, metadata: record>, components: table<component: string, host: string, port: int, route: string, usage: string>, synchronous_replication: string, pglookout_settings: record<max_failover_replication_time_lag: int>, maintenance: record<dow: string, time: string, updates: list<record>>, disk_size: int, node_memory: int, uri: string, uri_params: record, version: string, created_at: string, plan: string, work_mem: int, shared_buffers_percentage: int, pg_settings: record<track_activity_query_size: int, timezone: string, track_io_timing: string, pg_stat_monitor_pgsm_enable_query_plan: bool, max_files_per_process: int, pg_stat_monitor_pgsm_max_buckets: int, io_max_concurrency: int, wal: record<max_slot_wal_keep_size: int, max_wal_senders: int, wal_sender_timeout: int, wal_writer_delay: int>, default_toast_compression: string, deadlock_timeout: int, idle_in_transaction_session_timeout: int, max_pred_locks_per_transaction: int, max_replication_slots: int, max_sync_workers_per_subscription: int, autovacuum: record<log_autovacuum_min_duration: int, autovacuum_vacuum_cost_limit: int, autovacuum_max_workers: int, autovacuum_vacuum_threshold: int, autovacuum_naptime: int, autovacuum_vacuum_scale_factor: float, autovacuum_vacuum_cost_delay: int, autovacuum_analyze_scale_factor: float, autovacuum_analyze_threshold: int, autovacuum_freeze_max_age: int>, max_parallel_workers_per_gather: int, io_combine_limit: int, password_encryption: string, io_workers: int, pg_partman_bgw_interval: int, log_line_prefix: string, log_temp_files: int, max_locks_per_transaction: int, track_commit_timestamp: string, track_functions: string, io_max_combine_limit: int, io_method: string, max_stack_depth: int, max_parallel_workers: int, pg_partman_bgw_role: string, max_logical_replication_workers: int, max_prepared_transactions: int, max_worker_processes: int, pg_stat_statements_track: string, temp_file_limit: int, log_error_verbosity: string, log_min_duration_statement: int, max_standby_streaming_delay: int, jit: bool, max_standby_archive_delay: int, bg_writer: record<bgwriter_delay: int, bgwriter_flush_after: int, bgwriter_lru_maxpages: int, bgwriter_lru_multiplier: float>>, max_connections: int, users: table<type: string, username: string, password: string, allow_replication: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS PostgreSQL service
#
# POST /dbaas-postgres/{name}
# operationId: create-dbaas-service-pg
# --pgbouncer-settings shape: {min_pool_size?: int, ignore_startup_parameters?: list, server_lifetime?: int, autodb_pool_mode?: "transaction"|"session"|"statement", server_idle_timeout?: int, autodb_max_db_connections?: int, max_prepared_statements?: int, server_reset_query_always?: bool, autodb_pool_size?: int, autodb_idle_timeout?: int}
# --backup-schedule shape: {backup-hour?: int, backup-minute?: int}
# --integrations item shape: {type: "read_replica", source-service?: string, dest-service?: string, settings?: record}
# --timescaledb-settings shape: {max_background_workers?: int}
# --pgaudit-settings shape: {role?: string, log_parameter?: bool, log_rows?: bool, log_level?: "debug1"|"debug2"|"debug3"|"debug4"|"debug5"|"info"|"notice"|"warning"|"log", log_relation?: bool, log_statement_once?: bool, log_max_string_length?: int, log_catalog?: bool, log_nested_statements?: bool, log_statement?: bool, log_client?: bool, feature_enabled?: bool, log?: list, log_parameter_max_size?: int}
# --pglookout-settings shape: {max_failover_replication_time_lag?: int}
# --maintenance shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
# --pg-settings shape: {track_activity_query_size?: int, timezone?: string, track_io_timing?: "off"|"on", pg_stat_monitor.pgsm_enable_query_plan?: bool, max_files_per_process?: int, pg_stat_monitor.pgsm_max_buckets?: int, io_max_concurrency?: int, wal?: record, default_toast_compression?: "lz4"|"pglz", deadlock_timeout?: int, idle_in_transaction_session_timeout?: int, max_pred_locks_per_transaction?: int, max_replication_slots?: int, max_sync_workers_per_subscription?: int, autovacuum?: record, max_parallel_workers_per_gather?: int, io_combine_limit?: int, password_encryption?: "md5"|"scram-sha-256", io_workers?: int, pg_partman_bgw.interval?: int, log_line_prefix?: "'pid=%p,user=%u,db=%d,app=%a,client=%h '"|"'pid=%p,user=%u,db=%d,app=%a,client=%h,txid=%x,qid=%Q '"|"'%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '"|"'%m [%p] %q[user=%u,db=%d,app=%a] '", log_temp_files?: int, max_locks_per_transaction?: int, track_commit_timestamp?: "off"|"on", track_functions?: "all"|"pl"|"none", io_max_combine_limit?: int, io_method?: "worker"|"sync"|"io_uring", max_stack_depth?: int, max_parallel_workers?: int, pg_partman_bgw.role?: string, max_logical_replication_workers?: int, max_prepared_transactions?: int, max_worker_processes?: int, pg_stat_statements.track?: "all"|"top"|"none", temp_file_limit?: int, log_error_verbosity?: "TERSE"|"DEFAULT"|"VERBOSE", log_min_duration_statement?: int, max_standby_streaming_delay?: int, jit?: bool, max_standby_archive_delay?: int, bg-writer?: record}
# --migration shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
export def "dbaas-postgres create-dbaas-service-pg" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pgbouncer-settings: record # System-wide settings for pgbouncer. — shape: {min_pool_size?: int, ignore_startup_parameters?: list, server_lifetime?: int, autodb_pool_mode?: "transaction"|"session"|"statement", server_idle_timeout?: int, autodb_max_db_connections?: int, max_prepared_statements?: int, server_reset_query_always?: bool, autodb_pool_size?: int, autodb_idle_timeout?: int}
  --backup-schedule: record # shape: {backup-hour?: int, backup-minute?: int}
  --variant: string@variant-completer
  --integrations: list # Service integrations to be enabled when creating the service. — item shape: {type: "read_replica", source-service?: string, dest-service?: string, settings?: record}
  --timescaledb-settings: record # System-wide settings for the timescaledb extension — shape: {max_background_workers?: int}
  --ip-filter: list # Allow incoming connections from CIDR address block, e.g. '10.20.0.0/16'
  --termination-protection: string@bool-completer # Service is protected against termination and powering off
  --pgaudit-settings: record # System-wide settings for the pgaudit extension. — shape: {role?: string, log_parameter?: bool, log_rows?: bool, log_level?: "debug1"|"debug2"|"debug3"|"debug4"|"debug5"|"info"|"notice"|"warning"|"log", log_relation?: bool, log_statement_once?: bool, log_max_string_length?: int, log_catalog?: bool, log_nested_statements?: bool, log_statement?: bool, log_client?: bool, feature_enabled?: bool, log?: list, log_parameter_max_size?: int}
  --fork-from-service: string
  --synchronous-replication: string@synchronous-replication-completer
  --recovery-backup-time: string # ISO time of a backup to recover from for services that support arbitrary times
  --pglookout-settings: record # System-wide settings for pglookout. — shape: {max_failover_replication_time_lag?: int}
  --maintenance: record # Automatic maintenance settings — shape: {dow: "saturday"|"tuesday"|"never"|"wednesday"|"sunday"|"friday"|"monday"|"thursday", time: string}
  --admin-username: string # Custom username for admin user. This must be set only when a new service is being created.
  --version: string@version-completer
  plan: string # Subscription plan
  --work-mem: int # Sets the maximum amount of memory to be used by a query operation (such as a sort or hash table) before writing to temporary disk files, in MB. Default is 1MB + 0.075% of total RAM (up to 32MB). (format: int64)
  --shared-buffers-percentage: int # Percentage of total RAM that the database server uses for shared memory buffers. Valid range is 20-60 (float), which corresponds to 20% - 60%. This setting adjusts the shared_buffers configuration value. (format: int64)
  --pg-settings: record # shape: {track_activity_query_size?: int, timezone?: string, track_io_timing?: "off"|"on", pg_stat_monitor.pgsm_enable_query_plan?: bool, max_files_per_process?: int, pg_stat_monitor.pgsm_max_buckets?: int, io_max_concurrency?: int, wal?: record, default_toast_compression?: "lz4"|"pglz", deadlock_timeout?: int, idle_in_transaction_session_timeout?: int, max_pred_locks_per_transaction?: int, max_replication_slots?: int, max_sync_workers_per_subscription?: int, autovacuum?: record, max_parallel_workers_per_gather?: int, io_combine_limit?: int, password_encryption?: "md5"|"scram-sha-256", io_workers?: int, pg_partman_bgw.interval?: int, log_line_prefix?: "'pid=%p,user=%u,db=%d,app=%a,client=%h '"|"'pid=%p,user=%u,db=%d,app=%a,client=%h,txid=%x,qid=%Q '"|"'%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '"|"'%m [%p] %q[user=%u,db=%d,app=%a] '", log_temp_files?: int, max_locks_per_transaction?: int, track_commit_timestamp?: "off"|"on", track_functions?: "all"|"pl"|"none", io_max_combine_limit?: int, io_method?: "worker"|"sync"|"io_uring", max_stack_depth?: int, max_parallel_workers?: int, pg_partman_bgw.role?: string, max_logical_replication_workers?: int, max_prepared_transactions?: int, max_worker_processes?: int, pg_stat_statements.track?: "all"|"top"|"none", temp_file_limit?: int, log_error_verbosity?: "TERSE"|"DEFAULT"|"VERBOSE", log_min_duration_statement?: int, max_standby_streaming_delay?: int, jit?: bool, max_standby_archive_delay?: int, bg-writer?: record}
  --admin-password: string # Custom password for admin user. Defaults to random string. This must be set only when a new service is being created.
  --migration: record # Migrate data from existing server — shape: {host: string, port: int, password?: string, ssl?: bool, username?: string, dbname?: string, ignore-dbs?: string, method?: "dump"|"replication"}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($name)")
  let body = {pgbouncer-settings: $pgbouncer_settings, backup-schedule: $backup_schedule, variant: $variant, integrations: $integrations, timescaledb-settings: $timescaledb_settings, ip-filter: $ip_filter, termination-protection: $termination_protection, pgaudit-settings: $pgaudit_settings, fork-from-service: $fork_from_service, synchronous-replication: $synchronous_replication, recovery-backup-time: $recovery_backup_time, pglookout-settings: $pglookout_settings, maintenance: $maintenance, admin-username: $admin_username, version: $version, plan: $plan, work-mem: $work_mem, shared-buffers-percentage: $shared_buffers_percentage, pg-settings: $pg_settings, admin-password: $admin_password, migration: $migration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Postgres service
#
# DELETE /dbaas-postgres/{name}
# operationId: delete-dbaas-service-pg
export def "dbaas-postgres delete-dbaas-service-pg" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a DBaaS Valkey user
#
# POST /dbaas-valkey/{service-name}/user
# operationId: create-dbaas-valkey-user
# --access-control shape: {categories?: list, channels?: list, commands?: list, keys?: list}
export def "dbaas-valkey-user create-dbaas-valkey-user" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  --access-control: record # shape: {categories?: list, channels?: list, commands?: list, keys?: list}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($service_name)/user")
  let body = {username: $username, access-control: $access_control} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List DBaaS Valkey users with ACL configuration
#
# GET /dbaas-valkey/{service-name}/user
# operationId: list-dbaas-valkey-users
export def "dbaas-valkey-user list-dbaas-valkey-users" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<users: table<username: string, type: string, access_control: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-valkey/($service_name)/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Exoscale Karpenter credentials
#
# PUT /sks-cluster/{id}/rotate-karpenter-credentials
# operationId: rotate-sks-karpenter-credentials
export def "sks-cluster-rotate-karpenter-credentials rotate-sks-karpenter-credentials" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/rotate-karpenter-credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create a new DBaaS integration between two services
#
# POST /dbaas-integration
# operationId: create-dbaas-integration
export def "dbaas-integration create-dbaas-integration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  integration_type: string@integration-type-completer
  source_service: string
  dest_service: string
  --settings: record # Integration settings
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbaas-integration")
  let body = {integration-type: $integration_type, source-service: $source_service, dest-service: $dest_service, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a DBaaS task
#
# GET /dbaas-task/{service}/{id}
# operationId: get-dbaas-task
export def "dbaas-task get-dbaas-task" [
  service: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, create_time: string, result: string, result_codes: table<code: string, dbname: string>, success: bool, task_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-task/($service)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Presigned Download URL for SOS object
#
# GET /sos/{bucket}/presigned-url
# operationId: get-sos-presigned-url
export def "sos-presigned-url get-sos-presigned-url" [
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sos/($bucket)/presigned-url" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate operators certificate authority
#
# PUT /sks-cluster/{id}/rotate-operators-ca
# operationId: rotate-sks-operators-ca
export def "sks-cluster-rotate-operators-ca rotate-sks-operators-ca" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/rotate-operators-ca")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reveal Deployment API Key
#
# GET /ai/deployment/{id}/api-key
# operationId: reveal-deployment-api-key
export def "ai-deployment-api-key reveal-deployment-api-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/deployment/($id)/api-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Anti-affinity Group details
#
# GET /anti-affinity-group/{id}
# operationId: get-anti-affinity-group
export def "anti-affinity-group get-anti-affinity-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, instances: table<application_consistent_snapshot_enabled: bool, anti_affinity_groups: list, public_ip_assignment: string, labels: record, security_groups: list, elastic_ips: list, name: string, instance_type: record, private_networks: list, template: record, state: string, secureboot_enabled: bool, ssh_key: record, user_data: string, mac_address: string, manager: record, tpm_enabled: bool, deploy_target: record, ipv6_address: string, id: string, snapshots: list, disk_size: int, disk_encrypted: bool, ssh_keys: list, created_at: string, public_ip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/anti-affinity-group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Anti-affinity Group
#
# DELETE /anti-affinity-group/{id}
# operationId: delete-anti-affinity-group
export def "anti-affinity-group delete-anti-affinity-group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/anti-affinity-group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Replicate KMS Key
#
# POST /kms-key/{id}/replicate
# operationId: replicate-kms-key
export def "kms-key-replicate replicate-kms-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  zone: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/replicate")
  let body = {zone: $zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List available versions for SKS clusters
#
# GET /sks-cluster-version
# operationId: list-sks-cluster-versions
export def "sks-cluster-version list-sks-cluster-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deprecated: string
]: nothing -> record<sks_cluster_versions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include-deprecated" $include_deprecated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sks-cluster-version" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Compute instance
#
# POST /instance
# operationId: create-instance
# --anti-affinity-groups item shape: {id?: string}
# --security-groups item shape: {id?: string}
# --instance-type shape: {id?: string}
# --template shape: {id?: string}
# --ssh-key shape: {name?: string}
# --deploy-target shape: {id?: string}
# --ssh-keys item shape: {name?: string}
export def "instance create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application-consistent-snapshot-enabled: string@bool-completer # Enable application-consistent snapshot for the instance
  --anti-affinity-groups: list # Instance Anti-affinity Groups — item shape: {id?: string}
  --public-ip-assignment: string@public-ip-assignment-completer
  --labels: record
  --auto-start: string@bool-completer # Start Instance on creation (default: true)
  --security-groups: list # Instance Security Groups — item shape: {id?: string}
  --name: string # Instance name
  instance_type: record # Instance type reference — shape: {id?: string}
  template: record # Template reference — shape: {id?: string}
  --secureboot-enabled: string@bool-completer # Enable secure boot
  --ssh-key: record # SSH key reference — shape: {name?: string}
  --user-data: string # Instance Cloud-init user-data (base64 encoded)
  --tpm-enabled: string@bool-completer # Enable Trusted Platform Module (TPM)
  --deploy-target: record # Deploy target reference — shape: {id?: string}
  --ipv6-enabled: string@bool-completer # Enable IPv6. DEPRECATED: use `public-ip-assignments`.
  disk_size: int # Instance disk size in GiB (format: int64)
  --ssh-keys: list # Instance SSH Keys — item shape: {name?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/instance")
  let body = {application-consistent-snapshot-enabled: $application_consistent_snapshot_enabled, anti-affinity-groups: $anti_affinity_groups, public-ip-assignment: $public_ip_assignment, labels: $labels, auto-start: $auto_start, security-groups: $security_groups, name: $name, instance-type: $instance_type, template: $template, secureboot-enabled: $secureboot_enabled, ssh-key: $ssh_key, user-data: $user_data, tpm-enabled: $tpm_enabled, deploy-target: $deploy_target, ipv6-enabled: $ipv6_enabled, disk-size: $disk_size, ssh-keys: $ssh_keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Compute instances
#
# GET /instance
# operationId: list-instances
export def "instance list-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --manager-id: string # format: uuid
  --manager-type: string@manager-type-completer
  --ip-address: string
  --labels: string
]: nothing -> record<instances: table<public_ip_assignment: string, labels: record, security_groups: list, name: string, instance_type: record, private_networks: list, template: record, state: string, ssh_key: record, mac_address: string, manager: record, ipv6_address: string, id: string, ssh_keys: list, created_at: string, public_ip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "manager-id" $manager_id "scalar") (serialize-qp "manager-type" $manager_type "scalar") (serialize-qp "ip-address" $ip_address "scalar") (serialize-qp "labels" $labels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/instance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List IAM Roles
#
# GET /iam-role
# operationId: list-iam-roles
export def "iam-role list-iam-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<iam_roles: table<description: string, labels: record, permissions: list, assume_role_policy: record, editable: bool, name: string, max_session_ttl: int, policy: record, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iam-role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create IAM Role
#
# POST /iam-role
# operationId: create-iam-role
# --policy shape: {default-service-strategy: "allow"|"deny", services: record}
# --assume-role-policy shape: {rules?: list}
export def "iam-role create-iam-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # IAM Role name
  --description: string # IAM Role description
  --permissions: list # IAM Role permissions
  --editable: string@bool-completer # Sets if the IAM Role Policy is editable or not (default: true). This setting cannot be changed after creation
  --labels: record
  --policy: record # Policy — shape: {default-service-strategy: "allow"|"deny", services: record}
  --assume-role-policy: record # Assume Role Policy — shape: {rules?: list}
  --max-session-ttl: int # Maximum TTL requester is allowed to ask for when assuming a role (format: int64)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iam-role")
  let body = {name: $name, description: $description, permissions: $permissions, editable: $editable, labels: $labels, policy: $policy, assume-role-policy: $assume_role_policy, max-session-ttl: $max_session_ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset Private Network field
#
# DELETE /private-network/{id}/{field}
# operationId: reset-private-network-field
export def "private-network reset-private-network-field" [
  id: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/private-network/($id)/($field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a User
#
# POST /user
# operationId: create-user
# --role shape: {description?: string, labels?: record, permissions?: list, assume-role-policy?: record, editable?: bool, name?: string, max-session-ttl?: int, policy?: record}
export def "user create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # User Email
  --role: record # IAM Role — shape: {description?: string, labels?: record, permissions?: list, assume-role-policy?: record, editable?: bool, name?: string, max-session-ttl?: int, policy?: record}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let body = {email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Users
#
# GET /user
# operationId: list-users
export def "user list-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<users: table<sso: bool, two_factor_authentication: bool, email: string, id: string, role: record, pending: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment Logs
#
# GET /ai/deployment/{id}/logs
# operationId: get-deployment-logs
export def "ai-deployment-logs get-deployment-logs" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream: string@bool-completer
  --tail: int # format: int64
]: nothing -> record<logs: table<time: string, node: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai/deployment/($id)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upgrade an SKS cluster
#
# PUT /sks-cluster/{id}/upgrade
# operationId: upgrade-sks-cluster
export def "sks-cluster-upgrade upgrade-sks-cluster" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  version: string # Control plane Kubernetes version
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sks-cluster/($id)/upgrade")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Cancel KMS Key Deletion
#
# POST /kms-key/{id}/cancel-deletion
# operationId: cancel-kms-key-deletion
export def "kms-key-cancel-deletion cancel-kms-key-deletion" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/cancel-deletion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Generate Data Key
#
# POST /kms-key/{id}/generate-data-key
# operationId: generate-data-key
export def "kms-key-generate-data-key generate-data-key" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-spec: string@key-spec-completer
  --bytes-count: int
  --encryption-context: string # nullable, format: byte
]: any -> record<plaintext: string, ciphertext: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kms-key/($id)/generate-data-key")
  let body = {key-spec: $key_spec, bytes-count: $bytes_count, encryption-context: $encryption_context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Update a VPC
#
# PUT /vpc/{id}
# operationId: update-vpc
export def "vpc update-vpc" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # VPC name (nullable)
  --description: string # VPC description (nullable)
  --labels: record
]: any -> record<id: string, name: string, description: string, created_at: string, labels: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vpc/($id)")
  let body = {name: $name, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Retrieve VPC details
#
# GET /vpc/{id}
# operationId: get-vpc
export def "vpc get-vpc" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, created_at: string, labels: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vpc/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Delete a VPC
#
# DELETE /vpc/{id}
# operationId: delete-vpc
export def "vpc delete-vpc" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vpc/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List block storage volumes
#
# GET /block-storage
# operationId: list-block-storage-volumes
export def "block-storage list-block-storage-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --instance-id: string # format: uuid
]: nothing -> record<block_storage_volumes: table<labels: record, instance: record, name: string, state: string, size: int, blocksize: int, block_storage_snapshots: list, id: string, encrypted: bool, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "instance-id" $instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/block-storage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a block storage volume
#
# POST /block-storage
# operationId: create-block-storage-volume
# --block-storage-snapshot shape: {id?: string}
export def "block-storage create-block-storage-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Volume name
  --size: int # Volume size in GiB.                             When a snapshot ID is supplied, this defaults to the size of the source volume, but can be set to a larger value. (format: int64)
  --labels: record
  --block-storage-snapshot: record # Target block storage snapshot — shape: {id?: string}
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/block-storage")
  let body = {name: $name, size: $size, labels: $labels, block-storage-snapshot: $block_storage_snapshot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Kafka ACL entry
#
# DELETE /dbaas-kafka/{name}/topic/acl-config/{acl-id}
# operationId: delete-dbaas-kafka-topic-acl-config
export def "dbaas-kafka-topic-acl-config delete-dbaas-kafka-topic-acl-config" [
  name: string
  acl_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-kafka/($name)/topic/acl-config/($acl_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revert a snapshot for an instance
#
# POST /instance/{instance-id}:revert-snapshot
# operationId: revert-instance-to-snapshot
export def "instance revert-instance-to-snapshot" [
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # Snapshot ID (format: uuid)
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/instance/($instance_id):revert-snapshot")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the credentials of a DBaaS Postgres user
#
# PUT /dbaas-postgres/{service-name}/user/{username}/password/reset
# operationId: reset-dbaas-postgres-user-password
export def "dbaas-postgres-user-password-reset reset-dbaas-postgres-user-password" [
  service_name: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> record<id: string, reason: string, reference: record<id: string, link: string, command: string>, message: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dbaas-postgres/($service_name)/user/($username)/password/reset")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
