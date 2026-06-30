# Auto-generated client for PrivateDnsManagementClient v2018-09-01
# Source: https://api.apis.guru/v2/specs/azure.com/privatedns/2018-09-01/swagger.json
# Auth: --token flag or $env.PRIVATEDNSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PRIVATEDNSMANAGEMENTCLIENT_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-network-private-dns-zones list" } } | get name | first)
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

# Lists the Private DNS zones in all resource groups in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/privateDnsZones
# operationId: PrivateZones_List
export def "subscriptions-providers-microsoft-network-private-dns-zones list" [
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
  --top: int # The maximum number of Private DNS zones to return. If not specified, returns up to 100 zones. (format: int32)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/privateDnsZones") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$top": $top, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the Private DNS zones within a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones
# operationId: PrivateZones_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones list" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$top": $top, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a Private DNS zone. WARNING: All DNS records in the zone will also be deleted. This operation cannot be undone. Private DNS zone cannot be deleted unless all virtual network links to it are removed.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}
# operationId: PrivateZones_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones delete" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the Private DNS zone. Omit this value to always delete the current zone. Specify the last-seen ETag value to prevent accidentally deleting any concurrent changes.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets a Private DNS zone. Retrieves the zone properties, but not the virtual networks links or the record sets within the zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}
# operationId: PrivateZones_Get
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones get" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<etag: string, properties: record<maxNumberOfRecordSets: int, maxNumberOfVirtualNetworkLinks: int, maxNumberOfVirtualNetworkLinksWithRegistration: int, numberOfRecordSets: int, numberOfVirtualNetworkLinks: int, numberOfVirtualNetworkLinksWithRegistration: int, provisioningState: string>, location: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a Private DNS zone. Does not modify virtual network links or DNS records within the zone.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}
# operationId: PrivateZones_Update
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones update" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the Private DNS zone. Omit this value to always overwrite the current zone. Specify the last-seen ETag value to prevent accidentally overwriting any concurrent changes.
  --etag: string # The ETag of the zone.
  --properties: any # Represents the properties of the Private DNS zone.
  --location: string # The Azure Region where the resource lives
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<maxNumberOfRecordSets: int, maxNumberOfVirtualNetworkLinks: int, maxNumberOfVirtualNetworkLinksWithRegistration: int, numberOfRecordSets: int, numberOfVirtualNetworkLinks: int, numberOfVirtualNetworkLinksWithRegistration: int, provisioningState: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Creates or updates a Private DNS zone. Does not modify Links to virtual networks or DNS records within the zone.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}
# operationId: PrivateZones_CreateOrUpdate
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones create-or-update" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the Private DNS zone. Omit this value to always overwrite the current zone. Specify the last-seen ETag value to prevent accidentally overwriting any concurrent changes.
  --if-none-match: string # Set to '*' to allow a new Private DNS zone to be created, but to prevent updating an existing zone. Other values will be ignored.
  --etag: string # The ETag of the zone.
  --properties: any # Represents the properties of the Private DNS zone.
  --location: string # The Azure Region where the resource lives
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<maxNumberOfRecordSets: int, maxNumberOfVirtualNetworkLinks: int, maxNumberOfVirtualNetworkLinksWithRegistration: int, numberOfRecordSets: int, numberOfVirtualNetworkLinks: int, numberOfVirtualNetworkLinksWithRegistration: int, provisioningState: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201 202]
}

