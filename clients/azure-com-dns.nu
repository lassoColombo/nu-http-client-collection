# Auto-generated client for DnsManagementClient v2018-05-01
# Source: https://api.apis.guru/v2/specs/azure.com/dns/2018-05-01/swagger.json
# Auth: --token flag or $env.DNSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DNSMANAGEMENTCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-network-dnszones list-zones" } } | get name | first)
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

# Lists the DNS zones in all resource groups in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/dnszones
# operationId: Zones_List
export def "subscriptions-providers-microsoft-network-dnszones list-zones" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of DNS zones to return. If not specified, returns up to 100 zones. (format: int32)
  --api-version: string # Specifies the API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/dnszones") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "api-version": $api_version} | compact), body: null}
}

# Returns the DNS records specified by the referencing targetResourceIds.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Network/getDnsResourceReference
# operationId: DnsResourceReference_GetByTargetResources
# --properties shape: {targetResources?: list}
export def "subscriptions-providers-microsoft-network-get-dns-resource-reference get-by-target" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --properties: any # Represents the properties of the Dns Resource Reference Request. — shape: {targetResources?: list}
]: any -> record<properties: record<dnsResourceReferences: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/getDnsResourceReference") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists the DNS zones within a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones
# operationId: Zones_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of record sets to return. If not specified, returns up to 100 record sets. (format: int32)
  --api-version: string # Specifies the API version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "api-version": $api_version} | compact), body: null}
}

# Deletes a DNS zone. WARNING: All DNS records in the zone will also be deleted. This operation cannot be undone.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}
# operationId: Zones_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones delete" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --if-match: string # The etag of the DNS zone. Omit this value to always delete the current zone. Specify the last-seen etag value to prevent accidentally deleting any concurrent changes.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a DNS zone. Retrieves the zone properties, but not the record sets within the zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}
# operationId: Zones_Get
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones get" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
]: nothing -> record<etag: string, properties: record<maxNumberOfRecordSets: int, nameServers: list<string>, numberOfRecordSets: int, registrationVirtualNetworks: list<record>, resolutionVirtualNetworks: list<record>, zoneType: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a DNS zone. Does not modify DNS records within the zone.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}
# operationId: Zones_Update
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones update" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --if-match: string # The etag of the DNS zone. Omit this value to always overwrite the current zone. Specify the last-seen etag value to prevent accidentally overwriting any concurrent changes.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<maxNumberOfRecordSets: int, nameServers: list<string>, numberOfRecordSets: int, registrationVirtualNetworks: list<record>, resolutionVirtualNetworks: list<record>, zoneType: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a DNS zone. Does not modify DNS records within the zone.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}
# operationId: Zones_CreateOrUpdate
# --properties shape: {registrationVirtualNetworks?: list, resolutionVirtualNetworks?: list, zoneType?: "Public"|"Private"}
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones create-or-update" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --if-match: string # The etag of the DNS zone. Omit this value to always overwrite the current zone. Specify the last-seen etag value to prevent accidentally overwriting any concurrent changes.
  --if-none-match: string # Set to '*' to allow a new DNS zone to be created, but to prevent updating an existing zone. Other values will be ignored.
  --etag: string # The etag of the zone.
  --properties: any # Represents the properties of the zone. — shape: {registrationVirtualNetworks?: list, resolutionVirtualNetworks?: list, zoneType?: "Public"|"Private"}
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<maxNumberOfRecordSets: int, nameServers: list<string>, numberOfRecordSets: int, registrationVirtualNetworks: list<record>, resolutionVirtualNetworks: list<record>, zoneType: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all record sets in a DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/all
# operationId: RecordSets_ListAllByDnsZone
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones-all list-record-sets" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of record sets to return. If not specified, returns up to 100 record sets. (format: int32)
  --recordsetnamesuffix: string # The suffix label of the record set name that has to be used to filter the record set enumerations. If this parameter is specified, Enumeration will return only records that end with .
  --api-version: string # Specifies the API version.
]: nothing -> record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$recordsetnamesuffix" $recordsetnamesuffix "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "$recordsetnamesuffix": $recordsetnamesuffix, "api-version": $api_version} | compact), body: null}
}

# Lists all record sets in a DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/recordsets
# operationId: RecordSets_ListByDnsZone
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones-recordsets list-record-sets" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of record sets to return. If not specified, returns up to 100 record sets. (format: int32)
  --recordsetnamesuffix: string # The suffix label of the record set name that has to be used to filter the record set enumerations. If this parameter is specified, Enumeration will return only records that end with .
  --api-version: string # Specifies the API version.
]: nothing -> record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$recordsetnamesuffix" $recordsetnamesuffix "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/recordsets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "$recordsetnamesuffix": $recordsetnamesuffix, "api-version": $api_version} | compact), body: null}
}

