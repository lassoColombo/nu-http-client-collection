# Auto-generated client for vRealize Network Insight API Reference v1.0.0
# Source: https://api.apis.guru/v2/specs/vmware.local/vrni/1.0.0/openapi.json
# Auth: --token flag or $env.VREALIZE_NETWORK_INSIGHT_API_REFERENCE_TOKEN

const BASE_URL = "http://vmware.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VREALIZE_NETWORK_INSIGHT_API_REFERENCE_TOKEN | default "" }
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

def base-url-completer [] { ["http://vmware.local" "https://vrni.example.com/api/ni"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "expiry" "token"] }
def snmp-version-completer [] { ["v2c" "v3"] }
def switch-type-completer [] { ["CATALYST_3000" "CATALYST_4500" "CATALYST_6500" "NEXUS_5K" "NEXUS_7K" "NEXUS_9K"] }
def switch-type-completer-1 [] { ["FORCE_10_MXL_10" "POWERCONNECT_8024" "S4048" "S6000" "Z9100"] }
def entity-type-completer [] { ["AristaSwitchDataSource" "BrocadeSwitchDataSource" "CheckpointFirewallDataSource" "CiscoSwitchDataSource" "DellSwitchDataSource" "HPOneViewDataSource" "HPVCManagerDataSource" "JuniperSwitchDataSource" "NSXVManagerDataSource" "PanFirewallDataSource" "UCSManagerDataSource" "VCenterDataSource"] }
def accept-completer-1 [] { ["application/json" "results" "total_count"] }
def accept-completer-2 [] { ["application/json" "credentials" "enabled" "entity_id" "entity_type" "fqdn" "ip" "nickname" "notes" "proxy_id"] }
def accept-completer-3 [] { ["application/json" "cursor" "end_time" "results" "start_time" "total_count"] }
def accept-completer-4 [] { ["application/json" "entity_id" "entity_type" "name" "nsx_manager" "num_cpu_cores" "num_datastores" "num_hosts" "total_cpus" "total_memory" "vcenter_manager" "vendor_id"] }
def accept-completer-5 [] { ["application/json" "entity_id" "entity_type" "name" "vcenter_manager" "vendor_id"] }
def accept-completer-6 [] { ["application/json" "distributed_virtual_switch" "entity_id" "entity_type" "name" "vcenter_manager" "vendor_id"] }
def accept-completer-7 [] { ["application/json" "entity_id" "entity_type" "hosts" "name" "vcenter_manager" "vendor_id"] }
def accept-completer-8 [] { ["action" "application/json" "destination_any" "destination_inversion" "destinations" "direction" "disabled" "entity_id" "entity_type" "logging_enabled" "name" "nsx_managers" "port_ranges" "rule_id" "scope" "section_id" "section_name" "sequence_number" "service_any" "services" "source_any" "source_inversion" "sources"] }
def accept-completer-9 [] { ["application/json" "entity_id" "entity_type" "exclusions" "firewall_rules" "name"] }
def accept-completer-10 [] { ["application/json" "destination_folders" "destination_ip" "destination_ip_sets" "destination_security_groups" "destination_security_tags" "destination_vm_tags" "entity_id" "entity_type" "firewall_action" "flow_tag" "name" "port" "protocol" "source_folders" "source_ip" "source_ip_sets" "source_security_groups" "source_security_tags" "source_vm_tags" "traffic_type" "within_host"] }
def accept-completer-11 [] { ["application/json" "cluster" "connection_state" "datastores" "entity_id" "entity_type" "maintenance_mode" "name" "nsx_manager" "service_tag" "vcenter_manager" "vendor_id" "vm_count" "vmknics"] }
def accept-completer-12 [] { ["application/json" "direct_destination_rules" "direct_source_rules" "entity_id" "entity_type" "indirect_destination_rules" "indirect_source_rules" "ip_addresses" "ip_numeric_ranges" "ip_ranges" "name" "nsx_managers" "parent_security_groups" "scope" "translated_vm_count" "vendor" "vendor_id"] }
def accept-completer-13 [] { ["application/json" "entity_id" "entity_type" "gateways" "name" "network_addresses" "nsx_managers" "scope" "segment_id" "vteps"] }
def accept-completer-14 [] { ["application/json" "entity_id" "entity_type" "ip_address" "name" "role" "version"] }
def accept-completer-15 [] { ["admin_state" "anchor_entities" "application/json" "archived" "entity_id" "entity_type" "event_tags" "event_time_epoch_ms" "message" "name" "related_entities" "severity"] }
def accept-completer-16 [] { ["application/json" "direct_destination_rules" "direct_members" "direct_source_rules" "entity_id" "entity_type" "excluded_members" "indirect_destination_rules" "indirect_source_rules" "ip_sets" "members" "name" "nsx_managers" "parents" "scope" "security_tags" "translated_vm_count" "vendor_id"] }
def accept-completer-17 [] { ["application/json" "description" "direct_security_groups" "entity_id" "entity_type" "name" "nsx_manager" "security_groups" "vendor_id"] }
def accept-completer-18 [] { ["application/json" "entity_id" "entity_type" "members" "name" "nsx_managers" "scope" "vendor_id"] }
def accept-completer-19 [] { ["application/json" "entity_id" "entity_type" "name" "nsx_managers" "port_ranges" "protocol" "scope" "vendor_id"] }
def accept-completer-20 [] { ["application/json" "entity_id" "entity_type" "ip_address" "name"] }
def accept-completer-21 [] { ["application/json" "entity_id" "entity_type" "host" "ip_addresses" "layer2_network" "name" "vlan"] }
def accept-completer-22 [] { ["application/json" "applied_to_destination_rules" "applied_to_source_rules" "cluster" "datacenter" "datastores" "default_gateway" "destination_firewall_rules" "destination_inversion_rules" "entity_id" "entity_type" "folders" "host" "ip_addresses" "ip_sets" "layer2_networks" "name" "nsx_manager" "resource_pool" "security_groups" "security_tags" "source_firewall_rules" "source_inversion_rules" "vcenter_manager" "vendor_id" "vlans" "vnics"] }
def accept-completer-23 [] { ["application/json" "entity_id" "entity_type" "ip_addresses" "layer2_network" "name" "vlan" "vm"] }
def accept-completer-24 [] { ["application/json" "create_time" "created_by" "entity_id" "entity_type" "last_modified_by" "last_modified_time" "name"] }
def accept-completer-25 [] { ["application/json" "results"] }
def accept-completer-26 [] { ["application" "application/json" "entity_id" "entity_type" "group_membership_criteria" "name"] }
def accept-completer-27 [] { ["application/json" "entity_type" "id" "ip_address" "node_id" "node_type"] }
def accept-completer-28 [] { ["application/json" "results" "time_range"] }
def entity-type-completer-1 [] { ["Application" "BaseEvent" "BaseFirewall" "BaseFirewallRule" "BaseIPSet" "BaseL2Network" "BaseManager" "BaseNSXManager" "BaseSecurityGroup" "BaseService" "BaseServiceGroup" "BaseVirtualMachine" "BaseVnic" "Cluster" "Datastore" "DistributedVirtualPortgroup" "DistributedVirtualSwitch" "EC2Firewall" "EC2IPSet" "EC2Instance" "EC2SGFirewallRule" "EC2SecurityGroup" "EC2Service" "Flow" "Folder" "Group" "Host" "NSXDistributedFirewall" "NSXFirewallRule" "NSXIPSet" "NSXRedirectRule" "NSXSecurityGroup" "NSXService" "NSXServiceGroup" "NSXVManager" "ProblemEvent" "ResourcePool" "SecurityTag" "Tier" "VCDatacenter" "VCenterManager" "VPC" "VirtualMachine" "VlanL2Network" "Vmknic" "Vnic" "VxlanLayer2Network"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-token delete" } } | get name | first)
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

# Delete an auth token.
#
# DELETE /auth/token
# operationId: delete
export def "auth-token delete" [
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
  let full_url = (build-url $base "/auth/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an auth token
#
# POST /auth/token
# operationId: create
# --domain shape: {domain_type?: "LDAP"|"LOCAL", value?: string}
export def "auth-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domain: record # shape: {domain_type?: "LDAP"|"LOCAL", value?: string}
  --password: string # e.g. password
  --username: string # e.g. admin@vrni.com
]: any -> record<expiry: int, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let body = {domain: $domain, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List arista switch data sources
#
# GET /data-sources/arista-switches
# operationId: listAristaSwitches
export def "data-sources-arista-switches listAristaSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/arista-switches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an arista switch data source
#
# POST /data-sources/arista-switches
# operationId: addAristaSwitch
export def "data-sources-arista-switches addAristaSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/arista-switches")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an arista switch data source
#
# DELETE /data-sources/arista-switches/{id}
# operationId: deleteAristaSwitch
export def "data-sources-arista-switches delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show arista switch data source details
#
# GET /data-sources/arista-switches/{id}
# operationId: getAristaSwitch
export def "data-sources-arista-switches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an arista switch data source
#
# PUT /data-sources/arista-switches/{id}
# operationId: updateAristaSwitch
export def "data-sources-arista-switches updateAristaSwitch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable an arista switch data source
#
# POST /data-sources/arista-switches/{id}/disable
# operationId: disableAristaSwitch
export def "data-sources-arista-switches-disable disableAristaSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable an arista switch data source
#
# POST /data-sources/arista-switches/{id}/enable
# operationId: enableAristaSwitch
export def "data-sources-arista-switches-enable enableAristaSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show snmp config for arista switch data source
#
# GET /data-sources/arista-switches/{id}/snmp-config
# operationId: getAristaSwitchSnmpConfig
export def "data-sources-arista-switches-snmp-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)/snmp-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snmp config for arista switch data source
#
# PUT /data-sources/arista-switches/{id}/snmp-config
# operationId: updateAristaSwitchSnmpConfig
# --config_snmp_2c shape: {community_string?: string}
# --config_snmp_3 shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
export def "data-sources-arista-switches-snmp-config updateAristaSwitchSnmpConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/arista-switches/($id)/snmp-config")
  let body = {config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List brocade switch data sources
#
# GET /data-sources/brocade-switches
# operationId: listBrocadeSwitches
export def "data-sources-brocade-switches listBrocadeSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/brocade-switches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a brocade switch data source
#
# POST /data-sources/brocade-switches
# operationId: addBrocadeSwitch
export def "data-sources-brocade-switches addBrocadeSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/brocade-switches")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a brocade switch data source
#
# DELETE /data-sources/brocade-switches/{id}
# operationId: deleteBrocadeSwitch
export def "data-sources-brocade-switches delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show brocade switch data source details
#
# GET /data-sources/brocade-switches/{id}
# operationId: getBrocadeSwitch
export def "data-sources-brocade-switches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a brocade switch data source
#
# PUT /data-sources/brocade-switches/{id}
# operationId: updateBrocadeSwitch
export def "data-sources-brocade-switches updateBrocadeSwitch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a brocade switch data source
#
# POST /data-sources/brocade-switches/{id}/disable
# operationId: disableBrocadeSwitch
export def "data-sources-brocade-switches-disable disableBrocadeSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a brocade switch data source
#
# POST /data-sources/brocade-switches/{id}/enable
# operationId: enableBrocadeSwitch
export def "data-sources-brocade-switches-enable enableBrocadeSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show snmp config for brocade switch data source
#
# GET /data-sources/brocade-switches/{id}/snmp-config
# operationId: getBrocadeSwitchSnmpConfig
export def "data-sources-brocade-switches-snmp-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)/snmp-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snmp config for brocade switch data source
#
# PUT /data-sources/brocade-switches/{id}/snmp-config
# operationId: updateBrocadeSwitchSnmpConfig
# --config_snmp_2c shape: {community_string?: string}
# --config_snmp_3 shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
export def "data-sources-brocade-switches-snmp-config updateBrocadeSwitchSnmpConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/brocade-switches/($id)/snmp-config")
  let body = {config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List checkpoint firewall data sources
#
# GET /data-sources/checkpoint-firewalls
# operationId: listCheckpointFirewalls
export def "data-sources-checkpoint-firewalls listCheckpointFirewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/checkpoint-firewalls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a checkpoint firewall
#
# POST /data-sources/checkpoint-firewalls
# operationId: addCheckpointFirewall
export def "data-sources-checkpoint-firewalls addCheckpointFirewall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/checkpoint-firewalls")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a checkpoint firewall data source
#
# DELETE /data-sources/checkpoint-firewalls/{id}
# operationId: deleteCheckpointFirewall
export def "data-sources-checkpoint-firewalls delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/checkpoint-firewalls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show checkpoint firewall data source details
#
# GET /data-sources/checkpoint-firewalls/{id}
# operationId: getCheckpointFirewall
export def "data-sources-checkpoint-firewalls get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/checkpoint-firewalls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a checkpoint firewall data source
#
# PUT /data-sources/checkpoint-firewalls/{id}
# operationId: updateCheckpointFirewall
export def "data-sources-checkpoint-firewalls updateCheckpointFirewall" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/checkpoint-firewalls/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a checkpoint firewall data source
#
# POST /data-sources/checkpoint-firewalls/{id}/disable
# operationId: disableCheckpointFirewall
export def "data-sources-checkpoint-firewalls-disable disableCheckpointFirewall" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/checkpoint-firewalls/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a checkpoint firewall data source
#
# POST /data-sources/checkpoint-firewalls/{id}/enable
# operationId: enableCheckpointFirewall
export def "data-sources-checkpoint-firewalls-enable enableCheckpointFirewall" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/checkpoint-firewalls/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List cisco switch data sources
#
# GET /data-sources/cisco-switches
# operationId: listCiscoSwitches
export def "data-sources-cisco-switches listCiscoSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/cisco-switches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a cisco switch data source
#
# POST /data-sources/cisco-switches
# operationId: addCiscoSwitch
export def "data-sources-cisco-switches addCiscoSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-type: string@switch-type-completer
]: any -> record<switch_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/cisco-switches")
  let body = {switch_type: $switch_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a cisco switch data source
#
# DELETE /data-sources/cisco-switches/{id}
# operationId: deleteCiscoSwitch
export def "data-sources-cisco-switches delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show cisco switch data source details
#
# GET /data-sources/cisco-switches/{id}
# operationId: getCiscoSwitch
export def "data-sources-cisco-switches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<switch_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a cisco switch data source
#
# PUT /data-sources/cisco-switches/{id}
# operationId: updateCiscoSwitch
export def "data-sources-cisco-switches updateCiscoSwitch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-type: string@switch-type-completer
]: any -> record<switch_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)")
  let body = {switch_type: $switch_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a cisco switch data source
#
# POST /data-sources/cisco-switches/{id}/disable
# operationId: disableCiscoSwitch
export def "data-sources-cisco-switches-disable disableCiscoSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a cisco switch data source
#
# POST /data-sources/cisco-switches/{id}/enable
# operationId: enableCiscoSwitch
export def "data-sources-cisco-switches-enable enableCiscoSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show snmp config for cisco switch data source
#
# GET /data-sources/cisco-switches/{id}/snmp-config
# operationId: getCiscoSwitchSnmpConfig
export def "data-sources-cisco-switches-snmp-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)/snmp-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snmp config for cisco switch data source
#
# PUT /data-sources/cisco-switches/{id}/snmp-config
# operationId: updateCiscoSwitchSnmpConfig
# --config_snmp_2c shape: {community_string?: string}
# --config_snmp_3 shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
export def "data-sources-cisco-switches-snmp-config updateCiscoSwitchSnmpConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/cisco-switches/($id)/snmp-config")
  let body = {config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List dell switch data sources
#
# GET /data-sources/dell-switches
# operationId: listDellSwitches
export def "data-sources-dell-switches listDellSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/dell-switches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a dell switch data source
#
# POST /data-sources/dell-switches
# operationId: addDellSwitch
export def "data-sources-dell-switches addDellSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-type: string@switch-type-completer-1
]: any -> record<switch_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/dell-switches")
  let body = {switch_type: $switch_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a dell switch data source
#
# DELETE /data-sources/dell-switches/{id}
# operationId: deleteDellSwitch
export def "data-sources-dell-switches delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show dell switch data source details
#
# GET /data-sources/dell-switches/{id}
# operationId: getDellSwitch
export def "data-sources-dell-switches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<switch_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a dell switch data source
#
# PUT /data-sources/dell-switches/{id}
# operationId: updateDellSwitch
export def "data-sources-dell-switches updateDellSwitch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-type: string@switch-type-completer-1
]: any -> record<switch_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)")
  let body = {switch_type: $switch_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a dell switch data source
#
# POST /data-sources/dell-switches/{id}/disable
# operationId: disableDellSwitch
export def "data-sources-dell-switches-disable disableDellSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a dell switch data source
#
# POST /data-sources/dell-switches/{id}/enable
# operationId: enableDellSwitch
export def "data-sources-dell-switches-enable enableDellSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show snmp config for dell switch data source
#
# GET /data-sources/dell-switches/{id}/snmp-config
# operationId: getDellSwitchSnmpConfig
export def "data-sources-dell-switches-snmp-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)/snmp-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snmp config for dell switch data source
#
# PUT /data-sources/dell-switches/{id}/snmp-config
# operationId: updateDellSwitchSnmpConfig
# --config_snmp_2c shape: {community_string?: string}
# --config_snmp_3 shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
export def "data-sources-dell-switches-snmp-config updateDellSwitchSnmpConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/dell-switches/($id)/snmp-config")
  let body = {config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List hp oneview manager data sources
#
# GET /data-sources/hpov-managers
# operationId: listHpovManagers
export def "data-sources-hpov-managers listHpovManagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/hpov-managers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a hp oneview manager data source
#
# POST /data-sources/hpov-managers
# operationId: addHpovManager
export def "data-sources-hpov-managers addHpovManager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/hpov-managers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a hp oneview data source
#
# DELETE /data-sources/hpov-managers/{id}
# operationId: deleteHpovManager
export def "data-sources-hpov-managers delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/hpov-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show hp oneview data source details
#
# GET /data-sources/hpov-managers/{id}
# operationId: getHpovManager
export def "data-sources-hpov-managers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/hpov-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a hp oneview data source
#
# PUT /data-sources/hpov-managers/{id}
# operationId: updateHpovManager
export def "data-sources-hpov-managers updateHpovManager" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/hpov-managers/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a hp oneview data source
#
# POST /data-sources/hpov-managers/{id}/disable
# operationId: disableHpovManager
export def "data-sources-hpov-managers-disable disableHpovManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/hpov-managers/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a hp oneview data source
#
# POST /data-sources/hpov-managers/{id}/enable
# operationId: enableHpovManager
export def "data-sources-hpov-managers-enable enableHpovManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/hpov-managers/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List hpvc manager data sources
#
# GET /data-sources/hpvc-managers
# operationId: listHpvcManagers
export def "data-sources-hpvc-managers listHpvcManagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/hpvc-managers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a hpvc manager data source
#
# POST /data-sources/hpvc-managers
# operationId: addHpvcManager
export def "data-sources-hpvc-managers addHpvcManager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/hpvc-managers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a hpvc manager data source
#
# DELETE /data-sources/hpvc-managers/{id}
# operationId: deleteHpvcManager
export def "data-sources-hpvc-managers delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/hpvc-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show hpvc data source details
#
# GET /data-sources/hpvc-managers/{id}
# operationId: getHpvcManager
export def "data-sources-hpvc-managers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/hpvc-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a hpvc manager data source
#
# PUT /data-sources/hpvc-managers/{id}
# operationId: updateHpvcManager
export def "data-sources-hpvc-managers updateHpvcManager" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/hpvc-managers/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a hpvc manager data source
#
# POST /data-sources/hpvc-managers/{id}/disable
# operationId: disableHpvcManager
export def "data-sources-hpvc-managers-disable disableHpvcManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/hpvc-managers/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a hpvc manager data source
#
# POST /data-sources/hpvc-managers/{id}/enable
# operationId: enableHpvcManager
export def "data-sources-hpvc-managers-enable enableHpvcManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/hpvc-managers/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List juniper switch data sources
#
# GET /data-sources/juniper-switches
# operationId: listJuniperSwitches
export def "data-sources-juniper-switches listJuniperSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/juniper-switches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a juniper switch as data source
#
# POST /data-sources/juniper-switches
# operationId: addJuniperSwitch
export def "data-sources-juniper-switches addJuniperSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/juniper-switches")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a juniper switch data source
#
# DELETE /data-sources/juniper-switches/{id}
# operationId: deleteJuniperSwitch
export def "data-sources-juniper-switches delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show juniper switch data source details
#
# GET /data-sources/juniper-switches/{id}
# operationId: getJuniperSwitch
export def "data-sources-juniper-switches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a juniper switch data source
#
# PUT /data-sources/juniper-switches/{id}
# operationId: updateJuniperSwitch
export def "data-sources-juniper-switches updateJuniperSwitch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a juniper switch data source
#
# POST /data-sources/juniper-switches/{id}/disable
# operationId: disableJuniperSwitch
export def "data-sources-juniper-switches-disable disableJuniperSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a juniper switch data source
#
# POST /data-sources/juniper-switches/{id}/enable
# operationId: enableJuniperSwitch
export def "data-sources-juniper-switches-enable enableJuniperSwitch" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show snmp config for juniper switch data source
#
# GET /data-sources/juniper-switches/{id}/snmp-config
# operationId: getJuniperSwitchSnmpConfig
export def "data-sources-juniper-switches-snmp-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)/snmp-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snmp config for a juniper switch data source
#
# PUT /data-sources/juniper-switches/{id}/snmp-config
# operationId: updateJuniperSwitchSnmpConfig
# --config_snmp_2c shape: {community_string?: string}
# --config_snmp_3 shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
export def "data-sources-juniper-switches-snmp-config updateJuniperSwitchSnmpConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/juniper-switches/($id)/snmp-config")
  let body = {config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List nsx-v manager data sources
#
# GET /data-sources/nsxv-managers
# operationId: listNsxvManagers
export def "data-sources-nsxv-managers listNsxvManagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/nsxv-managers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a nsx-v manager data source
#
# POST /data-sources/nsxv-managers
# operationId: addNsxvManagerDatasource
# --credentials shape: {password: string, username: string}
export def "data-sources-nsxv-managers addNsxvManagerDatasource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --central-cli-enabled: oneof<nothing, bool> # default: false
  credentials: record # shape: {password: string, username: string}
  --ipfix-enabled: oneof<nothing, bool> # default: false
  vcenter_id: string # Associated vcenter data source entity Id
]: any -> record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/nsxv-managers")
  let body = {enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, central_cli_enabled: $central_cli_enabled, credentials: $credentials, ipfix_enabled: $ipfix_enabled, vcenter_id: $vcenter_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a nsx-v manager data source
#
# DELETE /data-sources/nsxv-managers/{id}
# operationId: deleteNsxvManager
export def "data-sources-nsxv-managers delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show nsx-v manager data source details
#
# GET /data-sources/nsxv-managers/{id}
# operationId: getNsxvManager
export def "data-sources-nsxv-managers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a nsx-v manager data source
#
# PUT /data-sources/nsxv-managers/{id}
# operationId: updateNsxvManager
# --credentials shape: {password: string, username: string}
export def "data-sources-nsxv-managers updateNsxvManager" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --central-cli-enabled: oneof<nothing, bool> # default: false
  --credentials: record # shape: {password: string, username: string}
  --ipfix-enabled: oneof<nothing, bool> # default: false
  --vcenter-id: string # Associated vcenter data source entity Id
]: any -> record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, central_cli_enabled: bool, credentials: record<password: string, username: string>, ipfix_enabled: bool, vcenter_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)")
  let body = {enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, central_cli_enabled: $central_cli_enabled, credentials: $credentials, ipfix_enabled: $ipfix_enabled, vcenter_id: $vcenter_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show nsx controller-cluster details
#
# GET /data-sources/nsxv-managers/{id}/controller-cluster
# operationId: getNsxvControllerCluster
export def "data-sources-nsxv-managers-controller-cluster get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<controller_password: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)/controller-cluster")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update nsx controller-cluster details
#
# PUT /data-sources/nsxv-managers/{id}/controller-cluster
# operationId: updateNsxvControllerCluster
export def "data-sources-nsxv-managers-controller-cluster updateNsxvControllerCluster" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --controller-password: string
  --enabled: oneof<nothing, bool> # default: false
]: any -> record<controller_password: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)/controller-cluster")
  let body = {controller_password: $controller_password, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a nsx-v manager data source
#
# POST /data-sources/nsxv-managers/{id}/disable
# operationId: disableNsxvManager
export def "data-sources-nsxv-managers-disable disableNsxvManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a nsx-v manager data source
#
# POST /data-sources/nsxv-managers/{id}/enable
# operationId: enableNsxvManager
export def "data-sources-nsxv-managers-enable enableNsxvManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/nsxv-managers/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List panorama firewall data sources
#
# GET /data-sources/panorama-firewalls
# operationId: listPanoramaFirewalls
export def "data-sources-panorama-firewalls listPanoramaFirewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/panorama-firewalls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create panorama firewall data source
#
# POST /data-sources/panorama-firewalls
# operationId: addPanoramaFirewall
export def "data-sources-panorama-firewalls addPanoramaFirewall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/panorama-firewalls")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a panorama firewall data source
#
# DELETE /data-sources/panorama-firewalls/{id}
# operationId: deletePanoramaFirewall
export def "data-sources-panorama-firewalls delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/panorama-firewalls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show panorama firewall data source details
#
# GET /data-sources/panorama-firewalls/{id}
# operationId: getPanoramaFirewall
export def "data-sources-panorama-firewalls get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/panorama-firewalls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a panorama firewall data source
#
# PUT /data-sources/panorama-firewalls/{id}
# operationId: updatePanoramaFirewall
export def "data-sources-panorama-firewalls updatePanoramaFirewall" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/panorama-firewalls/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a panorama firewall data source
#
# POST /data-sources/panorama-firewalls/{id}/disable
# operationId: disablePanoramaFirewall
export def "data-sources-panorama-firewalls-disable disablePanoramaFirewall" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/panorama-firewalls/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a panorama firewall data source
#
# POST /data-sources/panorama-firewalls/{id}/enable
# operationId: enablePanoramaFirewall
export def "data-sources-panorama-firewalls-enable enablePanoramaFirewall" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/panorama-firewalls/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ucs manager data sources
#
# GET /data-sources/ucs-managers
# operationId: listUcsManagers
export def "data-sources-ucs-managers listUcsManagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/ucs-managers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an ucs manager data source
#
# POST /data-sources/ucs-managers
# operationId: addUcsManager
export def "data-sources-ucs-managers addUcsManager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/ucs-managers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an ucs manager data source
#
# DELETE /data-sources/ucs-managers/{id}
# operationId: deleteUcsManager
export def "data-sources-ucs-managers delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show ucs manager data source details
#
# GET /data-sources/ucs-managers/{id}
# operationId: getUcsManager
export def "data-sources-ucs-managers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an ucs manager data source
#
# PUT /data-sources/ucs-managers/{id}
# operationId: updateUcsManager
export def "data-sources-ucs-managers updateUcsManager" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable an ucs manager data source
#
# POST /data-sources/ucs-managers/{id}/disable
# operationId: disableUcsManager
export def "data-sources-ucs-managers-disable disableUcsManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable an ucs manager data source
#
# POST /data-sources/ucs-managers/{id}/enable
# operationId: enableUcsManager
export def "data-sources-ucs-managers-enable enableUcsManager" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show snmp config for ucs fabric interconnects
#
# GET /data-sources/ucs-managers/{id}/snmp-config
# operationId: getUcsSnmpConfig
export def "data-sources-ucs-managers-snmp-config get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)/snmp-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snmp config for ucs fabric interconnects
#
# PUT /data-sources/ucs-managers/{id}/snmp-config
# operationId: updateUcsSnmpConfig
# --config_snmp_2c shape: {community_string?: string}
# --config_snmp_3 shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
export def "data-sources-ucs-managers-snmp-config updateUcsSnmpConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-snmp-2c: record # shape: {community_string?: string}
  --config-snmp-3: record # shape: {authentication_password?: string, authentication_type?: "NO_AUTH"|"MD5"|"SHA", context_name?: string, privacy_password?: string, privacy_type?: "AES"|"DES"|"AES128"|"AES192"|"AES256"|"3DES"|"NO_PRIV", username?: string}
  --snmp-enabled: oneof<nothing, bool> # default: false
  --snmp-version: string@snmp-version-completer
]: any -> record<config_snmp_2c: record<community_string: string>, config_snmp_3: record<authentication_password: string, authentication_type: string, context_name: string, privacy_password: string, privacy_type: string, username: string>, snmp_enabled: bool, snmp_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/ucs-managers/($id)/snmp-config")
  let body = {config_snmp_2c: $config_snmp_2c, config_snmp_3: $config_snmp_3, snmp_enabled: $snmp_enabled, snmp_version: $snmp_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List vCenter data sources
#
# GET /data-sources/vcenters
# operationId: listVcenters
export def "data-sources-vcenters listVcenters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<results: table<entity_id: string, entity_type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/vcenters")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a vCenter data source
#
# POST /data-sources/vcenters
# operationId: addVcenterDatasource
# --credentials shape: {password: string, username: string}
export def "data-sources-vcenters addVcenterDatasource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --enabled: oneof<nothing, bool> # default: true
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  nickname: string # e.g. vc1
  --notes: string
  proxy_id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-sources/vcenters")
  let body = {enabled: $enabled, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a vCenter data source
#
# DELETE /data-sources/vcenters/{id}
# operationId: deleteVcenter
export def "data-sources-vcenters delete" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/vcenters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show vCenter data source details
#
# GET /data-sources/vcenters/{id}
# operationId: getVcenter
export def "data-sources-vcenters get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/vcenters/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a vCenter data source.
#
# PUT /data-sources/vcenters/{id}
# operationId: updateVcenter
# --credentials shape: {password: string, username: string}
export def "data-sources-vcenters updateVcenter" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # default: true
  --entity-id: string
  --entity-type: string@entity-type-completer
  --fqdn: string # e.g. your.domain.com
  --ip: string # e.g. 192.168.10.1
  --nickname: string # e.g. vc1
  --notes: string
  --proxy-id: string # proxy vm which should register this vcenter (e.g. 1000:104:12313412)
  --credentials: record # shape: {password: string, username: string}
]: any -> record<enabled: bool, entity_id: string, entity_type: string, fqdn: string, ip: string, nickname: string, notes: string, proxy_id: string, credentials: record<password: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-sources/vcenters/($id)")
  let body = {enabled: $enabled, entity_id: $entity_id, entity_type: $entity_type, fqdn: $fqdn, ip: $ip, nickname: $nickname, notes: $notes, proxy_id: $proxy_id, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a vCenter data source
#
# POST /data-sources/vcenters/{id}/disable
# operationId: disableVcenter
export def "data-sources-vcenters-disable disableVcenter" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/vcenters/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a vCenter data source
#
# POST /data-sources/vcenters/{id}/enable
# operationId: enableVcenter
export def "data-sources-vcenters-enable enableVcenter" [
  id: string
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
  let full_url = (build-url $base $"/data-sources/vcenters/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List clusters
#
# GET /entities/clusters
# operationId: listClusters
export def "entities-clusters listClusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/clusters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show cluster details
#
# GET /entities/clusters/{id}
# operationId: getCluster
export def "entities-clusters get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-4 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/clusters/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List datastores
#
# GET /entities/datastores
# operationId: listDatastores
export def "entities-datastores listDatastores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/datastores" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show datastore details
#
# GET /entities/datastores/{id}
# operationId: getDatastore
export def "entities-datastores get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-5 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/datastores/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List distributed virtual portgroups
#
# GET /entities/distributed-virtual-portgroups
# operationId: listDistributedVirtualPortgroups
export def "entities-distributed-virtual-portgroups listDistributedVirtualPortgroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/distributed-virtual-portgroups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show distributed virtual portgroup details
#
# GET /entities/distributed-virtual-portgroups/{id}
# operationId: getDistributedVirtualPortgroup
export def "entities-distributed-virtual-portgroups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-6 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/distributed-virtual-portgroups/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List distributed virtual switches
#
# GET /entities/distributed-virtual-switches
# operationId: listDistributedVirtualSwitches
export def "entities-distributed-virtual-switches listDistributedVirtualSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/distributed-virtual-switches" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show distributed virtual switch details
#
# GET /entities/distributed-virtual-switches/{id}
# operationId: getDistributedVirtualSwitch
export def "entities-distributed-virtual-switches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-7 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/distributed-virtual-switches/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List firewall rules
#
# GET /entities/firewall-rules
# operationId: listFirewallRules
export def "entities-firewall-rules listFirewallRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/firewall-rules" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show firewall rule details
#
# GET /entities/firewall-rules/{id}
# operationId: getFirewallRule
export def "entities-firewall-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-8 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, action: string, destination_any: bool, destination_inversion: bool, destinations: table<entity_id: string, entity_type: string>, disabled: bool, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, rule_id: string, section_id: string, section_name: string, sequence_number: int, service_any: bool, services: table<entity_id: string, entity_type: string>, source_any: bool, source_inversion: bool, sources: table<entity_id: string, entity_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/firewall-rules/($id)" $qp)
  let accept_val = ($accept | default "action")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List firewalls
#
# GET /entities/firewalls
# operationId: listFirewalls
export def "entities-firewalls listFirewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/firewalls" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show firewall details
#
# GET /entities/firewalls/{id}
# operationId: getFirewall
export def "entities-firewalls get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-9 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, action: string, destination_any: bool, destination_inversion: bool, destinations: table<entity_id: string, entity_type: string>, disabled: bool, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, rule_id: string, section_id: string, section_name: string, sequence_number: int, service_any: bool, services: table<entity_id: string, entity_type: string>, source_any: bool, source_inversion: bool, sources: table<entity_id: string, entity_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/firewalls/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List flows
#
# GET /entities/flows
# operationId: getFlows
export def "entities-flows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/flows" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show flow details
#
# GET /entities/flows/{id}
# operationId: getFlow
export def "entities-flows get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-10 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, destination_cluster: record<entity_id: string, entity_type: string>, destination_datacenter: record<entity_id: string, entity_type: string>, destination_folders: table<entity_id: string, entity_type: string>, destination_host: record<entity_id: string, entity_type: string>, destination_ip: record<ip_address: string, netmask: string, network_address: string>, destination_ip_sets: table<entity_id: string, entity_type: string>, destination_l2_network: record<entity_id: string, entity_type: string>, destination_resource_pool: record<entity_id: string, entity_type: string>, destination_security_groups: table<entity_id: string, entity_type: string>, destination_security_tags: table<entity_id: string, entity_type: string>, destination_vm: record<entity_id: string, entity_type: string>, destination_vm_tags: list<string>, destination_vnic: record<entity_id: string, entity_type: string>, destination_vpc: record<entity_id: string, entity_type: string>, firewall_action: string, flow_tag: list<string>, port: record<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, protocol: string, source_cluster: record<entity_id: string, entity_type: string>, source_datacenter: record<entity_id: string, entity_type: string>, source_folders: table<entity_id: string, entity_type: string>, source_host: record<entity_id: string, entity_type: string>, source_ip: record<ip_address: string, netmask: string, network_address: string>, source_ip_sets: table<entity_id: string, entity_type: string>, source_l2_network: record<entity_id: string, entity_type: string>, source_resource_pool: record<entity_id: string, entity_type: string>, source_security_groups: table<entity_id: string, entity_type: string>, source_security_tags: table<entity_id: string, entity_type: string>, source_vm: record<entity_id: string, entity_type: string>, source_vm_tags: list<string>, source_vnic: record<entity_id: string, entity_type: string>, source_vpc: record<entity_id: string, entity_type: string>, traffic_type: string, within_host: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/flows/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List folders
#
# GET /entities/folders
# operationId: listFolders
export def "entities-folders listFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/folders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show folder details
#
# GET /entities/folders/{id}
# operationId: getFolder
export def "entities-folders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-5 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/folders/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List hosts
#
# GET /entities/hosts
# operationId: listHosts
export def "entities-hosts listHosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/hosts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show host details
#
# GET /entities/hosts/{id}
# operationId: getHost
export def "entities-hosts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-11 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, cluster: record<entity_id: string, entity_type: string>, connection_state: string, datastores: table<entity_id: string, entity_type: string>, maintenance_mode: string, nsx_manager: record<entity_id: string, entity_type: string>, service_tag: string, vcenter_manager: record<entity_id: string, entity_type: string>, vendor_id: string, vm_count: int, vmknics: table<entity_id: string, entity_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/hosts/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ip sets
#
# GET /entities/ip-sets
# operationId: listIPSets
export def "entities-ip-sets listIPSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/ip-sets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show ip set details
#
# GET /entities/ip-sets/{id}
# operationId: getIPSet
export def "entities-ip-sets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-12 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, direct_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, direct_source_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_source_rules: table<firewall: record, rule_set_type: string, rules: list>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, ip_numeric_ranges: table<end: int, start: int>, ip_ranges: table<end_ip: string, start_ip: string>, parent_security_groups: table<entity_id: string, entity_type: string>, translated_vm_count: int, vendor: string, vendor_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/ip-sets/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List layer2 networks
#
# GET /entities/layer2-networks
# operationId: listLayer2Networks
export def "entities-layer2-networks listLayer2Networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/layer2-networks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show layer2 network details
#
# GET /entities/layer2-networks/{id}
# operationId: getLayer2Network
export def "entities-layer2-networks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-13 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, gateways: list<string>, network_addresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/layer2-networks/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get names for entities
#
# POST /entities/names
# operationId: getNames
# --entities item shape: {entity_id?: string, time?: int}
export def "entities-names post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: list # item shape: {entity_id?: string, time?: int}
]: any -> record<entities: table<entity_id: string, entity_type: string, time: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entities/names")
  let body = {entities: $entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get name of an entity
#
# GET /entities/names/{id}
# operationId: getName
export def "entities-names get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, time: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/names/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List nsx managers
#
# GET /entities/nsx-managers
# operationId: listNSXManagers
export def "entities-nsx-managers listNSXManagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/nsx-managers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show nsx manager details
#
# GET /entities/nsx-managers/{id}
# operationId: getNSXManager
export def "entities-nsx-managers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-14 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/nsx-managers/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List problems
#
# GET /entities/problems
# operationId: listProblemEvents
export def "entities-problems listProblemEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/problems" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show problem details
#
# GET /entities/problems/{id}
# operationId: getProblemEvent
export def "entities-problems get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-15 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<event_close_time_epoch_ms: int, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/problems/($id)" $qp)
  let accept_val = ($accept | default "admin_state")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List security groups
#
# GET /entities/security-groups
# operationId: listSecurityGroups
export def "entities-security-groups listSecurityGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/security-groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show security group details
#
# GET /entities/security-groups/{id}
# operationId: getSecurityGroup
export def "entities-security-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-16 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<direct_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, direct_members: table<entity_id: string, entity_type: string>, direct_source_rules: table<firewall: record, rule_set_type: string, rules: list>, excluded_members: table<entity_id: string, entity_type: string>, indirect_destination_rules: table<firewall: record, rule_set_type: string, rules: list>, indirect_source_rules: table<firewall: record, rule_set_type: string, rules: list>, members: table<entity_id: string, entity_type: string>, parents: table<entity_id: string, entity_type: string>, translated_vm_count: int, vendor_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/security-groups/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List security tags
#
# GET /entities/security-tags
# operationId: listSecurityTags
export def "entities-security-tags listSecurityTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/security-tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show security tag details
#
# GET /entities/security-tags/{id}
# operationId: getSecurityTag
export def "entities-security-tags get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-17 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, description: string, direct_security_groups: table<entity_id: string, entity_type: string>, nsx_manager: record<entity_id: string, entity_type: string>, security_groups: table<entity_id: string, entity_type: string>, vendor_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/security-tags/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List service groups
#
# GET /entities/service-groups
# operationId: listServiceGroups
export def "entities-service-groups listServiceGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/service-groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show service group details
#
# GET /entities/service-groups/{id}
# operationId: getServiceGroup
export def "entities-service-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-18 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/service-groups/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List services
#
# GET /entities/services
# operationId: listServices
export def "entities-services listServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/services" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show service details
#
# GET /entities/services/{id}
# operationId: getService
export def "entities-services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-19 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, port_ranges: table<display: string, end: int, iana_name: string, iana_port_display: string, start: int>, protocol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/services/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List vCenter datacenters
#
# GET /entities/vc-datacenters
# operationId: listDatacenters
export def "entities-vc-datacenters listDatacenters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/vc-datacenters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show vCenter datacenter details
#
# GET /entities/vc-datacenters/{id}
# operationId: getDatacenter
export def "entities-vc-datacenters get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-5 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/vc-datacenters/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List vCenter managers
#
# GET /entities/vcenter-managers
# operationId: listVcenterManagers
export def "entities-vcenter-managers listVcenterManagers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/vcenter-managers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show vCenter manager details
#
# GET /entities/vcenter-managers/{id}
# operationId: getVcenterManager
export def "entities-vcenter-managers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-20 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<fqdn: string, ip_address: record<ip_address: string, netmask: string, network_address: string>, nsx_manager: record<entity_id: string, entity_type: string>, vm: record<entity_id: string, entity_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/vcenter-managers/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List vmknics
#
# GET /entities/vmknics
# operationId: listVmknics
export def "entities-vmknics listVmknics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/vmknics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show vmknic details
#
# GET /entities/vmknics/{id}
# operationId: getVmknic
export def "entities-vmknics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-21 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, host: record<entity_id: string, entity_type: string>, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, layer2_network: record<entity_id: string, entity_type: string>, vlan: record<begin: int, end: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/vmknics/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List vms
#
# GET /entities/vms
# operationId: listVms
export def "entities-vms listVms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/vms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show vm details
#
# GET /entities/vms/{id}
# operationId: getVm
export def "entities-vms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-22 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/vms/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List vnics
#
# GET /entities/vnics
# operationId: listVnics
export def "entities-vnics listVnics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/vnics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show vnic details
#
# GET /entities/vnics/{id}
# operationId: getVnic
export def "entities-vnics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-23 # Response content type
  --time: int # time in epoch seconds (format: int64)
]: nothing -> record<entity_id: string, entity_type: string, name: string, ip_addresses: table<ip_address: string, netmask: string, network_address: string>, layer2_network: record<entity_id: string, entity_type: string>, vlan: record<begin: int, end: int>, vm: record<entity_id: string, entity_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entities/vnics/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List applications
#
# GET /groups/applications
# operationId: listApplications
export def "groups-applications listApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --size: float # page size of results (default: 10)
  --cursor: string # cursor from previous response
  --start-time: float # start time for query in epoch seconds
  --end-time: float # end time for query in epoch seconds
]: nothing -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string>, start_time: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/applications" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an application
#
# POST /groups/applications
# operationId: addApplication
export def "groups-applications addApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-24 # Response content type
  --name: string
]: any -> record<entity_id: string, entity_type: string, name: string, create_time: int, created_by: string, last_modified_by: string, last_modified_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/applications")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an application
#
# DELETE /groups/applications/{id}
# operationId: deleteApplication
export def "groups-applications delete" [
  id: string
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
  let full_url = (build-url $base $"/groups/applications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show application details
#
# GET /groups/applications/{id}
# operationId: getApplication
export def "groups-applications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-24 # Response content type
]: nothing -> record<entity_id: string, entity_type: string, name: string, create_time: int, created_by: string, last_modified_by: string, last_modified_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/applications/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tiers of an application
#
# GET /groups/applications/{id}/tiers
# operationId: listApplicationTiers
export def "groups-applications-tiers listApplicationTiers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-25 # Response content type
]: nothing -> record<results: table<entity_id: string, entity_type: string, name: string, application: record, group_membership_criteria: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/applications/($id)/tiers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tier in application
#
# POST /groups/applications/{id}/tiers
# operationId: addTier
# --group_membership_criteria item shape: {ip_address_membership_criteria?: record, membership_type?: "SearchMembershipCriteria"|"IPAddressMembershipCriteria", search_membership_criteria?: record}
export def "groups-applications-tiers addTier" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-26 # Response content type
  --group-membership-criteria: list # item shape: {ip_address_membership_criteria?: record, membership_type?: "SearchMembershipCriteria"|"IPAddressMembershipCriteria", search_membership_criteria?: record}
  --name: string
]: any -> record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/applications/($id)/tiers")
  let body = {group_membership_criteria: $group_membership_criteria, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete tier
#
# DELETE /groups/applications/{id}/tiers/{tier-id}
# operationId: deleteTier
export def "groups-applications-tiers delete" [
  id: string
  tier_id: string
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
  let full_url = (build-url $base $"/groups/applications/($id)/tiers/($tier_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show tier details
#
# GET /groups/applications/{id}/tiers/{tier-id}
# operationId: getApplicationTier
export def "groups-applications-tiers get" [
  id: string
  tier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-26 # Response content type
]: nothing -> record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/applications/($id)/tiers/($tier_id)")
  let accept_val = ($accept | default "application")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show tier details
#
# GET /groups/tiers/{tier-id}
# operationId: getTier
export def "groups-tiers get" [
  tier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-26 # Response content type
  --Authorization: string # Authorization Header
]: nothing -> record<entity_id: string, entity_type: string, name: string, application: record<entity_id: string, entity_type: string>, group_membership_criteria: table<ip_address_membership_criteria: record, membership_type: string, search_membership_criteria: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/tiers/($tier_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show version info
#
# GET /info/version
# operationId: getVersion
export def "info-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List nodes
#
# GET /infra/nodes
# operationId: listNodes
export def "infra-nodes listNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<results: table<entity_type: string, id: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/infra/nodes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show node details
#
# GET /infra/nodes/{id}
# operationId: getNode
export def "infra-nodes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-27 # Response content type
]: nothing -> record<entity_type: string, id: string, ip_address: string, name: string, node_id: string, node_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/infra/nodes/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logical recommended rules
#
# POST /micro-seg/recommended-rules
# operationId: listRecommendedRules
# --group_1 shape: {entity?: record}
# --group_2 shape: {entity?: record}
# --time_range shape: {end_time?: int, start_time?: int}
export def "micro-seg-recommended-rules listRecommendedRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-28 # Response content type
  --group-1: record # shape: {entity?: record}
  --group-2: record # shape: {entity?: record}
  --time-range: record # shape: {end_time?: int, start_time?: int}
]: any -> record<results: table<action: string, destinations: list, port_ranges: list, protocols: list, sources: list>, time_range: record<end_time: int, start_time: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/micro-seg/recommended-rules")
  let body = {group_1: $group_1, group_2: $group_2, time_range: $time_range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export recommended rules for NSX-V
#
# POST /micro-seg/recommended-rules/nsx
# operationId: exportNsxRecommendedRules
# --group_1 shape: {entity?: record}
# --group_2 shape: {entity?: record}
# --time_range shape: {end_time?: int, start_time?: int}
export def "micro-seg-recommended-rules-nsx exportNsxRecommendedRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-1: record # shape: {entity?: record}
  --group-2: record # shape: {entity?: record}
  --time-range: record # shape: {end_time?: int, start_time?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/micro-seg/recommended-rules/nsx")
  let body = {group_1: $group_1, group_2: $group_2, time_range: $time_range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search entities
#
# POST /search
# operationId: searchEntities
# --sort_by shape: {field?: string, order?: "ASC"|"DESC"}
# --time_range shape: {end_time?: int, start_time?: int}
export def "search searchEntities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --entity-type: string@entity-type-completer-1
  --filter: string # query filter
  --size: int # format: int32
  --sort-by: record # shape: {field?: string, order?: "ASC"|"DESC"}
  --time-range: record # shape: {end_time?: int, start_time?: int}
]: any -> record<cursor: string, end_time: int, results: table<entity_id: string, entity_type: string, time: int>, start_time: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search")
  let body = {cursor: $cursor, entity_type: $entity_type, filter: $filter, size: $size, sort_by: $sort_by, time_range: $time_range} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
