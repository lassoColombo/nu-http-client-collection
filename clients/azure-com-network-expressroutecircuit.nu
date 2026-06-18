# Auto-generated client for NetworkManagementClient v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/network-expressRouteCircuit/2019-08-01/swagger.json
# Auth: --token flag or $env.NETWORKMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETWORKMANAGEMENTCLIENT_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-network-express-route-circuits list-list" } } | get name | first)
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

# Gets all the express route circuits in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/expressRouteCircuits
# operationId: ExpressRouteCircuits_ListAll
export def "subscriptions-providers-microsoft-network-express-route-circuits list-list" [
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
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/expressRouteCircuits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the available express route service providers.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/expressRouteServiceProviders
# operationId: ExpressRouteServiceProviders_List
export def "subscriptions-providers-microsoft-network-express-route-service-providers list" [
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/expressRouteServiceProviders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the express route circuits in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits
# operationId: ExpressRouteCircuits_List
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits list" [
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
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified express route circuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# operationId: ExpressRouteCircuits_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# operationId: ExpressRouteCircuits_Get
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, bandwidthInGbps: float, circuitProvisioningState: string, expressRoutePort: record<id: string>, gatewayManagerEtag: string, globalReachEnabled: bool, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string, stag: int>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an express route circuit tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# operationId: ExpressRouteCircuits_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits update-tags" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
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
]: any -> record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, bandwidthInGbps: float, circuitProvisioningState: string, expressRoutePort: record<id: string>, gatewayManagerEtag: string, globalReachEnabled: bool, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string, stag: int>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or updates an express route circuit.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# operationId: ExpressRouteCircuits_CreateOrUpdate
# --properties shape: {allowClassicOperations?: bool, authorizations?: list, bandwidthInGbps?: float, circuitProvisioningState?: string, expressRoutePort?: any, gatewayManagerEtag?: string, globalReachEnabled?: bool, peerings?: list, serviceKey?: string, serviceProviderNotes?: string, serviceProviderProperties?: any, serviceProviderProvisioningState?: "NotProvisioned"|"Provisioning"|"Provisioned"|"Deprovisioning"}
# --sku shape: {family?: "UnlimitedData"|"MeteredData", name?: string, tier?: "Standard"|"Premium"|"Basic"|"Local"}
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Properties of ExpressRouteCircuit. — shape: {allowClassicOperations?: bool, authorizations?: list, bandwidthInGbps?: float, circuitProvisioningState?: string, expressRoutePort?: any, gatewayManagerEtag?: string, globalReachEnabled?: bool, peerings?: list, serviceKey?: string, serviceProviderNotes?: string, serviceProviderProperties?: any, serviceProviderProvisioningState?: "NotProvisioned"|"Provisioning"|"Provisioned"|"Deprovisioning"}
  --sku: any # Contains SKU in an ExpressRouteCircuit. — shape: {family?: "UnlimitedData"|"MeteredData", name?: string, tier?: "Standard"|"Premium"|"Basic"|"Local"}
  --id: string # Resource ID.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, bandwidthInGbps: float, circuitProvisioningState: string, expressRoutePort: record<id: string>, gatewayManagerEtag: string, globalReachEnabled: bool, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string, stag: int>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets all authorizations in an express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations
# operationId: ExpressRouteCircuitAuthorizations_List
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-authorizations list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/authorizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified authorization from the specified express route circuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}
# operationId: ExpressRouteCircuitAuthorizations_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-authorizations delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  authorization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), authorization_name: (encode-path-segment $authorization_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/authorizations/{authorization_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified authorization from the specified express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}
# operationId: ExpressRouteCircuitAuthorizations_Get
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-authorizations get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  authorization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<authorizationKey: string, authorizationUseStatus: string, provisioningState: string>, type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), authorization_name: (encode-path-segment $authorization_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/authorizations/{authorization_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an authorization in the specified express route circuit.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}
# operationId: ExpressRouteCircuitAuthorizations_CreateOrUpdate
# --properties shape: {authorizationKey?: string, authorizationUseStatus?: "Available"|"InUse"}
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-authorizations create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  authorization_name: string
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
  --properties: any # Properties of ExpressRouteCircuitAuthorization. — shape: {authorizationKey?: string, authorizationUseStatus?: "Available"|"InUse"}
  --id: string # Resource ID.
]: any -> record<etag: string, name: string, properties: record<authorizationKey: string, authorizationUseStatus: string, provisioningState: string>, type: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), authorization_name: (encode-path-segment $authorization_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/authorizations/{authorization_name}") $qp)
  let req_body = {"name": $name, "properties": $properties, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets all peerings in a specified express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings
# operationId: ExpressRouteCircuitPeerings_List
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified peering from the specified express route circuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}
# operationId: ExpressRouteCircuitPeerings_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified peering for the express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}
# operationId: ExpressRouteCircuitPeerings_Get
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, name: string, properties: record<azureASN: int, connections: list<record>, expressRouteConnection: record<id: string>, gatewayManagerEtag: string, ipv6PeeringConfig: record<microsoftPeeringConfig: record, primaryPeerAddressPrefix: string, routeFilter: record, secondaryPeerAddressPrefix: string, state: string>, lastModifiedBy: string, microsoftPeeringConfig: record<advertisedCommunities: list, advertisedPublicPrefixes: list, advertisedPublicPrefixesState: string, customerASN: int, legacyMode: int, routingRegistryName: string>, peerASN: int, peeredConnections: list<record>, peeringType: string, primaryAzurePort: string, primaryPeerAddressPrefix: string, provisioningState: string, routeFilter: record<id: string>, secondaryAzurePort: string, secondaryPeerAddressPrefix: string, sharedKey: string, state: string, stats: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>, vlanId: int>, type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a peering in the specified express route circuits.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}
# operationId: ExpressRouteCircuitPeerings_CreateOrUpdate
# --properties shape: {azureASN?: int, connections?: list, expressRouteConnection?: any, gatewayManagerEtag?: string, ipv6PeeringConfig?: any, lastModifiedBy?: string, microsoftPeeringConfig?: any, peerASN?: int, peeringType?: "AzurePublicPeering"|"AzurePrivatePeering"|"MicrosoftPeering", primaryAzurePort?: string, primaryPeerAddressPrefix?: string, routeFilter?: any, secondaryAzurePort?: string, secondaryPeerAddressPrefix?: string, sharedKey?: string, state?: "Disabled"|"Enabled", stats?: any, vlanId?: int}
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
  --properties: any # Properties of the express route circuit peering. — shape: {azureASN?: int, connections?: list, expressRouteConnection?: any, gatewayManagerEtag?: string, ipv6PeeringConfig?: any, lastModifiedBy?: string, microsoftPeeringConfig?: any, peerASN?: int, peeringType?: "AzurePublicPeering"|"AzurePrivatePeering"|"MicrosoftPeering", primaryAzurePort?: string, primaryPeerAddressPrefix?: string, routeFilter?: any, secondaryAzurePort?: string, secondaryPeerAddressPrefix?: string, sharedKey?: string, state?: "Disabled"|"Enabled", stats?: any, vlanId?: int}
  --id: string # Resource ID.
]: any -> record<etag: string, name: string, properties: record<azureASN: int, connections: list<record>, expressRouteConnection: record<id: string>, gatewayManagerEtag: string, ipv6PeeringConfig: record<microsoftPeeringConfig: record, primaryPeerAddressPrefix: string, routeFilter: record, secondaryPeerAddressPrefix: string, state: string>, lastModifiedBy: string, microsoftPeeringConfig: record<advertisedCommunities: list, advertisedPublicPrefixes: list, advertisedPublicPrefixesState: string, customerASN: int, legacyMode: int, routingRegistryName: string>, peerASN: int, peeredConnections: list<record>, peeringType: string, primaryAzurePort: string, primaryPeerAddressPrefix: string, provisioningState: string, routeFilter: record<id: string>, secondaryAzurePort: string, secondaryPeerAddressPrefix: string, sharedKey: string, state: string, stats: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>, vlanId: int>, type: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}") $qp)
  let req_body = {"name": $name, "properties": $properties, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the currently advertised ARP table associated with the express route circuit in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/arpTables/{devicePath}
# operationId: ExpressRouteCircuits_ListArpTable
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-arp-tables list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  device_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<age: int, interface: string, ipAddress: string, macAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), device_path: (encode-path-segment $device_path)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/arpTables/{device_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all global reach connections associated with a private peering in an express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/connections
# operationId: ExpressRouteCircuitConnections_List
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-connections list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified Express Route Circuit Connection from the specified express route circuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/connections/{connectionName}
# operationId: ExpressRouteCircuitConnections_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-connections delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/connections/{connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Express Route Circuit Connection from the specified express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/connections/{connectionName}
# operationId: ExpressRouteCircuitConnections_Get
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-connections get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
]: nothing -> record<etag: string, name: string, properties: record<addressPrefix: string, authorizationKey: string, circuitConnectionStatus: string, expressRouteCircuitPeering: record<id: string>, peerExpressRouteCircuitPeering: record<id: string>, provisioningState: string>, type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/connections/{connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a Express Route Circuit Connection in the specified express route circuits.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/connections/{connectionName}
# operationId: ExpressRouteCircuitConnections_CreateOrUpdate
# --properties shape: {addressPrefix?: string, authorizationKey?: string, expressRouteCircuitPeering?: any, peerExpressRouteCircuitPeering?: any}
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-connections create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
  --properties: any # Properties of the express route circuit connection. — shape: {addressPrefix?: string, authorizationKey?: string, expressRouteCircuitPeering?: any, peerExpressRouteCircuitPeering?: any}
  --id: string # Resource ID.
]: any -> record<etag: string, name: string, properties: record<addressPrefix: string, authorizationKey: string, circuitConnectionStatus: string, expressRouteCircuitPeering: record<id: string>, peerExpressRouteCircuitPeering: record<id: string>, provisioningState: string>, type: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/connections/{connection_name}") $qp)
  let req_body = {"name": $name, "properties": $properties, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets all global reach peer connections associated with a private peering in an express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/peerConnections
# operationId: PeerExpressRouteCircuitConnections_List
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-peer-connections list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/peerConnections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Peer Express Route Circuit Connection from the specified express route circuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/peerConnections/{connectionName}
# operationId: PeerExpressRouteCircuitConnections_Get
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-peer-connections get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
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
]: nothing -> record<etag: string, name: string, properties: record<addressPrefix: string, authResourceGuid: string, circuitConnectionStatus: string, connectionName: string, expressRouteCircuitPeering: record<id: string>, peerExpressRouteCircuitPeering: record<id: string>, provisioningState: string>, type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), connection_name: (encode-path-segment $connection_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/peerConnections/{connection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the currently advertised routes table associated with the express route circuit in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/routeTables/{devicePath}
# operationId: ExpressRouteCircuits_ListRoutesTable
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-route-tables list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  device_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<locPrf: string, network: string, nextHop: string, path: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), device_path: (encode-path-segment $device_path)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/routeTables/{device_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the currently advertised routes table summary associated with the express route circuit in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/routeTablesSummary/{devicePath}
# operationId: ExpressRouteCircuits_ListRoutesTableSummary
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-route-tables-summary list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  device_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<as: int, neighbor: string, statePfxRcd: string, upDown: string, v: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name), device_path: (encode-path-segment $device_path)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/routeTablesSummary/{device_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all stats from an express route circuit in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/stats
# operationId: ExpressRouteCircuits_GetPeeringStats
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-peerings-stats get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name), peering_name: (encode-path-segment $peering_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/peerings/{peering_name}/stats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the stats from an express route circuit in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/stats
# operationId: ExpressRouteCircuits_GetStats
export def "subscriptions-resource-groups-providers-microsoft-network-express-route-circuits-stats get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), circuit_name: (encode-path-segment $circuit_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/expressRouteCircuits/{circuit_name}/stats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