# Lists the record sets of a specified type in a DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/{recordType}
# operationId: RecordSets_ListByType
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones list-record-sets-by-type" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  record_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of record sets to return. If not specified, returns up to 100 record sets. (format: int32)
  --recordsetnamesuffix: string # The suffix label of the record set name that has to be used to filter the record set enumerations. If this parameter is specified, Enumeration will return only records that end with .
  --api-version: string # Specifies the API version.
]: nothing -> record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$recordsetnamesuffix" $recordsetnamesuffix "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name), record_type: (encode-path-segment $record_type)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/{record_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "$recordsetnamesuffix": $recordsetnamesuffix, "api-version": $api_version} | compact), body: null}
}

# Deletes a record set from a DNS zone. This operation cannot be undone.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones delete-record-sets" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  record_type: string
  relative_record_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --if-match: string # The etag of the record set. Omit this value to always delete the current record set. Specify the last-seen etag value to prevent accidentally deleting any concurrent changes.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/{record_type}/{relative_record_set_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a record set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_Get
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones get-record-sets" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  record_type: string
  relative_record_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
]: nothing -> record<etag: string, id: string, name: string, properties: record<AAAARecords: list<record>, ARecords: list<record>, CNAMERecord: record<cname: string>, MXRecords: list<record>, NSRecords: list<record>, PTRRecords: list<record>, SOARecord: record<email: string, expireTime: int, host: string, minimumTTL: int, refreshTime: int, retryTime: int, serialNumber: int>, SRVRecords: list<record>, TTL: int, TXTRecords: list<record>, caaRecords: list<record>, fqdn: string, metadata: record, provisioningState: string, targetResource: record<id: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/{record_type}/{relative_record_set_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a record set within a DNS zone.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_Update
# --properties shape: {AAAARecords?: list, ARecords?: list, CNAMERecord?: any, MXRecords?: list, NSRecords?: list, PTRRecords?: list, SOARecord?: any, SRVRecords?: list, TTL?: int, TXTRecords?: list, caaRecords?: list, metadata?: record, targetResource?: any}
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones update-record-sets" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  record_type: string
  relative_record_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --if-match: string # The etag of the record set. Omit this value to always overwrite the current record set. Specify the last-seen etag value to prevent accidentally overwriting concurrent changes.
  --etag: string # The etag of the record set.
  --properties: any # Represents the properties of the records in the record set. — shape: {AAAARecords?: list, ARecords?: list, CNAMERecord?: any, MXRecords?: list, NSRecords?: list, PTRRecords?: list, SOARecord?: any, SRVRecords?: list, TTL?: int, TXTRecords?: list, caaRecords?: list, metadata?: record, targetResource?: any}
]: any -> record<etag: string, id: string, name: string, properties: record<AAAARecords: list<record>, ARecords: list<record>, CNAMERecord: record<cname: string>, MXRecords: list<record>, NSRecords: list<record>, PTRRecords: list<record>, SOARecord: record<email: string, expireTime: int, host: string, minimumTTL: int, refreshTime: int, retryTime: int, serialNumber: int>, SRVRecords: list<record>, TTL: int, TXTRecords: list<record>, caaRecords: list<record>, fqdn: string, metadata: record, provisioningState: string, targetResource: record<id: string>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/{record_type}/{relative_record_set_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a record set within a DNS zone.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_CreateOrUpdate
# --properties shape: {AAAARecords?: list, ARecords?: list, CNAMERecord?: any, MXRecords?: list, NSRecords?: list, PTRRecords?: list, SOARecord?: any, SRVRecords?: list, TTL?: int, TXTRecords?: list, caaRecords?: list, metadata?: record, targetResource?: any}
export def "subscriptions-resource-groups-providers-microsoft-network-dns-zones create-record-sets-or-update" [
  subscription_id: string
  resource_group_name: string
  zone_name: string
  record_type: string
  relative_record_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the API version.
  --if-match: string # The etag of the record set. Omit this value to always overwrite the current record set. Specify the last-seen etag value to prevent accidentally overwriting any concurrent changes.
  --if-none-match: string # Set to '*' to allow a new record set to be created, but to prevent updating an existing record set. Other values will be ignored.
  --etag: string # The etag of the record set.
  --properties: any # Represents the properties of the records in the record set. — shape: {AAAARecords?: list, ARecords?: list, CNAMERecord?: any, MXRecords?: list, NSRecords?: list, PTRRecords?: list, SOARecord?: any, SRVRecords?: list, TTL?: int, TXTRecords?: list, caaRecords?: list, metadata?: record, targetResource?: any}
]: any -> record<etag: string, id: string, name: string, properties: record<AAAARecords: list<record>, ARecords: list<record>, CNAMERecord: record<cname: string>, MXRecords: list<record>, NSRecords: list<record>, PTRRecords: list<record>, SOARecord: record<email: string, expireTime: int, host: string, minimumTTL: int, refreshTime: int, retryTime: int, serialNumber: int>, SRVRecords: list<record>, TTL: int, TXTRecords: list<record>, caaRecords: list<record>, fqdn: string, metadata: record, provisioningState: string, targetResource: record<id: string>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($zone_name | is-empty) { error make --unspanned { msg: "path parameter 'zoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), zone_name: (encode-path-segment $zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/dnsZones/{zone_name}/{record_type}/{relative_record_set_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
