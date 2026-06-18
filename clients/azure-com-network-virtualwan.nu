# Auto-generated client for VirtualWANAsAServiceManagementClient v2019-07-01
# Source: https://api.apis.guru/v2/specs/azure.com/network-virtualWan/2019-07-01/swagger.json
# Auth: --token flag or $env.VIRTUALWANASASERVICEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VIRTUALWANASASERVICEMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def authentication-method-completer [] { ["EAPMSCHAPv2" "EAPTLS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-network-p2svpn-gateways list-p2s-vpn" } } | get name | first)
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

# Lists all the P2SVpnGateways in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/p2svpnGateways
# operationId: P2sVpnGateways_List
export def "subscriptions-providers-microsoft-network-p2svpn-gateways list-p2s-vpn" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/p2svpnGateways") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the VirtualHubs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualHubs
# operationId: VirtualHubs_List
export def "subscriptions-providers-microsoft-network-virtual-hubs list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/virtualHubs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the VirtualWANs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualWans
# operationId: VirtualWans_List
export def "subscriptions-providers-microsoft-network-virtual-wans list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/virtualWans") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the VpnGateways in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/vpnGateways
# operationId: VpnGateways_List
export def "subscriptions-providers-microsoft-network-vpn-gateways list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/vpnGateways") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the VpnSites in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/vpnSites
# operationId: VpnSites_List
export def "subscriptions-providers-microsoft-network-vpn-sites list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/vpnSites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the P2SVpnGateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways
# operationId: P2sVpnGateways_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways list-p2s-vpn" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a virtual wan p2s vpn gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# operationId: P2sVpnGateways_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways delete-p2s-vpn" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways/{gateway_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a virtual wan p2s vpn gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# operationId: P2sVpnGateways_Get
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways get-p2s-vpn" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways/{gateway_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates virtual wan p2s vpn gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# operationId: P2sVpnGateways_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways update-p2s-vpn-tags" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways/{gateway_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a virtual wan p2s vpn gateway if it doesn't exist else updates the existing gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# operationId: P2sVpnGateways_CreateOrUpdate
# --properties shape: {customRoutes?: any, p2SVpnServerConfiguration?: any, virtualHub?: any, vpnClientAddressPool?: any, vpnClientConnectionHealth?: any, vpnGatewayScaleUnit?: int}
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways create-p2s-vpn-or-update" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Parameters for P2SVpnGateway. — shape: {customRoutes?: any, p2SVpnServerConfiguration?: any, virtualHub?: any, vpnClientAddressPool?: any, vpnClientConnectionHealth?: any, vpnGatewayScaleUnit?: int}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Generates VPN profile for P2S client of the P2SVpnGateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}/generatevpnprofile
# operationId: P2sVpnGateways_GenerateVpnProfile
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways-generatevpnprofile generate-p2s-vpn-vpn-profile" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --authentication-method: string@authentication-method-completer # VPN client authentication method.
]: any -> record<profileUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways/{gateway_name}/generatevpnprofile") $qp)
  let req_body = {"authenticationMethod": $authentication_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the connection health of P2S clients of the virtual wan P2SVpnGateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}/getP2sVpnConnectionHealth
