# Auto-generated client for Replica Pool vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/replicapool/v1beta1/openapi.json
# Auth: --token flag or $env.REPLICA_POOL_TOKEN

const BASE_URL = "https://www.googleapis.com/replicapool/v1beta1/projects"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REPLICA_POOL_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://www.googleapis.com/replicapool/v1beta1/projects"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "zones-pools list" } } | get name | first)
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

# List all replica pools.
#
# GET /{projectName}/zones/{zone}/pools
# operationId: replicapool.pools.list
export def "zones-pools list" [
  project_name: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum count of results to be returned. Acceptable values are 0 to 100, inclusive. (Default: 50) (default: 500)
  --page-token: string # Set this to the nextPageToken value returned by a previous list request to obtain the next page of results from the previous list request.
]: nothing -> record<nextPageToken: string, resources: table<autoRestart: bool, baseInstanceName: string, currentNumReplicas: int, description: string, healthChecks: list, initialNumReplicas: int, labels: list, name: string, numReplicas: int, resourceViews: list, selfLink: string, targetPool: string, targetPools: list, template: record, type: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone)} | format pattern "/{project_name}/zones/{zone}/pools") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Inserts a new replica pool.
#
# POST /{projectName}/zones/{zone}/pools
# operationId: replicapool.pools.insert
# --healthChecks item shape: {checkIntervalSec?: int, description?: string, healthyThreshold?: int, host?: string, name?: string, path?: string, port?: int, timeoutSec?: int, unhealthyThreshold?: int}
# --labels item shape: {key?: string, value?: string}
# --template shape: {action?: record, healthChecks?: list, version?: string, vmParams?: record}
export def "zones-pools create" [
  project_name: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --auto-restart: oneof<nothing, bool> # Whether replicas in this pool should be restarted if they experience a failure. The default value is true.
  --base-instance-name: string # The base instance name to use for the replicas in this pool. This must match the regex [a-z]([-a-z0-9]*[a-z0-9])?. If specified, the instances in this replica pool will be named in the format <base-instance-name>-. The postfix will be a four character alphanumeric identifier generated by the service. If this is not specified by the user, a random base instance name is generated by the service.
  --current-num-replicas: int # [Output Only] The current number of replicas in the pool. (format: int32)
  --description: string # An optional description of the replica pool.
  --health-checks: list # Deprecated. Please use template[].healthChecks instead. — item shape: {checkIntervalSec?: int, description?: string, healthyThreshold?: int, host?: string, name?: string, path?: string, port?: int, timeoutSec?: int, unhealthyThreshold?: int}
  --initial-num-replicas: int # The initial number of replicas this pool should have. You must provide a value greater than or equal to 0. (format: int32)
  --labels: list # A list of labels to attach to this replica pool and all created virtual machines in this replica pool. — item shape: {key?: string, value?: string}
  --name: string # The name of the replica pool. Must follow the regex [a-z]([-a-z0-9]*[a-z0-9])? and be 1-28 characters long.
  --num-replicas: int # Deprecated! Use initial_num_replicas instead. (format: int32)
  --resource-views: list<string> # The list of resource views that should be updated with all the replicas that are managed by this pool.
  --self-link: string # [Output Only] A self-link to the replica pool.
  --target-pool: string # Deprecated, please use target_pools instead.
  --target-pools: list<string> # A list of target pools to update with the replicas that are managed by this pool. If specified, the replicas in this replica pool will be added to the specified target pools for load balancing purposes. The replica pool must live in the same region as the specified target pools. These values must be the target pool resource names, and not fully qualified URLs.
  --template: record # The template used for creating replicas in the pool. — shape: {action?: record, healthChecks?: list, version?: string, vmParams?: record}
  --type: string # Deprecated! Do not set.
]: any -> record<autoRestart: bool, baseInstanceName: string, currentNumReplicas: int, description: string, healthChecks: table<checkIntervalSec: int, description: string, healthyThreshold: int, host: string, name: string, path: string, port: int, timeoutSec: int, unhealthyThreshold: int>, initialNumReplicas: int, labels: table<key: string, value: string>, name: string, numReplicas: int, resourceViews: list<string>, selfLink: string, targetPool: string, targetPools: list<string>, template: record<action: record<commands: list, envVariables: list, timeoutMilliSeconds: int>, healthChecks: list<record>, version: string, vmParams: record<baseInstanceName: string, canIpForward: bool, description: string, disksToAttach: list, disksToCreate: list, machineType: string, metadata: record, networkInterfaces: list, onHostMaintenance: string, serviceAccounts: list, tags: record>>, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone)} | format pattern "/{project_name}/zones/{zone}/pools") $qp)
  let req_body = {"autoRestart": $auto_restart, "baseInstanceName": $base_instance_name, "currentNumReplicas": $current_num_replicas, "description": $description, "healthChecks": $health_checks, "initialNumReplicas": $initial_num_replicas, "labels": $labels, "name": $name, "numReplicas": $num_replicas, "resourceViews": $resource_views, "selfLink": $self_link, "targetPool": $target_pool, "targetPools": $target_pools, "template": $template, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Gets information about a single replica pool.
#
# GET /{projectName}/zones/{zone}/pools/{poolName}
# operationId: replicapool.pools.get
export def "zones-pools get" [
  project_name: string
  zone: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<autoRestart: bool, baseInstanceName: string, currentNumReplicas: int, description: string, healthChecks: table<checkIntervalSec: int, description: string, healthyThreshold: int, host: string, name: string, path: string, port: int, timeoutSec: int, unhealthyThreshold: int>, initialNumReplicas: int, labels: table<key: string, value: string>, name: string, numReplicas: int, resourceViews: list<string>, selfLink: string, targetPool: string, targetPools: list<string>, template: record<action: record<commands: list, envVariables: list, timeoutMilliSeconds: int>, healthChecks: list<record>, version: string, vmParams: record<baseInstanceName: string, canIpForward: bool, description: string, disksToAttach: list, disksToCreate: list, machineType: string, metadata: record, networkInterfaces: list, onHostMaintenance: string, serviceAccounts: list, tags: record>>, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Deletes a replica pool.
#
# POST /{projectName}/zones/{zone}/pools/{poolName}
# operationId: replicapool.pools.delete
export def "zones-pools delete" [
  project_name: string
  zone: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --abandon-instances: list<string> # If there are instances you would like to keep, you can specify them here. These instances won't be deleted, but the associated replica objects will be removed.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}") $qp)
  let req_body = {"abandonInstances": $abandon_instances} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Lists all replicas in a pool.
#
# GET /{projectName}/zones/{zone}/pools/{poolName}/replicas
# operationId: replicapool.replicas.list
export def "zones-pools-replicas list" [
  project_name: string
  zone: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum count of results to be returned. Acceptable values are 0 to 100, inclusive. (Default: 50) (default: 500)
  --page-token: string # Set this to the nextPageToken value returned by a previous list request to obtain the next page of results from the previous list request.
]: nothing -> record<nextPageToken: string, resources: table<name: string, selfLink: string, status: record>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}/replicas") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Gets information about a specific replica.
#
# GET /{projectName}/zones/{zone}/pools/{poolName}/replicas/{replicaName}
# operationId: replicapool.replicas.get
export def "zones-pools-replicas get" [
  project_name: string
  zone: string
  pool_name: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<name: string, selfLink: string, status: record<details: string, state: string, templateVersion: string, vmLink: string, vmStartTime: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replicaName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name), replica_name: (encode-path-segment $replica_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}/replicas/{replica_name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Deletes a replica from the pool.
#
# POST /{projectName}/zones/{zone}/pools/{poolName}/replicas/{replicaName}
# operationId: replicapool.replicas.delete
export def "zones-pools-replicas delete" [
  project_name: string
  zone: string
  pool_name: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --abandon-instance: oneof<nothing, bool> # Whether the instance resource represented by this replica should be deleted or abandoned. If abandoned, the replica will be deleted but the virtual machine instance will remain. By default, this is set to false and the instance will be deleted along with the replica.
]: any -> record<name: string, selfLink: string, status: record<details: string, state: string, templateVersion: string, vmLink: string, vmStartTime: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replicaName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name), replica_name: (encode-path-segment $replica_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}/replicas/{replica_name}") $qp)
  let req_body = {"abandonInstance": $abandon_instance} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Restarts a replica in a pool.
#
# POST /{projectName}/zones/{zone}/pools/{poolName}/replicas/{replicaName}/restart
# operationId: replicapool.replicas.restart
export def "zones-pools-replicas-restart restart" [
  project_name: string
  zone: string
  pool_name: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<name: string, selfLink: string, status: record<details: string, state: string, templateVersion: string, vmLink: string, vmStartTime: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replicaName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name), replica_name: (encode-path-segment $replica_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}/replicas/{replica_name}/restart") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Resize a pool. This is an asynchronous operation, and multiple overlapping resize requests can be made. Replica Pools will use the information from the last resize request.
#
# POST /{projectName}/zones/{zone}/pools/{poolName}/resize
# operationId: replicapool.pools.resize
export def "zones-pools-resize resize" [
  project_name: string
  zone: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --num-replicas: int # The desired number of replicas to resize to. If this number is larger than the existing number of replicas, new replicas will be added. If the number is smaller, then existing replicas will be deleted.
]: nothing -> record<autoRestart: bool, baseInstanceName: string, currentNumReplicas: int, description: string, healthChecks: table<checkIntervalSec: int, description: string, healthyThreshold: int, host: string, name: string, path: string, port: int, timeoutSec: int, unhealthyThreshold: int>, initialNumReplicas: int, labels: table<key: string, value: string>, name: string, numReplicas: int, resourceViews: list<string>, selfLink: string, targetPool: string, targetPools: list<string>, template: record<action: record<commands: list, envVariables: list, timeoutMilliSeconds: int>, healthChecks: list<record>, version: string, vmParams: record<baseInstanceName: string, canIpForward: bool, description: string, disksToAttach: list, disksToCreate: list, machineType: string, metadata: record, networkInterfaces: list, onHostMaintenance: string, serviceAccounts: list, tags: record>>, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "numReplicas" $num_replicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}/resize") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "numReplicas": $num_replicas} | compact), body: null}
}