# Lists all record sets in a Private DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/ALL
# operationId: RecordSets_List
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones-all list-record-sets" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
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
  --recordsetnamesuffix: string # The suffix label of the record set name to be used to filter the record set enumeration. If this parameter is specified, the returned enumeration will only contain records that end with ".".
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$recordsetnamesuffix" $recordsetnamesuffix "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/ALL") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$top": $top, "$recordsetnamesuffix": $recordsetnamesuffix, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the virtual network links to the specified Private DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/virtualNetworkLinks
# operationId: VirtualNetworkLinks_List
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones-virtual-network-links list" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of virtual network links to return. If not specified, returns up to 100 virtual network links. (format: int32)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/virtualNetworkLinks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$top": $top, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a virtual network link to the specified Private DNS zone. WARNING: In case of a registration virtual network, all auto-registered DNS records in the zone for the virtual network will also be deleted. This operation cannot be undone.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/virtualNetworkLinks/{virtualNetworkLinkName}
# operationId: VirtualNetworkLinks_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones-virtual-network-links delete" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  virtual_network_link_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the virtual network link to the Private DNS zone. Omit this value to always delete the current zone. Specify the last-seen ETag value to prevent accidentally deleting any concurrent changes.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($virtual_network_link_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNetworkLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), virtual_network_link_name: (encode-path-segment $virtual_network_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/virtualNetworkLinks/{virtual_network_link_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets a virtual network link to the specified Private DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/virtualNetworkLinks/{virtualNetworkLinkName}
# operationId: VirtualNetworkLinks_Get
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones-virtual-network-links get" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  virtual_network_link_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<etag: string, properties: record<provisioningState: string, registrationEnabled: bool, virtualNetwork: record<id: string>, virtualNetworkLinkState: string>, location: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($virtual_network_link_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNetworkLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), virtual_network_link_name: (encode-path-segment $virtual_network_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/virtualNetworkLinks/{virtual_network_link_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a virtual network link to the specified Private DNS zone.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/virtualNetworkLinks/{virtualNetworkLinkName}
# operationId: VirtualNetworkLinks_Update
# --properties shape: {registrationEnabled?: bool, virtualNetwork?: any}
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones-virtual-network-links update" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  virtual_network_link_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the virtual network link to the Private DNS zone. Omit this value to always overwrite the current virtual network link. Specify the last-seen ETag value to prevent accidentally overwriting any concurrent changes.
  --etag: string # The ETag of the virtual network link.
  --properties: any # Represents the properties of the Private DNS zone. — shape: {registrationEnabled?: bool, virtualNetwork?: any}
  --location: string # The Azure Region where the resource lives
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<provisioningState: string, registrationEnabled: bool, virtualNetwork: record<id: string>, virtualNetworkLinkState: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($virtual_network_link_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNetworkLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), virtual_network_link_name: (encode-path-segment $virtual_network_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/virtualNetworkLinks/{virtual_network_link_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Creates or updates a virtual network link to the specified Private DNS zone.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/virtualNetworkLinks/{virtualNetworkLinkName}
# operationId: VirtualNetworkLinks_CreateOrUpdate
# --properties shape: {registrationEnabled?: bool, virtualNetwork?: any}
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones-virtual-network-links create-or-update" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
  virtual_network_link_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the virtual network link to the Private DNS zone. Omit this value to always overwrite the current virtual network link. Specify the last-seen ETag value to prevent accidentally overwriting any concurrent changes.
  --if-none-match: string # Set to '*' to allow a new virtual network link to the Private DNS zone to be created, but to prevent updating an existing link. Other values will be ignored.
  --etag: string # The ETag of the virtual network link.
  --properties: any # Represents the properties of the Private DNS zone. — shape: {registrationEnabled?: bool, virtualNetwork?: any}
  --location: string # The Azure Region where the resource lives
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<provisioningState: string, registrationEnabled: bool, virtualNetwork: record<id: string>, virtualNetworkLinkState: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($virtual_network_link_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualNetworkLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), virtual_network_link_name: (encode-path-segment $virtual_network_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/virtualNetworkLinks/{virtual_network_link_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201 202]
}

# Lists the record sets of a specified type in a Private DNS zone.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}
# operationId: RecordSets_ListByType
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones list-record-sets-by-type" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
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
  --recordsetnamesuffix: string # The suffix label of the record set name to be used to filter the record set enumeration. If this parameter is specified, the returned enumeration will only contain records that end with ".".
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$recordsetnamesuffix" $recordsetnamesuffix "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), record_type: (encode-path-segment $record_type)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/{record_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$top": $top, "$recordsetnamesuffix": $recordsetnamesuffix, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a record set from a Private DNS zone. This operation cannot be undone.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones delete-record-sets" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
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
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the record set. Omit this value to always delete the current record set. Specify the last-seen ETag value to prevent accidentally deleting any concurrent changes.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/{record_type}/{relative_record_set_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets a record set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_Get
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones get-record-sets" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<etag: string, id: string, name: string, properties: record<aRecords: list<record>, aaaaRecords: list<record>, cnameRecord: record<cname: string>, fqdn: string, isAutoRegistered: bool, metadata: record, mxRecords: list<record>, ptrRecords: list<record>, soaRecord: record<email: string, expireTime: int, host: string, minimumTtl: int, refreshTime: int, retryTime: int, serialNumber: int>, srvRecords: list<record>, ttl: int, txtRecords: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/{record_type}/{relative_record_set_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a record set within a Private DNS zone.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_Update
# --properties shape: {aRecords?: list, aaaaRecords?: list, cnameRecord?: any, metadata?: record, mxRecords?: list, ptrRecords?: list, soaRecord?: any, srvRecords?: list, ttl?: int, txtRecords?: list}
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones update-record-sets" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
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
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the record set. Omit this value to always overwrite the current record set. Specify the last-seen ETag value to prevent accidentally overwriting concurrent changes.
  --etag: string # The ETag of the record set.
  --properties: any # Represents the properties of the records in the record set. — shape: {aRecords?: list, aaaaRecords?: list, cnameRecord?: any, metadata?: record, mxRecords?: list, ptrRecords?: list, soaRecord?: any, srvRecords?: list, ttl?: int, txtRecords?: list}
]: any -> record<etag: string, id: string, name: string, properties: record<aRecords: list<record>, aaaaRecords: list<record>, cnameRecord: record<cname: string>, fqdn: string, isAutoRegistered: bool, metadata: record, mxRecords: list<record>, ptrRecords: list<record>, soaRecord: record<email: string, expireTime: int, host: string, minimumTtl: int, refreshTime: int, retryTime: int, serialNumber: int>, srvRecords: list<record>, ttl: int, txtRecords: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/{record_type}/{relative_record_set_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates or updates a record set within a Private DNS zone.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}/{relativeRecordSetName}
# operationId: RecordSets_CreateOrUpdate
# --properties shape: {aRecords?: list, aaaaRecords?: list, cnameRecord?: any, metadata?: record, mxRecords?: list, ptrRecords?: list, soaRecord?: any, srvRecords?: list, ttl?: int, txtRecords?: list}
export def "subscriptions-resource-groups-providers-microsoft-network-private-dns-zones create-record-sets-or-update" [
  subscription_id: string
  resource_group_name: string
  private_zone_name: string
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
  --api-version: string # Client Api Version.
  --if-match: string # The ETag of the record set. Omit this value to always overwrite the current record set. Specify the last-seen ETag value to prevent accidentally overwriting any concurrent changes.
  --if-none-match: string # Set to '*' to allow a new record set to be created, but to prevent updating an existing record set. Other values will be ignored.
  --etag: string # The ETag of the record set.
  --properties: any # Represents the properties of the records in the record set. — shape: {aRecords?: list, aaaaRecords?: list, cnameRecord?: any, metadata?: record, mxRecords?: list, ptrRecords?: list, soaRecord?: any, srvRecords?: list, ttl?: int, txtRecords?: list}
]: any -> record<etag: string, id: string, name: string, properties: record<aRecords: list<record>, aaaaRecords: list<record>, cnameRecord: record<cname: string>, fqdn: string, isAutoRegistered: bool, metadata: record, mxRecords: list<record>, ptrRecords: list<record>, soaRecord: record<email: string, expireTime: int, host: string, minimumTtl: int, refreshTime: int, retryTime: int, serialNumber: int>, srvRecords: list<record>, ttl: int, txtRecords: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($private_zone_name | is-empty) { error make --unspanned { msg: "path parameter 'privateZoneName' must be non-empty" } }
  if ($record_type | is-empty) { error make --unspanned { msg: "path parameter 'recordType' must be non-empty" } }
  if ($relative_record_set_name | is-empty) { error make --unspanned { msg: "path parameter 'relativeRecordSetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), private_zone_name: (encode-path-segment $private_zone_name), record_type: (encode-path-segment $record_type), relative_record_set_name: (encode-path-segment $relative_record_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/privateDnsZones/{private_zone_name}/{record_type}/{relative_record_set_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}
