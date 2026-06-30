# Auto-generated client for ApiManagementClient v2019-12-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/apimanagement-apimproducts/2019-12-01-preview/swagger.json
# Auth: --token flag or $env.APIMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o APIMANAGEMENTCLIENT_TOKEN | default "" }
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

# HEAD — bodyless; default surfaces just the headers on success
def send-head [req: record, insecure: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = (http head --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure $req.url)
  if (not $full) and (not $allow_errors) and (status-ok $resp.status $ok_codes) { return $resp.headers }
  $resp | handle-response $allow_errors $full $ok_codes
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

# Completers for enum parameters
def format-completer [] { ["rawxml" "xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-api-management-service-products list" } } | get name | first)
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

# Lists a collection of products in the specified service instance.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products
# operationId: Product_ListByService
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products list" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | description | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | terms | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | state | filter | eq | | | groups | expand | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --expand-groups: oneof<nothing, bool> # When set to true, the response contains an array of groups that have visibility to the product. The default is false.
  --tags: string # Products which are part of a specific tag.
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "expandGroups" $expand_groups "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "expandGroups": $expand_groups, "tags": $tags, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete product.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}
# operationId: Product_Delete
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-subscriptions: oneof<nothing, bool> # Delete existing subscriptions associated with the product or not.
  --api-version: string # Version of the API to be used with the client request.
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update.
]: nothing -> record<error: record<code: string, details: list<record>, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "deleteSubscriptions" $delete_subscriptions "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"deleteSubscriptions": $delete_subscriptions, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets the details of the product specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}
# operationId: Product_Get
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<properties: record<displayName: string, approvalRequired: bool, description: string, state: string, subscriptionRequired: bool, subscriptionsLimit: int, terms: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}") $qp $auth.query)
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

# Gets the entity state (Etag) version of the product specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}
# operationId: Product_GetEntityTag
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [200]
}

# Update existing product details.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}
# operationId: Product_Update
# --properties shape: {displayName?: string, approvalRequired?: bool, description?: string, state?: "notPublished"|"published", subscriptionRequired?: bool, subscriptionsLimit?: int, terms?: string}
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update.
  --properties: any # Parameters supplied to the Update Product operation. — shape: {displayName?: string, approvalRequired?: bool, description?: string, state?: "notPublished"|"published", subscriptionRequired?: bool, subscriptionsLimit?: int, terms?: string}
]: any -> record<error: record<code: string, details: list<record>, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Creates or Updates a product.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}
# operationId: Product_CreateOrUpdate
# --properties shape: {displayName: string, approvalRequired?: bool, description?: string, state?: "notPublished"|"published", subscriptionRequired?: bool, subscriptionsLimit?: int, terms?: string}
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Product profile. — shape: {displayName: string, approvalRequired?: bool, description?: string, state?: "notPublished"|"published", subscriptionRequired?: bool, subscriptionsLimit?: int, terms?: string}
]: any -> record<properties: record<displayName: string, approvalRequired: bool, description: string, state: string, subscriptionRequired: bool, subscriptionsLimit: int, terms: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
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

# Lists a collection of the APIs associated with a product.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/apis
# operationId: ProductApi_ListByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-apis list" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | description | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | serviceUrl | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | path | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/apis") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes the specified API from the specified product.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/apis/{apiId}
# operationId: ProductApi_Delete
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-apis delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<record>, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), api_id: (encode-path-segment $api_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/apis/{api_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Checks that API entity specified by identifier is associated with the Product entity.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/apis/{apiId}
# operationId: ProductApi_CheckEntityExists
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-apis check-entity-exists" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), api_id: (encode-path-segment $api_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/apis/{api_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [204]
}

# Adds an API to the specified product.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/apis/{apiId}
# operationId: ProductApi_CreateOrUpdate
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-apis create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<properties: record<apiVersionSet: record<description: string, id: string, name: string, versionHeaderName: string, versionQueryName: string, versioningScheme: string>, displayName: string, path: string, protocols: list<string>, serviceUrl: string, sourceApiId: string, apiRevision: string, apiRevisionDescription: string, apiVersion: string, apiVersionDescription: string, apiVersionSetId: string, authenticationSettings: record<oAuth2: record, openid: record>, description: string, isCurrent: bool, isOnline: bool, subscriptionKeyParameterNames: record<header: string, query: string>, subscriptionRequired: bool, type: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), api_id: (encode-path-segment $api_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/apis/{api_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 201]
}