# Update the template used by the pool.
#
# POST /{projectName}/zones/{zone}/pools/{poolName}/updateTemplate
# operationId: replicapool.pools.updatetemplate
# --action shape: {commands?: list<string>, envVariables?: list, timeoutMilliSeconds?: int}
# --healthChecks item shape: {checkIntervalSec?: int, description?: string, healthyThreshold?: int, host?: string, name?: string, path?: string, port?: int, timeoutSec?: int, unhealthyThreshold?: int}
# --vmParams shape: {baseInstanceName?: string, canIpForward?: bool, description?: string, disksToAttach?: list, disksToCreate?: list, machineType?: string, metadata?: record, networkInterfaces?: list, onHostMaintenance?: string, serviceAccounts?: list, tags?: record}
export def "zones-pools-update-template update" [
  project_name: string
  zone: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --action: record # An action that gets executed during initialization of the replicas. — shape: {commands?: list<string>, envVariables?: list, timeoutMilliSeconds?: int}
  --health-checks: list # A list of HTTP Health Checks to configure for this replica pool and all virtual machines in this replica pool. — item shape: {checkIntervalSec?: int, description?: string, healthyThreshold?: int, host?: string, name?: string, path?: string, port?: int, timeoutSec?: int, unhealthyThreshold?: int}
  --version: string # A free-form string describing the version of this template. You can provide any versioning string you would like. For example, version1 or template-v1.
  --vm-params: record # Parameters for creating a Compute Engine Instance resource. Most fields are identical to the corresponding Compute Engine resource. — shape: {baseInstanceName?: string, canIpForward?: bool, description?: string, disksToAttach?: list, disksToCreate?: list, machineType?: string, metadata?: record, networkInterfaces?: list, onHostMaintenance?: string, serviceAccounts?: list, tags?: record}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o REPLICA_POOL_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o REPLICA_POOL_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'projectName' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'poolName' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), zone: (encode-path-segment $zone), pool_name: (encode-path-segment $pool_name)} | format pattern "/{project_name}/zones/{zone}/pools/{pool_name}/updateTemplate") $qp)
  let req_body = {"action": $action, "healthChecks": $health_checks, "version": $version, "vmParams": $vm_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}
