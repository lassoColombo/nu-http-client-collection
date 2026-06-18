# Auto-generated client for NetworkManagementClient v2019-07-01
# Source: https://api.apis.guru/v2/specs/azure.com/network-applicationGateway/2019-07-01/swagger.json
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

# Completers for enum parameters
def protocol-completer [] { ["Http" "Https"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-network-application-gateway-available-request-headers list" } } | get name | first)
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

# Lists all available request headers.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableRequestHeaders
# operationId: ApplicationGateways_ListAvailableRequestHeaders
export def "subscriptions-providers-microsoft-network-application-gateway-available-request-headers list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableRequestHeaders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all available response headers.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableResponseHeaders
# operationId: ApplicationGateways_ListAvailableResponseHeaders
export def "subscriptions-providers-microsoft-network-application-gateway-available-response-headers list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableResponseHeaders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all available server variables.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableServerVariables
# operationId: ApplicationGateways_ListAvailableServerVariables
export def "subscriptions-providers-microsoft-network-application-gateway-available-server-variables list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableServerVariables"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists available Ssl options for configuring Ssl policy.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableSslOptions/default
# operationId: ApplicationGateways_ListAvailableSslOptions
export def "subscriptions-providers-microsoft-network-application-gateway-available-ssl-options-default list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: record<availableCipherSuites: list<string>, availableProtocols: list<string>, defaultPolicy: string, predefinedPolicies: list<record>>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableSslOptions/default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all SSL predefined policies for configuring Ssl policy.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableSslOptions/default/predefinedPolicies
# operationId: ApplicationGateways_ListAvailableSslPredefinedPolicies
export def "subscriptions-providers-microsoft-network-application-gateway-available-ssl-options-default-predefined-policies list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, value: table<name: string, properties: record, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableSslOptions/default/predefinedPolicies"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Ssl predefined policy with the specified policy name.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableSslOptions/default/predefinedPolicies/{predefinedPolicyName}
# operationId: ApplicationGateways_GetSslPredefinedPolicy
export def "subscriptions-providers-microsoft-network-application-gateway-available-ssl-options-default-predefined-policies get-policy" [
  subscription_id: any
  predefined_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, properties: record<cipherSuites: list<string>, minProtocolVersion: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), predefined_policy_name: (encode-path-segment $predefined_policy_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableSslOptions/default/predefinedPolicies/{predefined_policy_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all available web application firewall rule sets.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGatewayAvailableWafRuleSets
# operationId: ApplicationGateways_ListAvailableWafRuleSets
export def "subscriptions-providers-microsoft-network-application-gateway-available-waf-rule-sets list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGatewayAvailableWafRuleSets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the application gateways in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGateways
# operationId: ApplicationGateways_ListAll
export def "subscriptions-providers-microsoft-network-application-gateways list-list" [
  subscription_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, value: table<etag: string, identity: record, properties: record, zones: list, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/applicationGateways"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all application gateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways
# operationId: ApplicationGateways_List
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways list" [
  subscription_id: any
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nextLink: string, value: table<etag: string, identity: record, properties: record, zones: list, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified application gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# operationId: ApplicationGateways_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways delete" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified application gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# operationId: ApplicationGateways_Get
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways get" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<authenticationCertificates: list<record>, autoscaleConfiguration: record<maxCapacity: int, minCapacity: int>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, customErrorConfigurations: list<record>, enableFips: bool, enableHttp2: bool, firewallPolicy: record<id: string>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, redirectConfigurations: list<record>, requestRoutingRules: list<record>, resourceGuid: string, rewriteRuleSets: list<record>, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<cipherSuites: list, disabledSslProtocols: list, minProtocolVersion: string, policyName: string, policyType: string>, trustedRootCertificates: list<record>, urlPathMaps: list<record>, webApplicationFirewallConfiguration: record<disabledRuleGroups: list, enabled: bool, exclusions: list, fileUploadLimitInMb: int, firewallMode: string, maxRequestBodySize: int, maxRequestBodySizeInKb: int, requestBodyCheck: bool, ruleSetType: string, ruleSetVersion: string>>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified application gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# operationId: ApplicationGateways_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways update-tags" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record # Resource tags.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<authenticationCertificates: list<record>, autoscaleConfiguration: record<maxCapacity: int, minCapacity: int>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, customErrorConfigurations: list<record>, enableFips: bool, enableHttp2: bool, firewallPolicy: record<id: string>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, redirectConfigurations: list<record>, requestRoutingRules: list<record>, resourceGuid: string, rewriteRuleSets: list<record>, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<cipherSuites: list, disabledSslProtocols: list, minProtocolVersion: string, policyName: string, policyType: string>, trustedRootCertificates: list<record>, urlPathMaps: list<record>, webApplicationFirewallConfiguration: record<disabledRuleGroups: list, enabled: bool, exclusions: list, fileUploadLimitInMb: int, firewallMode: string, maxRequestBodySize: int, maxRequestBodySizeInKb: int, requestBodyCheck: bool, ruleSetType: string, ruleSetVersion: string>>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or updates the specified application gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# operationId: ApplicationGateways_CreateOrUpdate
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {authenticationCertificates?: list, autoscaleConfiguration?: any, backendAddressPools?: list, backendHttpSettingsCollection?: list, customErrorConfigurations?: list, enableFips?: bool, enableHttp2?: bool, firewallPolicy?: any, frontendIPConfigurations?: list, frontendPorts?: list, gatewayIPConfigurations?: list, httpListeners?: list, probes?: list, redirectConfigurations?: list, requestRoutingRules?: list, resourceGuid?: string, rewriteRuleSets?: list, sku?: any, sslCertificates?: list, ... (4 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways create-or-update" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --etag: string # A unique read-only string that changes whenever the resource is updated.
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: any # Properties of the application gateway. — shape: {authenticationCertificates?: list, autoscaleConfiguration?: any, backendAddressPools?: list, backendHttpSettingsCollection?: list, customErrorConfigurations?: list, enableFips?: bool, enableHttp2?: bool, firewallPolicy?: any, frontendIPConfigurations?: list, frontendPorts?: list, gatewayIPConfigurations?: list, httpListeners?: list, probes?: list, redirectConfigurations?: list, requestRoutingRules?: list, resourceGuid?: string, rewriteRuleSets?: list, sku?: any, sslCertificates?: list, ... (4 more fields)}
  --zones: list<string> # A list of availability zones denoting where the resource needs to come from.
  --id: string # Resource ID.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<authenticationCertificates: list<record>, autoscaleConfiguration: record<maxCapacity: int, minCapacity: int>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, customErrorConfigurations: list<record>, enableFips: bool, enableHttp2: bool, firewallPolicy: record<id: string>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, redirectConfigurations: list<record>, requestRoutingRules: list<record>, resourceGuid: string, rewriteRuleSets: list<record>, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<cipherSuites: list, disabledSslProtocols: list, minProtocolVersion: string, policyName: string, policyType: string>, trustedRootCertificates: list<record>, urlPathMaps: list<record>, webApplicationFirewallConfiguration: record<disabledRuleGroups: list, enabled: bool, exclusions: list, fileUploadLimitInMb: int, firewallMode: string, maxRequestBodySize: int, maxRequestBodySizeInKb: int, requestBodyCheck: bool, ruleSetType: string, ruleSetVersion: string>>, zones: list<string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}"))
  let req_body = {"etag": $etag, "identity": $identity, "properties": $properties, "zones": $zones, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the backend health of the specified application gateway in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/backendhealth
# operationId: ApplicationGateways_BackendHealth
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways-backendhealth create-backend-health" [
  subscription_id: string
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --expand: string # Expands BackendAddressPool and BackendHttpSettings referenced in backend health.
]: nothing -> record<backendAddressPools: table<backendAddressPool: record, backendHttpSettingsCollection: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}/backendhealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the backend health for given combination of backend pool and http setting of the specified application gateway in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/getBackendHealthOnDemand
# operationId: ApplicationGateways_BackendHealthOnDemand
# --backendAddressPool shape: {id?: string}
# --backendHttpSettings shape: {id?: string}
# --match shape: {body?: string, statusCodes?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways-get-backend-health-on-demand create" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expands BackendAddressPool and BackendHttpSettings referenced in backend health.
  --backend-address-pool: any # Reference to another subresource. — shape: {id?: string}
  --backend-http-settings: any # Reference to another subresource. — shape: {id?: string}
  --host: string # Host name to send the probe to.
  --body-match: any # Application gateway probe health response match. — shape: {body?: string, statusCodes?: list<string>}
  --path: string # Relative path of probe. Valid path starts from '/'. Probe is sent to ://:.
  --pick-host-name-from-backend-http-settings: oneof<nothing, bool> # Whether the host header should be picked from the backend http settings. Default value is false.
  --protocol: string@protocol-completer # Application Gateway protocol.
  --timeout: int # The probe timeout in seconds. Probe marked as failed if valid response is not received with this timeout period. Acceptable values are from 1 second to 86400 seconds. (format: int32)
]: any -> record<backendAddressPool: record<etag: string, name: string, properties: record<backendAddresses: list, backendIPConfigurations: list, provisioningState: string>, type: string, id: string>, backendHealthHttpSettings: record<backendHttpSettings: record<etag: string, name: string, properties: record, type: string, id: string>, servers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}/getBackendHealthOnDemand") $qp)
  let req_body = {"backendAddressPool": $backend_address_pool, "backendHttpSettings": $backend_http_settings, "host": $host, "match": $body_match, "path": $path, "pickHostNameFromBackendHttpSettings": $pick_host_name_from_backend_http_settings, "protocol": $protocol, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts the specified application gateway.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/start
# operationId: ApplicationGateways_Start
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways-start start" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops the specified application gateway in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/stop
# operationId: ApplicationGateways_Stop
export def "subscriptions-resource-groups-providers-microsoft-network-application-gateways-stop stop" [
  subscription_id: any
  resource_group_name: string
  application_gateway_name: string
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
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_gateway_name: (encode-path-segment $application_gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/applicationGateways/{application_gateway_name}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