# Lists the collection of developer groups associated with the specified product.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/groups
# operationId: ProductGroup_ListByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-groups list" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | | | displayName | filter | eq, ne | | | description | filter | eq, ne | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/groups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes the association between the specified group and product.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/groups/{groupId}
# operationId: ProductGroup_Delete
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-groups delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<record>, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/groups/{group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Checks that Group entity specified by identifier is associated with the Product entity.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/groups/{groupId}
# operationId: ProductGroup_CheckEntityExists
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-groups check-entity-exists" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/groups/{group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [204]
}

# Adds the association between the specified developer group with the specified product.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/groups/{groupId}
# operationId: ProductGroup_CreateOrUpdate
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-groups create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<properties: record<builtIn: bool, description: string, displayName: string, externalId: string, type: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), group_id: (encode-path-segment $group_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/groups/{group_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 201]
}

# Get the policy configuration at the Product level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/policies
# operationId: ProductPolicy_ListByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-policies list-policy" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/policies") $qp $auth.query)
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

# Deletes the policy configuration at the Product.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/policies/{policyId}
# operationId: ProductPolicy_Delete
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-policies delete-policy" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update.
]: nothing -> record<error: record<code: string, details: list<record>, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), policy_id: (encode-path-segment $policy_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/policies/{policy_id}") $qp $auth.query)
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

# Get the policy configuration at the Product level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/policies/{policyId}
# operationId: ProductPolicy_Get
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-policies get-policy" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Policy Export Format. (default: xml)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<properties: record<format: string, value: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), policy_id: (encode-path-segment $policy_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/policies/{policy_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the ETag of the policy configuration at the Product level.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/policies/{policyId}
# operationId: ProductPolicy_GetEntityTag
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-policies get-policy-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), policy_id: (encode-path-segment $policy_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/policies/{policy_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [200]
}

# Creates or updates policy configuration for the Product.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/policies/{policyId}
# operationId: ProductPolicy_CreateOrUpdate
# --properties shape: {format?: "xml"|"xml-link"|"rawxml"|"rawxml-link", value: string}
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-policies create-policy-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Policy contract Properties. — shape: {format?: "xml"|"xml-link"|"rawxml"|"rawxml-link", value: string}
]: any -> record<properties: record<format: string, value: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), policy_id: (encode-path-segment $policy_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/policies/{policy_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
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

# Lists the collection of subscriptions to the specified product.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/subscriptions
# operationId: ProductSubscriptions_List
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-subscriptions list" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | stateComment | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | ownerId | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | scope | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | userId | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | productId | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | state | filter | eq | | | user | expand | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/subscriptions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all Tags associated with the Product.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/tags
# operationId: Tag_ListByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-tags list" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/tags") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Detach the tag from the Product.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/tags/{tagId}
# operationId: Tag_DetachFromProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-tags tag-detach" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<record>, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/tags/{tag_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get tag associated with the Product.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/tags/{tagId}
# operationId: Tag_GetByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-tags get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<properties: record<displayName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/tags/{tag_id}") $qp $auth.query)
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

# Gets the entity state version of the tag specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/tags/{tagId}
# operationId: Tag_GetEntityStateByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-tags get-entity-state" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/tags/{tag_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [200]
}

# Assign tag to the Product.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/products/{productId}/tags/{tagId}
# operationId: Tag_AssignToProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-products-tags assign" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  product_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<properties: record<displayName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name), product_id: (encode-path-segment $product_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/products/{product_id}/tags/{tag_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 201]
}