# operationId: P2sVpnGateways_GetP2sVpnConnectionHealth
export def "subscriptions-resource-groups-providers-microsoft-network-p2svpn-gateways-get-p2s-vpn-connection-health get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/p2svpnGateways/{gateway_name}/getP2sVpnConnectionHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the VirtualHubs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs
# operationId: VirtualHubs_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a VirtualHub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# operationId: VirtualHubs_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs delete" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_hub_name: (encode-path-segment $virtual_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs/{virtual_hub_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a VirtualHub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# operationId: VirtualHubs_Get
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs get" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_hub_name: (encode-path-segment $virtual_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs/{virtual_hub_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates VirtualHub tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# operationId: VirtualHubs_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs update-tags" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_hub_name: (encode-path-segment $virtual_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs/{virtual_hub_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a VirtualHub resource if it doesn't exist else updates the existing VirtualHub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# operationId: VirtualHubs_CreateOrUpdate
# --properties shape: {addressPrefix?: string, expressRouteGateway?: any, p2SVpnGateway?: any, routeTable?: any, virtualNetworkConnections?: list, virtualWan?: any, vpnGateway?: any}
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Parameters for VirtualHub. — shape: {addressPrefix?: string, expressRouteGateway?: any, p2SVpnGateway?: any, routeTable?: any, virtualNetworkConnections?: list, virtualWan?: any, vpnGateway?: any}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_hub_name: (encode-path-segment $virtual_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs/{virtual_hub_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the details of all HubVirtualNetworkConnections.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}/hubVirtualNetworkConnections
# operationId: HubVirtualNetworkConnections_List
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs-hub-virtual-network-connections list" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_hub_name: (encode-path-segment $virtual_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs/{virtual_hub_name}/hubVirtualNetworkConnections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a HubVirtualNetworkConnection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}/hubVirtualNetworkConnections/{connectionName}
# operationId: HubVirtualNetworkConnections_Get
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-hubs-hub-virtual-network-connections get" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<allowHubToRemoteVnetTransit: bool, allowRemoteVnetToUseHubVnetGateways: bool, enableInternetSecurity: bool, provisioningState: string, remoteVirtualNetwork: record<id: string>>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_hub_name: (encode-path-segment $virtual_hub_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualHubs/{virtual_hub_name}/hubVirtualNetworkConnections/{connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the VirtualWANs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans
# operationId: VirtualWans_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a VirtualWAN.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# operationId: VirtualWans_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans delete" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a VirtualWAN.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# operationId: VirtualWans_Get
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans get" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a VirtualWAN tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# operationId: VirtualWans_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans update-tags" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a VirtualWAN resource if it doesn't exist else updates the existing VirtualWAN.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# operationId: VirtualWans_CreateOrUpdate
# --properties shape: {allowBranchToBranchTraffic?: bool, allowVnetToVnetTraffic?: bool, disableVpnEncryption?: bool, p2SVpnServerConfigurations?: list, securityProviderName?: string}
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Parameters for VirtualWAN. — shape: {allowBranchToBranchTraffic?: bool, allowVnetToVnetTraffic?: bool, disableVpnEncryption?: bool, p2SVpnServerConfigurations?: list, securityProviderName?: string}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gives the supported security providers for the virtual wan.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWANName}/supportedSecurityProviders
# operationId: SupportedSecurityProviders
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans-supported-security-providers get" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<supportedProviders: table<name: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}/supportedSecurityProviders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gives the sas-url to download the configurations for vpn-sites in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWANName}/vpnConfiguration
# operationId: VpnSitesConfiguration_Download
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans-vpn-configuration download-sites" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  output_blob_sas_url: string # The sas-url to download the configurations for vpn-sites.
  --vpn-sites: list<string> # List of resource-ids of the vpn-sites for which config is to be downloaded.
]: any -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}/vpnConfiguration") $qp)
  let req_body = {"outputBlobSasUrl": $output_blob_sas_url, "vpnSites": $vpn_sites} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves all P2SVpnServerConfigurations for a particular VirtualWan.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations
# operationId: P2sVpnServerConfigurations_ListByVirtualWan
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans-p2s-vpn-server-configurations list" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}/p2sVpnServerConfigurations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a P2SVpnServerConfiguration.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}
# operationId: P2sVpnServerConfigurations_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans-p2s-vpn-server-configurations delete" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  p2_s_vpn_server_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name), p2_s_vpn_server_configuration_name: (encode-path-segment $p2_s_vpn_server_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}/p2sVpnServerConfigurations/{p2_s_vpn_server_configuration_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a P2SVpnServerConfiguration.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}
# operationId: P2sVpnServerConfigurations_Get
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans-p2s-vpn-server-configurations get" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  p2_s_vpn_server_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<etag: string, name: string, p2SVpnGateways: list<record>, p2SVpnServerConfigRadiusClientRootCertificates: list<record>, p2SVpnServerConfigRadiusServerRootCertificates: list<record>, p2SVpnServerConfigVpnClientRevokedCertificates: list<record>, p2SVpnServerConfigVpnClientRootCertificates: list<record>, provisioningState: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientIpsecPolicies: list<record>, vpnProtocols: list<string>>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name), p2_s_vpn_server_configuration_name: (encode-path-segment $p2_s_vpn_server_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}/p2sVpnServerConfigurations/{p2_s_vpn_server_configuration_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a P2SVpnServerConfiguration to associate with a VirtualWan if it doesn't exist else updates the existing P2SVpnServerConfiguration.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}
# operationId: P2sVpnServerConfigurations_CreateOrUpdate
# --properties shape: {etag?: string, name?: string, p2SVpnServerConfigRadiusClientRootCertificates?: list, p2SVpnServerConfigRadiusServerRootCertificates?: list, p2SVpnServerConfigVpnClientRevokedCertificates?: list, p2SVpnServerConfigVpnClientRootCertificates?: list, radiusServerAddress?: string, radiusServerSecret?: string, vpnClientIpsecPolicies?: list, vpnProtocols?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-network-virtual-wans-p2s-vpn-server-configurations create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  p2_s_vpn_server_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --name: string # The name of the resource that is unique within a resource group. This name can be used to access the resource.
  --properties: any # Parameters for P2SVpnServerConfiguration. — shape: {etag?: string, name?: string, p2SVpnServerConfigRadiusClientRootCertificates?: list, p2SVpnServerConfigRadiusServerRootCertificates?: list, p2SVpnServerConfigVpnClientRevokedCertificates?: list, p2SVpnServerConfigVpnClientRootCertificates?: list, radiusServerAddress?: string, radiusServerSecret?: string, vpnClientIpsecPolicies?: list, vpnProtocols?: list<string>}
  --id: string # Resource ID.
]: any -> record<etag: string, name: string, properties: record<etag: string, name: string, p2SVpnGateways: list<record>, p2SVpnServerConfigRadiusClientRootCertificates: list<record>, p2SVpnServerConfigRadiusServerRootCertificates: list<record>, p2SVpnServerConfigVpnClientRevokedCertificates: list<record>, p2SVpnServerConfigVpnClientRootCertificates: list<record>, provisioningState: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientIpsecPolicies: list<record>, vpnProtocols: list<string>>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_wan_name: (encode-path-segment $virtual_wan_name), p2_s_vpn_server_configuration_name: (encode-path-segment $p2_s_vpn_server_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/virtualWans/{virtual_wan_name}/p2sVpnServerConfigurations/{p2_s_vpn_server_configuration_name}") $qp)
  let req_body = {"name": $name, "properties": $properties, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all the VpnGateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways
# operationId: VpnGateways_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a virtual wan vpn gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# operationId: VpnGateways_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways delete" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a virtual wan vpn gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# operationId: VpnGateways_Get
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates virtual wan vpn gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# operationId: VpnGateways_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways update-tags" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a virtual wan vpn gateway if it doesn't exist else updates the existing gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# operationId: VpnGateways_CreateOrUpdate
# --properties shape: {bgpSettings?: any, connections?: list, virtualHub?: any, vpnGatewayScaleUnit?: int}
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways create-or-update" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Parameters for VpnGateway. — shape: {bgpSettings?: any, connections?: list, virtualHub?: any, vpnGatewayScaleUnit?: int}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resets the primary of the vpn gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/reset
# operationId: VpnGateways_Reset
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-reset reset" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/reset") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all vpn connections for a particular virtual wan vpn gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections
# operationId: VpnConnections_ListByVpnGateway
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-vpn-connections list" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/vpnConnections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a vpn connection.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}
# operationId: VpnConnections_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-vpn-connections delete" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/vpnConnections/{connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a vpn connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}
# operationId: VpnConnections_Get
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-vpn-connections get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableInternetSecurity: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, remoteVpnSite: record<id: string>, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnLinkConnections: list<record>>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/vpnConnections/{connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a vpn connection to a scalable vpn gateway if it doesn't exist else updates the existing connection.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}
# operationId: VpnConnections_CreateOrUpdate
# --properties shape: {connectionBandwidth?: int, enableBgp?: bool, enableInternetSecurity?: bool, enableRateLimiting?: bool, ipsecPolicies?: list, remoteVpnSite?: any, routingWeight?: int, sharedKey?: string, useLocalAzureIpAddress?: bool, usePolicyBasedTrafficSelectors?: bool, vpnConnectionProtocolType?: "IKEv2"|"IKEv1", vpnLinkConnections?: list}
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-vpn-connections create-or-update" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --name: string # The name of the resource that is unique within a resource group. This name can be used to access the resource.
  --properties: any # Parameters for VpnConnection. — shape: {connectionBandwidth?: int, enableBgp?: bool, enableInternetSecurity?: bool, enableRateLimiting?: bool, ipsecPolicies?: list, remoteVpnSite?: any, routingWeight?: int, sharedKey?: string, useLocalAzureIpAddress?: bool, usePolicyBasedTrafficSelectors?: bool, vpnConnectionProtocolType?: "IKEv2"|"IKEv1", vpnLinkConnections?: list}
  --id: string # Resource ID.
]: any -> record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableInternetSecurity: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, remoteVpnSite: record<id: string>, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnLinkConnections: list<record>>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/vpnConnections/{connection_name}") $qp)
  let req_body = {"name": $name, "properties": $properties, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves all vpn site link connections for a particular virtual wan vpn gateway vpn connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}/vpnLinkConnections
# operationId: VpnLinkConnections_ListByVpnConnection
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-vpn-connections-vpn-link-connections list" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, name: string, properties: record, type: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/vpnConnections/{connection_name}/vpnLinkConnections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a vpn site link connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}/vpnLinkConnections/{linkConnectionName}
# operationId: VpnSiteLinkConnections_Get
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-gateways-vpn-connections-vpn-link-connections get-site" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  link_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnSiteLink: record<id: string>>, type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), gateway_name: (encode-path-segment $gateway_name), connection_name: (encode-path-segment $connection_name), link_connection_name: (encode-path-segment $link_connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnGateways/{gateway_name}/vpnConnections/{connection_name}/vpnLinkConnections/{link_connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the vpnSites in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites
# operationId: VpnSites_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a VpnSite.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# operationId: VpnSites_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites delete" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, innerError: string, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vpn_site_name: (encode-path-segment $vpn_site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites/{vpn_site_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a VPN site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# operationId: VpnSites_Get
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites get" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vpn_site_name: (encode-path-segment $vpn_site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites/{vpn_site_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates VpnSite tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# operationId: VpnSites_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites update-tags" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vpn_site_name: (encode-path-segment $vpn_site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites/{vpn_site_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a VpnSite resource if it doesn't exist else updates the existing VpnSite.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# operationId: VpnSites_CreateOrUpdate
# --properties shape: {addressSpace?: any, bgpProperties?: any, deviceProperties?: any, ipAddress?: string, isSecuritySite?: bool, siteKey?: string, virtualWan?: any, vpnSiteLinks?: list}
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites create-or-update" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Parameters for VpnSite. — shape: {addressSpace?: any, bgpProperties?: any, deviceProperties?: any, ipAddress?: string, isSecuritySite?: bool, siteKey?: string, virtualWan?: any, vpnSiteLinks?: list}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vpn_site_name: (encode-path-segment $vpn_site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites/{vpn_site_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all the vpnSiteLinks in a resource group for a vpn site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}/vpnSiteLinks
# operationId: VpnSiteLinks_ListByVpnSite
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites-vpn-site-links list" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<etag: string, name: string, properties: record, type: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vpn_site_name: (encode-path-segment $vpn_site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites/{vpn_site_name}/vpnSiteLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the details of a VPN site link.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}/vpnSiteLinks/{vpnSiteLinkName}
# operationId: VpnSiteLinks_Get
export def "subscriptions-resource-groups-providers-microsoft-network-vpn-sites-vpn-site-links get" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  vpn_site_link_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<bgpProperties: record<asn: int, bgpPeeringAddress: string>, ipAddress: string, linkProperties: record<linkProviderName: string, linkSpeedInMbps: int>, provisioningState: string>, type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vpn_site_name: (encode-path-segment $vpn_site_name), vpn_site_link_name: (encode-path-segment $vpn_site_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/vpnSites/{vpn_site_name}/vpnSiteLinks/{vpn_site_link_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
