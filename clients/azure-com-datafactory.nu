# Auto-generated client for DataFactoryManagementClient v2018-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/datafactory/2018-06-01/swagger.json
# Auth: --token flag or $env.DATAFACTORYMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATAFACTORYMANAGEMENTCLIENT_TOKEN | default "" }
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

# Completers for enum parameters
def command-completer [] { ["executeExpressionQuery" "executePreviewQuery" "executeStatisticsQuery"] }
def auto-update-completer [] { ["Off" "On"] }
def key-name-completer [] { ["authKey1" "authKey2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-data-factory-operations list" } } | get name | first)
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

# Lists the available Azure Data Factory API operations.
#
# GET /providers/Microsoft.DataFactory/operations
# operationId: Operations_List
export def "providers-microsoft-data-factory-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DataFactory/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists factories under the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DataFactory/factories
# operationId: Factories_List
export def "subscriptions-providers-microsoft-data-factory-factories list" [
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
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DataFactory/factories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a factory's repo information.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataFactory/locations/{locationId}/configureFactoryRepo
# operationId: Factories_ConfigureFactoryRepo
# --repoConfiguration shape: {accountName: string, collaborationBranch: string, lastCommitId?: string, repositoryName: string, rootFolder: string, type: string}
export def "subscriptions-providers-microsoft-data-factory-locations-configure-factory-repo create-factories" [
  subscription_id: string
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --factory-resource-id: string # The factory resource id.
  --repo-configuration: record # Factory's git repo information. — shape: {accountName: string, collaborationBranch: string, lastCommitId?: string, repositoryName: string, rootFolder: string, type: string}
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_id: (encode-path-segment $location_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DataFactory/locations/{location_id}/configureFactoryRepo") $qp)
  let req_body = {"factoryResourceId": $factory_resource_id, "repoConfiguration": $repo_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get exposure control feature for specific location.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataFactory/locations/{locationId}/getFeatureValue
# operationId: ExposureControl_GetFeatureValue
export def "subscriptions-providers-microsoft-data-factory-locations-get-feature-value get-exposure-control" [
  subscription_id: string
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --feature-name: string # The feature name.
  --feature-type: string # The feature type.
]: any -> record<featureName: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_id: (encode-path-segment $location_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DataFactory/locations/{location_id}/getFeatureValue") $qp)
  let req_body = {"featureName": $feature_name, "featureType": $feature_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists factories.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories
# operationId: Factories_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories list" [
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
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a factory.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a factory.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the factory entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a factory.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_Update
# --identity shape: {type: "SystemAssigned"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --identity: any # Identity properties of the factory resource. — shape: {type: "SystemAssigned"}
  --tags: record # The resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}") $qp)
  let req_body = {"identity": $identity, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a factory.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_CreateOrUpdate
# --identity shape: {type: "SystemAssigned"}
# --properties shape: {repoConfiguration?: record}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories create-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the factory entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  --identity: any # Identity properties of the factory resource. — shape: {type: "SystemAssigned"}
  --properties: any # Factory resource properties. — shape: {repoConfiguration?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}") $qp)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Add a data flow into debug session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/addDataFlowToDebugSession
# operationId: DataFlowDebugSession_AddDataFlow
# --dataFlow shape: {properties: record, name?: string}
# --datasets item shape: {properties: record, name?: string}
# --debugSettings shape: {datasetParameters?: record, parameters?: record, sourceSettings?: list}
# --linkedServices item shape: {properties: record, name?: string}
# --staging shape: {folderPath?: string, linkedService?: any}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-add-data-flow-to-debug-session create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --data-flow: any # Data flow debug resource. — shape: {properties: record, name?: string}
  --datasets: list # List of datasets. — item shape: {properties: record, name?: string}
  --debug-settings: record # Data flow debug settings. — shape: {datasetParameters?: record, parameters?: record, sourceSettings?: list}
  --linked-services: list # List of linked services. — item shape: {properties: record, name?: string}
  --session-id: string # The ID of data flow debug session.
  --staging: any # Staging info for execute data flow activity. — shape: {folderPath?: string, linkedService?: any}
]: any -> record<jobVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/addDataFlowToDebugSession") $qp)
  let req_body = {"dataFlow": $data_flow, "datasets": $datasets, "debugSettings": $debug_settings, "linkedServices": $linked_services, "sessionId": $session_id, "staging": $staging} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a data flow debug session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/createDataFlowDebugSession
# operationId: DataFlowDebugSession_Create
# --integrationRuntime shape: {properties: record, name?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-create-data-flow-debug-session create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --compute-type: string # Compute type of the cluster. The value will be overwritten by the same setting in integration runtime if provided.
  --core-count: int # Core count of the cluster. The value will be overwritten by the same setting in integration runtime if provided.
  --integration-runtime: any # Integration runtime debug resource. — shape: {properties: record, name?: string}
  --time-to-live: int # Time to live setting of the cluster in minutes.
]: any -> record<sessionId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/createDataFlowDebugSession") $qp)
  let req_body = {"computeType": $compute_type, "coreCount": $core_count, "integrationRuntime": $integration_runtime, "timeToLive": $time_to_live} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists data flows.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows
# operationId: DataFlows_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows list-flows" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/dataflows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a data flow.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows/{dataFlowName}
# operationId: DataFlows_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows delete-flows" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  data_flow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($data_flow_name | is-empty) { error make --unspanned { msg: "path parameter 'dataFlowName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), data_flow_name: (encode-path-segment $data_flow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/dataflows/{data_flow_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a data flow.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows/{dataFlowName}
# operationId: DataFlows_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows get-flows" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  data_flow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the data flow entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($data_flow_name | is-empty) { error make --unspanned { msg: "path parameter 'dataFlowName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), data_flow_name: (encode-path-segment $data_flow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/dataflows/{data_flow_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a data flow.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows/{dataFlowName}
# operationId: DataFlows_CreateOrUpdate
# --properties shape: {annotations?: list, description?: string, folder?: record, type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows create-flows-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  data_flow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the data flow entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # Azure Data Factory nested object which contains a flow with data movements and transformations. — shape: {annotations?: list, description?: string, folder?: record, type: string}
]: any -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($data_flow_name | is-empty) { error make --unspanned { msg: "path parameter 'dataFlowName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), data_flow_name: (encode-path-segment $data_flow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/dataflows/{data_flow_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists datasets.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets
# operationId: Datasets_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/datasets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a dataset.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets/{datasetName}
# operationId: Datasets_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  dataset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($dataset_name | is-empty) { error make --unspanned { msg: "path parameter 'datasetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), dataset_name: (encode-path-segment $dataset_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/datasets/{dataset_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a dataset.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets/{datasetName}
# operationId: Datasets_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  dataset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the dataset entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, linkedServiceName: record<parameters: record, referenceName: string, type: string>, parameters: record, schema: record, structure: record, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($dataset_name | is-empty) { error make --unspanned { msg: "path parameter 'datasetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), dataset_name: (encode-path-segment $dataset_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/datasets/{dataset_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a dataset.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets/{datasetName}
# operationId: Datasets_CreateOrUpdate
# --properties shape: {annotations?: list, description?: string, folder?: record, linkedServiceName: any, parameters?: record, schema?: record, structure?: record, type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets create-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  dataset_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the dataset entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # The Azure Data Factory nested object which identifies data within different data stores, such as tables, files, folders, and documents. — shape: {annotations?: list, description?: string, folder?: record, linkedServiceName: any, parameters?: record, schema?: record, structure?: record, type: string}
]: any -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, linkedServiceName: record<parameters: record, referenceName: string, type: string>, parameters: record, schema: record, structure: record, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($dataset_name | is-empty) { error make --unspanned { msg: "path parameter 'datasetName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), dataset_name: (encode-path-segment $dataset_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/datasets/{dataset_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a data flow debug session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/deleteDataFlowDebugSession
# operationId: DataFlowDebugSession_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-delete-data-flow-debug-session delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --session-id: string # The ID of data flow debug session.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/deleteDataFlowDebugSession") $qp)
  let req_body = {"sessionId": $session_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute a data flow debug command.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/executeDataFlowDebugCommand
# operationId: DataFlowDebugSession_ExecuteCommand
# --commandPayload shape: {columns?: list<string>, expression?: string, rowLimits?: int, streamName: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-execute-data-flow-debug-command create-session" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --command: string@command-completer # The command type.
  --command-payload: record # Structure of command payload. — shape: {columns?: list<string>, expression?: string, rowLimits?: int, streamName: string}
  --session-id: string # The ID of data flow debug session.
]: any -> record<data: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/executeDataFlowDebugCommand") $qp)
  let req_body = {"command": $command, "commandPayload": $command_payload, "sessionId": $session_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get Data Plane access.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/getDataPlaneAccess
# operationId: Factories_GetDataPlaneAccess
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-get-data-plane-access get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --access-resource-path: string # The resource path to get access relative to factory. Currently only empty string is supported which corresponds to the factory resource.
  --expire-time: string # Expiration time for the token. Maximum duration for the token is eight hours and by default the token will expire in eight hours.
  --permissions: string # The string with permissions for Data Plane access. Currently only 'r' is supported which grants read only access.
  --profile-name: string # The name of the profile. Currently only the default is supported. The default value is DefaultProfile.
  --start-time: string # Start time for the token. If not specified the current time will be used.
]: any -> record<accessToken: string, dataPlaneUrl: string, policy: record<accessResourcePath: string, expireTime: string, permissions: string, profileName: string, startTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/getDataPlaneAccess") $qp)
  let req_body = {"accessResourcePath": $access_resource_path, "expireTime": $expire_time, "permissions": $permissions, "profileName": $profile_name, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get exposure control feature for specific factory.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/getFeatureValue
# operationId: ExposureControl_GetFeatureValueByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-get-feature-value get-exposure-control" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --feature-name: string # The feature name.
  --feature-type: string # The feature type.
]: any -> record<featureName: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/getFeatureValue") $qp)
  let req_body = {"featureName": $feature_name, "featureType": $feature_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get GitHub Access Token.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/getGitHubAccessToken
# operationId: Factories_GetGitHubAccessToken
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-get-git-hub-access-token get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  git_hub_access_code: string # GitHub access code.
  git_hub_access_token_base_url: string # GitHub access token base URL.
  --git-hub-client-id: string # GitHub application client ID.
]: any -> record<gitHubAccessToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/getGitHubAccessToken") $qp)
  let req_body = {"gitHubAccessCode": $git_hub_access_code, "gitHubAccessTokenBaseUrl": $git_hub_access_token_base_url, "gitHubClientId": $git_hub_client_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists integration runtimes.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes
# operationId: IntegrationRuntimes_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes an integration runtime.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets an integration runtime.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the integration runtime entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<description: string, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates an integration runtime.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_Update
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --auto-update: string@auto-update-completer # The state of integration runtime auto update.
  --update-delay-offset: string # The time offset (in hours) in the day, e.g., PT03H is 3 hours. The integration runtime auto update will happen on that time.
]: any -> record<properties: record<description: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}") $qp)
  let req_body = {"autoUpdate": $auto_update, "updateDelayOffset": $update_delay_offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates an integration runtime.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_CreateOrUpdate
# --properties shape: {description?: string, type: "Managed"|"SelfHosted"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes create-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the integration runtime entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # Azure Data Factory nested object which serves as a compute resource for activities. — shape: {description?: string, type: "Managed"|"SelfHosted"}
]: any -> record<properties: record<description: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the on-premises integration runtime connection information for encrypting the on-premises data source credentials.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/getConnectionInfo
# operationId: IntegrationRuntimes_GetConnectionInfo
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-get-connection-info get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<hostServiceUri: string, identityCertThumbprint: string, isIdentityCertExprired: bool, publicKey: string, serviceToken: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/getConnectionInfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get a SSIS integration runtime object metadata by specified path. The return is pageable metadata list.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/getObjectMetadata
# operationId: IntegrationRuntimeObjectMetadata_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-get-object-metadata get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --metadata-path: string # Metadata path.
]: any -> record<nextLink: string, value: table<description: string, id: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/getObjectMetadata") $qp)
  let req_body = {"metadataPath": $metadata_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets detailed status information for an integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/getStatus
# operationId: IntegrationRuntimes_GetStatus
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-get-status get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<dataFactoryName: string, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/getStatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Create a linked integration runtime entry in a shared integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/linkedIntegrationRuntime
# operationId: IntegrationRuntimes_CreateLinkedIntegrationRuntime
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-linked-integration-runtime create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --data-factory-location: string # The location of the data factory that the linked integration runtime belongs to.
  --data-factory-name: string # The name of the data factory that the linked integration runtime belongs to.
  --name: string # The name of the linked integration runtime.
  --body-subscription-id: string # The ID of the subscription that the linked integration runtime belongs to.
]: any -> record<name: string, properties: record<dataFactoryName: string, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/linkedIntegrationRuntime") $qp)
  let req_body = {"dataFactoryLocation": $data_factory_location, "dataFactoryName": $data_factory_name, "name": $name, "subscriptionId": $body_subscription_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Retrieves the authentication keys for an integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/listAuthKeys
# operationId: IntegrationRuntimes_ListAuthKeys
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-list-auth-keys list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<authKey1: string, authKey2: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/listAuthKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get the integration runtime monitoring data, which includes the monitor data for all the nodes under this integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/monitoringData
# operationId: IntegrationRuntimes_GetMonitoringData
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-monitoring-data get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, nodes: table<availableMemoryInMB: int, concurrentJobsLimit: int, concurrentJobsRunning: int, cpuUtilization: int, maxConcurrentJobs: int, nodeName: string, receivedBytes: float, sentBytes: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/monitoringData") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a self-hosted integration runtime node.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}
# operationId: IntegrationRuntimeNodes_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name), node_name: (encode-path-segment $node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/nodes/{node_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a self-hosted integration runtime node.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}
# operationId: IntegrationRuntimeNodes_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<capabilities: record, concurrentJobsLimit: int, expiryTime: string, hostServiceUri: string, isActiveDispatcher: bool, lastConnectTime: string, lastEndUpdateTime: string, lastStartTime: string, lastStartUpdateTime: string, lastStopTime: string, lastUpdateResult: string, machineName: string, maxConcurrentJobs: int, nodeName: string, registerTime: string, status: string, version: string, versionStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name), node_name: (encode-path-segment $node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/nodes/{node_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a self-hosted integration runtime node.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}
# operationId: IntegrationRuntimeNodes_Update
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --concurrent-jobs-limit: int # The number of concurrent jobs permitted to run on the integration runtime node. Values between 1 and maxConcurrentJobs(inclusive) are allowed.
]: any -> record<capabilities: record, concurrentJobsLimit: int, expiryTime: string, hostServiceUri: string, isActiveDispatcher: bool, lastConnectTime: string, lastEndUpdateTime: string, lastStartTime: string, lastStartUpdateTime: string, lastStopTime: string, lastUpdateResult: string, machineName: string, maxConcurrentJobs: int, nodeName: string, registerTime: string, status: string, version: string, versionStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name), node_name: (encode-path-segment $node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/nodes/{node_name}") $qp)
  let req_body = {"concurrentJobsLimit": $concurrent_jobs_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get the IP address of self-hosted integration runtime node.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}/ipAddress
# operationId: IntegrationRuntimeNodes_GetIpAddress
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes-ip-address get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<ipAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name), node_name: (encode-path-segment $node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/nodes/{node_name}/ipAddress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Refresh a SSIS integration runtime object metadata.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/refreshObjectMetadata
# operationId: IntegrationRuntimeObjectMetadata_Refresh
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-refresh-object-metadata refresh" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: string, name: string, properties: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/refreshObjectMetadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Regenerates the authentication key for an integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/regenerateAuthKey
# operationId: IntegrationRuntimes_RegenerateAuthKey
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-regenerate-auth-key create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-name: string@key-name-completer # The name of the authentication key to regenerate.
]: any -> record<authKey1: string, authKey2: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/regenerateAuthKey") $qp)
  let req_body = {"keyName": $key_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Remove all linked integration runtimes under specific data factory in a self-hosted integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/removeLinks
# operationId: IntegrationRuntimes_RemoveLinks
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-remove-links delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --body-factory-name: string # The data factory name for linked integration runtime.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/removeLinks") $qp)
  let req_body = {"factoryName": $body_factory_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Starts a ManagedReserved type integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/start
# operationId: IntegrationRuntimes_Start
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-start start" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<dataFactoryName: string, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Stops a ManagedReserved type integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/stop
# operationId: IntegrationRuntimes_Stop
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-stop stop" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Force the integration runtime to synchronize credentials across integration runtime nodes, and this will override the credentials across all worker nodes with those available on the dispatcher node. If you already have the latest credential backup file, you should manually import it (preferred) on any self-hosted integration runtime node than using this API directly.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/syncCredentials
# operationId: IntegrationRuntimes_SyncCredentials
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-sync-credentials sync" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/syncCredentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Upgrade self-hosted integration runtime to latest version if availability.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/upgrade
# operationId: IntegrationRuntimes_Upgrade
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-upgrade create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  integration_runtime_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($integration_runtime_name | is-empty) { error make --unspanned { msg: "path parameter 'integrationRuntimeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), integration_runtime_name: (encode-path-segment $integration_runtime_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/integrationRuntimes/{integration_runtime_name}/upgrade") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists linked services.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices
# operationId: LinkedServices_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices list-linked-services" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/linkedservices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a linked service.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices/{linkedServiceName}
# operationId: LinkedServices_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices delete-linked-services" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  linked_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($linked_service_name | is-empty) { error make --unspanned { msg: "path parameter 'linkedServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), linked_service_name: (encode-path-segment $linked_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/linkedservices/{linked_service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a linked service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices/{linkedServiceName}
# operationId: LinkedServices_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices get-linked-services" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  linked_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the linked service entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, connectVia: record<parameters: record, referenceName: string, type: string>, description: string, parameters: record, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($linked_service_name | is-empty) { error make --unspanned { msg: "path parameter 'linkedServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), linked_service_name: (encode-path-segment $linked_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/linkedservices/{linked_service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a linked service.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices/{linkedServiceName}
# operationId: LinkedServices_CreateOrUpdate
# --properties shape: {annotations?: list, connectVia?: any, description?: string, parameters?: record, type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices create-linked-services-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  linked_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the linkedService entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # The Azure Data Factory nested object which contains the information and credential which can be used to connect with related store or compute resource. — shape: {annotations?: list, connectVia?: any, description?: string, parameters?: record, type: string}
]: any -> record<properties: record<annotations: list<record>, connectVia: record<parameters: record, referenceName: string, type: string>, description: string, parameters: record, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($linked_service_name | is-empty) { error make --unspanned { msg: "path parameter 'linkedServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), linked_service_name: (encode-path-segment $linked_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/linkedservices/{linked_service_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get a pipeline run by its run ID.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelineruns/{runId}
# operationId: PipelineRuns_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelineruns get-pipeline-runs" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<durationInMs: int, invokedBy: record<id: string, invokedByType: string, name: string>, isLatest: bool, lastUpdated: string, message: string, parameters: record, pipelineName: string, runDimensions: record, runEnd: string, runGroupId: string, runId: string, runStart: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelineruns/{run_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Cancel a pipeline run by its run ID.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelineruns/{runId}/cancel
# operationId: PipelineRuns_Cancel
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelineruns-cancel cancel-pipeline-runs" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-recursive: oneof<nothing, bool> # If true, cancel all the Child pipelines that are triggered by the current pipeline.
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "isRecursive" $is_recursive "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelineruns/{run_id}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isRecursive": $is_recursive, "api-version": $api_version} | compact), body: null}
}

# Query activity runs based on input filter conditions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelineruns/{runId}/queryActivityruns
# operationId: ActivityRuns_QueryByPipelineRun
# --filters item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list<string>}
# --orderBy item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelineruns-query-activityruns list-activity-runs-by-pipeline-run" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --continuation-token: string # The continuation token for getting the next page of results. Null for first page.
  --filters: list # List of filters. — item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list<string>}
  last_updated_after: string # The time at or after which the run event was updated in 'ISO 8601' format. (format: date-time)
  last_updated_before: string # The time at or before which the run event was updated in 'ISO 8601' format. (format: date-time)
  --order-by: list # List of OrderBy option. — item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
]: any -> record<continuationToken: string, value: table<activityName: string, activityRunEnd: string, activityRunId: string, activityRunStart: string, activityType: string, durationInMs: int, error: record, input: record, linkedServiceName: string, output: record, pipelineName: string, pipelineRunId: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelineruns/{run_id}/queryActivityruns") $qp)
  let req_body = {"continuationToken": $continuation_token, "filters": $filters, "lastUpdatedAfter": $last_updated_after, "lastUpdatedBefore": $last_updated_before, "orderBy": $order_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists pipelines.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines
# operationId: Pipelines_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a pipeline.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}
# operationId: Pipelines_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  pipeline_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($pipeline_name | is-empty) { error make --unspanned { msg: "path parameter 'pipelineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), pipeline_name: (encode-path-segment $pipeline_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelines/{pipeline_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a pipeline.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}
# operationId: Pipelines_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  pipeline_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the pipeline entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<activities: list<record>, annotations: list<record>, concurrency: int, description: string, folder: record<name: string>, parameters: record, runDimensions: record, variables: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($pipeline_name | is-empty) { error make --unspanned { msg: "path parameter 'pipelineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), pipeline_name: (encode-path-segment $pipeline_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelines/{pipeline_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a pipeline.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}
# operationId: Pipelines_CreateOrUpdate
# --properties shape: {activities?: list, annotations?: list, concurrency?: int, description?: string, folder?: record, parameters?: record, runDimensions?: record, variables?: record}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines create-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  pipeline_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the pipeline entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # A data factory pipeline. — shape: {activities?: list, annotations?: list, concurrency?: int, description?: string, folder?: record, parameters?: record, runDimensions?: record, variables?: record}
]: any -> record<properties: record<activities: list<record>, annotations: list<record>, concurrency: int, description: string, folder: record<name: string>, parameters: record, runDimensions: record, variables: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($pipeline_name | is-empty) { error make --unspanned { msg: "path parameter 'pipelineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), pipeline_name: (encode-path-segment $pipeline_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelines/{pipeline_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a run of a pipeline.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}/createRun
# operationId: Pipelines_CreateRun
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines-create-run create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  pipeline_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --reference-pipeline-run-id: string # The pipeline run identifier. If run ID is specified the parameters of the specified run will be used to create a new run.
  --is-recovery: oneof<nothing, bool> # Recovery mode flag. If recovery mode is set to true, the specified referenced pipeline run and the new run will be grouped under the same groupId.
  --start-activity-name: string # In recovery mode, the rerun will start from this activity. If not specified, all activities will run.
  --body: record
]: any -> record<runId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($pipeline_name | is-empty) { error make --unspanned { msg: "path parameter 'pipelineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "referencePipelineRunId" $reference_pipeline_run_id "scalar") (serialize-qp "isRecovery" $is_recovery "scalar") (serialize-qp "startActivityName" $start_activity_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), pipeline_name: (encode-path-segment $pipeline_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/pipelines/{pipeline_name}/createRun") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "referencePipelineRunId": $reference_pipeline_run_id, "isRecovery": $is_recovery, "startActivityName": $start_activity_name} | compact), body: $req_body}
}

# Query all active data flow debug sessions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/queryDataFlowDebugSessions
# operationId: DataFlowDebugSession_QueryByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-query-data-flow-debug-sessions list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<computeType: string, coreCount: int, dataFlowName: string, integrationRuntimeName: string, lastActivityTime: string, nodeCount: int, sessionId: string, startTime: string, timeToLiveInMinutes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/queryDataFlowDebugSessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Query pipeline runs in the factory based on input filter conditions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/queryPipelineRuns
# operationId: PipelineRuns_QueryByFactory
# --filters item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list<string>}
# --orderBy item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-query-pipeline-runs list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --continuation-token: string # The continuation token for getting the next page of results. Null for first page.
  --filters: list # List of filters. — item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list<string>}
  last_updated_after: string # The time at or after which the run event was updated in 'ISO 8601' format. (format: date-time)
  last_updated_before: string # The time at or before which the run event was updated in 'ISO 8601' format. (format: date-time)
  --order-by: list # List of OrderBy option. — item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
]: any -> record<continuationToken: string, value: table<durationInMs: int, invokedBy: record, isLatest: bool, lastUpdated: string, message: string, parameters: record, pipelineName: string, runDimensions: record, runEnd: string, runGroupId: string, runId: string, runStart: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/queryPipelineRuns") $qp)
  let req_body = {"continuationToken": $continuation_token, "filters": $filters, "lastUpdatedAfter": $last_updated_after, "lastUpdatedBefore": $last_updated_before, "orderBy": $order_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Query trigger runs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/queryTriggerRuns
# operationId: TriggerRuns_QueryByFactory
# --filters item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list<string>}
# --orderBy item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-query-trigger-runs trigger" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --continuation-token: string # The continuation token for getting the next page of results. Null for first page.
  --filters: list # List of filters. — item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list<string>}
  last_updated_after: string # The time at or after which the run event was updated in 'ISO 8601' format. (format: date-time)
  last_updated_before: string # The time at or before which the run event was updated in 'ISO 8601' format. (format: date-time)
  --order-by: list # List of OrderBy option. — item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
]: any -> record<continuationToken: string, value: table<dependencyStatus: record, message: string, properties: record, runDimension: record, status: string, triggerName: string, triggerRunId: string, triggerRunTimestamp: string, triggerType: string, triggeredPipelines: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/queryTriggerRuns") $qp)
  let req_body = {"continuationToken": $continuation_token, "filters": $filters, "lastUpdatedAfter": $last_updated_after, "lastUpdatedBefore": $last_updated_before, "orderBy": $order_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists triggers.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers
# operationId: Triggers_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a trigger.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}
# operationId: Triggers_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers delete" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a trigger.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}
# operationId: Triggers_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-none-match: string # ETag of the trigger entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, description: string, runtimeState: string, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a trigger.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}
# operationId: Triggers_CreateOrUpdate
# --properties shape: {annotations?: list, description?: string, runtimeState?: "Started"|"Stopped"|"Disabled", type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers create-or-update" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --if-match: string # ETag of the trigger entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # Azure data factory nested object which contains information about creating pipeline run — shape: {annotations?: list, description?: string, runtimeState?: "Started"|"Stopped"|"Disabled", type: string}
]: any -> record<properties: record<annotations: list<record>, description: string, runtimeState: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get a trigger's event subscription status.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/getEventSubscriptionStatus
# operationId: Triggers_GetEventSubscriptionStatus
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-get-event-subscription-status get" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<status: string, triggerName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/getEventSubscriptionStatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists rerun triggers by an original trigger name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers
# operationId: RerunTriggers_ListByTrigger
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers list" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/rerunTriggers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates a rerun trigger.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}
# operationId: RerunTriggers_Create
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers create" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  rerun_trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  end_time: string # The end time for the time period for which restatement is initiated. Only UTC time is currently supported. (format: date-time)
  max_concurrency: int # The max number of parallel time windows (ready for execution) for which a rerun is triggered.
  start_time: string # The start time for the time period for which restatement is initiated. Only UTC time is currently supported. (format: date-time)
]: any -> record<properties: record<annotations: list<record>, description: string, runtimeState: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($rerun_trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'rerunTriggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name), rerun_trigger_name: (encode-path-segment $rerun_trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/rerunTriggers/{rerun_trigger_name}") $qp)
  let req_body = {"endTime": $end_time, "maxConcurrency": $max_concurrency, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Cancels a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}/cancel
# operationId: RerunTriggers_Cancel
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers-cancel cancel" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  rerun_trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($rerun_trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'rerunTriggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name), rerun_trigger_name: (encode-path-segment $rerun_trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/rerunTriggers/{rerun_trigger_name}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Starts a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}/start
# operationId: RerunTriggers_Start
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers-start start" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  rerun_trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($rerun_trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'rerunTriggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name), rerun_trigger_name: (encode-path-segment $rerun_trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/rerunTriggers/{rerun_trigger_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Stops a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}/stop
# operationId: RerunTriggers_Stop
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers-stop stop" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  rerun_trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($rerun_trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'rerunTriggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name), rerun_trigger_name: (encode-path-segment $rerun_trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/rerunTriggers/{rerun_trigger_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Starts a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/start
# operationId: Triggers_Start
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-start start" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Stops a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/stop
# operationId: Triggers_Stop
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-stop stop" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Subscribe event trigger to events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/subscribeToEvents
# operationId: Triggers_SubscribeToEvents
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-subscribe-to-events subscribe" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<status: string, triggerName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/subscribeToEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Rerun single trigger instance by runId.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/triggerRuns/{runId}/rerun
# operationId: TriggerRuns_Rerun
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-trigger-runs-rerun trigger" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/triggerRuns/{run_id}/rerun") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Unsubscribe event trigger from events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/unsubscribeFromEvents
# operationId: Triggers_UnsubscribeFromEvents
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-unsubscribe-from-events unsubscribe" [
  subscription_id: string
  resource_group_name: string
  factory_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<status: string, triggerName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($factory_name | is-empty) { error make --unspanned { msg: "path parameter 'factoryName' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'triggerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), factory_name: (encode-path-segment $factory_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DataFactory/factories/{factory_name}/triggers/{trigger_name}/unsubscribeFromEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}
