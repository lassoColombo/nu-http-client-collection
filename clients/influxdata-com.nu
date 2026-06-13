# Auto-generated client for Influx OSS API Service v2.0.0
# Source: https://api.apis.guru/v2/specs/influxdata.com/2.0.0/openapi.json
# Auth: --token flag or $env.INFLUX_OSS_API_SERVICE_TOKEN

const BASE_URL = "http://localhost/api/v2"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INFLUX_OSS_API_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost/api/v2" ""] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def status-completer [] { ["active" "inactive"] }
def schemaType-completer [] { ["explicit" "implicit"] }
def sortBy-completer [] { ["CreatedAt" "ID" "UpdatedAt"] }
def include-completer [] { ["properties"] }
def type-completer [] { ["flux"] }
def Accept-Encoding-completer [] { ["gzip" "identity"] }
def Content-Type-completer [] { ["application/json" "application/vnd.flux"] }
def accept-completer [] { ["application/json" "application/vnd.influx.arrow" "text/csv"] }
def Content-Type-completer-1 [] { ["application/json"] }
def type-completer-1 [] { ["prometheus"] }
def type-completer-2 [] { ["self" "v1" "v2"] }
def Accept-completer [] { ["application/json" "application/octet-stream" "application/toml"] }
def accept-completer-1 [] { ["application/json" "application/octet-stream" "application/toml"] }
def accept-completer-2 [] { ["application/json" "application/x-yaml"] }
def precision-completer [] { ["ms" "ns" "s" "us"] }
def Content-Encoding-completer [] { ["gzip" "identity"] }
def Content-Type-completer-2 [] { ["application/vnd.influx.arrow" "text/plain" "text/plain; charset=utf-8"] }
def Accept-completer-1 [] { ["application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "routes GetRoutes" } } | get name | first)
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

# List all top level routes
#
# GET /
# operationId: GetRoutes
export def "routes GetRoutes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<authorizations: string, buckets: string, dashboards: string, external: record<statusFeed: string>, flags: string, me: string, orgs: string, query: record<analyze: string, ast: string, self: string, suggestions: string>, setup: string, signin: string, signout: string, sources: string, system: record<debug: string, health: string, metrics: string>, tasks: string, telegrafs: string, users: string, variables: string, write: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all authorizations
#
# GET /authorizations
# operationId: GetAuthorizations
export def "authorizations GetAuthorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userID: string # Only show authorizations that belong to a user ID.
  --user: string # Only show authorizations that belong to a user name.
  --orgID: string # Only show authorizations that belong to an organization ID.
  --org: string # Only show authorizations that belong to a organization name.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<authorizations: table<description: string, status: string, createdAt: string, id: string, links: record, org: string, orgID: string, permissions: list, token: string, updatedAt: string, user: string, userID: string>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userID" $userID "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorizations" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an authorization
#
# POST /authorizations
# operationId: PostAuthorizations
# --permissions item shape: {action: "read"|"write", resource: record}
export def "authorizations PostAuthorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # A description of the token.
  --status: string@status-completer # If inactive the token is inactive and requests using the token will be rejected. (default: active)
  orgID: string # ID of org that authorization is scoped to.
  permissions: list # List of permissions for an auth.  An auth must have at least one Permission. — item shape: {action: "read"|"write", resource: record}
  --userID: string # ID of user that authorization is scoped to.
]: any -> record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorizations")
  let body = {description: $description, status: $status, orgID: $orgID, permissions: $permissions, userID: $userID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an authorization
#
# DELETE /authorizations/{authID}
# operationId: DeleteAuthorizationsID
export def "authorizations DeleteAuthorizationsID" [
  authID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorizations/($authID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an authorization
#
# GET /authorizations/{authID}
# operationId: GetAuthorizationsID
export def "authorizations GetAuthorizationsID" [
  authID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorizations/($authID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an authorization to be active or inactive
#
# PATCH /authorizations/{authID}
# operationId: PatchAuthorizationsID
export def "authorizations PatchAuthorizationsID" [
  authID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # A description of the token.
  --status: string@status-completer # If inactive the token is inactive and requests using the token will be rejected. (default: active)
]: any -> record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorizations/($authID)")
  let body = {description: $description, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all buckets
#
# GET /buckets
# operationId: GetBuckets
export def "buckets GetBuckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --after: string # The last resource ID from which to seek from (but not including). This is to be used instead of `offset`.
  --org: string # The name of the organization.
  --orgID: string # The organization ID.
  --name: string # Only returns buckets with a specific name.
  --id: string # Only returns buckets with a specific ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buckets" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a bucket
#
# POST /buckets
# operationId: PostBuckets
# --retentionRules item shape: {everySeconds: int, shardGroupDurationSeconds?: int, type: "expire"}
export def "buckets PostBuckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  name: string
  orgID: string
  retentionRules: list # Rules to expire or retain data.  No rules means data never expires. — item shape: {everySeconds: int, shardGroupDurationSeconds?: int, type: "expire"}
  --rp: string
  --schemaType: string@schemaType-completer
]: any -> record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets")
  let body = {description: $description, name: $name, orgID: $orgID, retentionRules: $retentionRules, rp: $rp, schemaType: $schemaType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a bucket
#
# DELETE /buckets/{bucketID}
# operationId: DeleteBucketsID
export def "buckets DeleteBucketsID" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a bucket
#
# GET /buckets/{bucketID}
# operationId: GetBucketsID
export def "buckets GetBucketsID" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a bucket
#
# PATCH /buckets/{bucketID}
# operationId: PatchBucketsID
# --retentionRules item shape: {everySeconds?: int, shardGroupDurationSeconds?: int, type: "expire"}
export def "buckets PatchBucketsID" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --retentionRules: list # Updates to rules to expire or retain data. No rules means no updates. — item shape: {everySeconds?: int, shardGroupDurationSeconds?: int, type: "expire"}
]: any -> record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)")
  let body = {description: $description, name: $name, retentionRules: $retentionRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a bucket
#
# GET /buckets/{bucketID}/labels
# operationId: GetBucketsIDLabels
export def "buckets-labels GetBucketsIDLabels" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a bucket
#
# POST /buckets/{bucketID}/labels
# operationId: PostBucketsIDLabels
export def "buckets-labels PostBucketsIDLabels" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a bucket
#
# DELETE /buckets/{bucketID}/labels/{labelID}
# operationId: DeleteBucketsIDLabelsID
export def "buckets-labels DeleteBucketsIDLabelsID" [
  bucketID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users with member privileges for a bucket
#
# GET /buckets/{bucketID}/members
# operationId: GetBucketsIDMembers
export def "buckets-members GetBucketsIDMembers" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a bucket
#
# POST /buckets/{bucketID}/members
# operationId: PostBucketsIDMembers
export def "buckets-members PostBucketsIDMembers" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a bucket
#
# DELETE /buckets/{bucketID}/members/{userID}
# operationId: DeleteBucketsIDMembersID
export def "buckets-members DeleteBucketsIDMembersID" [
  userID: string
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a bucket
#
# GET /buckets/{bucketID}/owners
# operationId: GetBucketsIDOwners
export def "buckets-owners GetBucketsIDOwners" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a bucket
#
# POST /buckets/{bucketID}/owners
# operationId: PostBucketsIDOwners
export def "buckets-owners PostBucketsIDOwners" [
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a bucket
#
# DELETE /buckets/{bucketID}/owners/{userID}
# operationId: DeleteBucketsIDOwnersID
export def "buckets-owners DeleteBucketsIDOwnersID" [
  userID: string
  bucketID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/buckets/($bucketID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all checks
#
# GET /checks
# operationId: GetChecks
export def "checks GetChecks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --orgID: string # Only show checks that belong to a specific organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<checks: list<record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checks" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new check
#
# POST /checks
# operationId: CreateCheck
export def "checks CreateCheck" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a check
#
# DELETE /checks/{checkID}
# operationId: DeleteChecksID
export def "checks DeleteChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a check
#
# GET /checks/{checkID}
# operationId: GetChecksID
export def "checks GetChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a check
#
# PATCH /checks/{checkID}
# operationId: PatchChecksID
export def "checks PatchChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let body = {description: $description, name: $name, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a check
#
# PUT /checks/{checkID}
# operationId: PutChecksID
export def "checks PutChecksID" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a check
#
# GET /checks/{checkID}/labels
# operationId: GetChecksIDLabels
export def "checks-labels GetChecksIDLabels" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a check
#
# POST /checks/{checkID}/labels
# operationId: PostChecksIDLabels
export def "checks-labels PostChecksIDLabels" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete label from a check
#
# DELETE /checks/{checkID}/labels/{labelID}
# operationId: DeleteChecksIDLabelsID
export def "checks-labels DeleteChecksIDLabelsID" [
  checkID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a check query
#
# GET /checks/{checkID}/query
# operationId: GetChecksIDQuery
export def "checks-query GetChecksIDQuery" [
  checkID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<flux: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($checkID)/query")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all dashboards
#
# GET /dashboards
# operationId: GetDashboards
export def "dashboards GetDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --descending: oneof<nothing, bool> # default: false
  --owner: string # A user identifier. Returns only dashboards where this user has the `owner` role.
  --sortBy: string@sortBy-completer # The column to sort by.
  --id: list # A list of dashboard identifiers. Returns only the listed dashboards. If both `id` and `owner` are specified, only `id` is used.
  --orgID: string # The identifier of the organization.
  --org: string # The name of the organization.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<dashboards: list<record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboards" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a dashboard
#
# POST /dashboards
# operationId: PostDashboards
export def "dashboards PostDashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # The user-facing description of the dashboard.
  name: string # The user-facing name of the dashboard.
  orgID: string # The ID of the organization that owns the dashboard.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards")
  let body = {description: $description, name: $name, orgID: $orgID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a dashboard
#
# DELETE /dashboards/{dashboardID}
# operationId: DeleteDashboardsID
export def "dashboards DeleteDashboardsID" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Dashboard
#
# GET /dashboards/{dashboardID}
# operationId: GetDashboardsID
export def "dashboards GetDashboardsID" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Includes the cell view properties in the response if set to `properties`
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dashboards/($dashboardID)" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a dashboard
#
# PATCH /dashboards/{dashboardID}
# operationId: PatchDashboardsID
# --cells shape: {h?: int, id?: string, links?: record, viewID?: string, w?: int, x?: int, y?: int, name?: string, properties?: any}
export def "dashboards PatchDashboardsID" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --cells: record # shape: {h?: int, id?: string, links?: record, viewID?: string, w?: int, x?: int, y?: int, name?: string, properties?: any}
  --description: string # optional, when provided will replace the description
  --name: string # optional, when provided will replace the name
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)")
  let body = {cells: $cells, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a dashboard cell
#
# POST /dashboards/{dashboardID}/cells
# operationId: PostDashboardsIDCells
export def "dashboards-cells PostDashboardsIDCells" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --h: int # format: int32
  --name: string
  --usingView: string # Makes a copy of the provided view.
  --w: int # format: int32
  --x: int # format: int32
  --y: int # format: int32
]: any -> record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells")
  let body = {h: $h, name: $name, usingView: $usingView, w: $w, x: $x, y: $y} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace cells in a dashboard
#
# PUT /dashboards/{dashboardID}/cells
# operationId: PutDashboardsIDCells
export def "dashboards-cells PutDashboardsIDCells" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a dashboard cell
#
# DELETE /dashboards/{dashboardID}/cells/{cellID}
# operationId: DeleteDashboardsIDCellsID
export def "dashboards-cells DeleteDashboardsIDCellsID" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the non-positional information related to a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}
# operationId: PatchDashboardsIDCellsID
export def "dashboards-cells PatchDashboardsIDCellsID" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --h: int # format: int32
  --w: int # format: int32
  --x: int # format: int32
  --y: int # format: int32
]: any -> record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)")
  let body = {h: $h, w: $w, x: $x, y: $y} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the view for a cell
#
# GET /dashboards/{dashboardID}/cells/{cellID}/view
# operationId: GetDashboardsIDCellsIDView
export def "dashboards-cells-view GetDashboardsIDCellsIDView" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<id: string, links: record<self: string>, name: string, properties: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)/view")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the view for a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}/view
# operationId: PatchDashboardsIDCellsIDView
# --links shape: {self?: string}
export def "dashboards-cells-view PatchDashboardsIDCellsIDView" [
  dashboardID: string
  cellID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  properties: any
]: any -> record<id: string, links: record<self: string>, name: string, properties: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/cells/($cellID)/view")
  let body = {name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a dashboard
#
# GET /dashboards/{dashboardID}/labels
# operationId: GetDashboardsIDLabels
export def "dashboards-labels GetDashboardsIDLabels" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a dashboard
#
# POST /dashboards/{dashboardID}/labels
# operationId: PostDashboardsIDLabels
export def "dashboards-labels PostDashboardsIDLabels" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a dashboard
#
# DELETE /dashboards/{dashboardID}/labels/{labelID}
# operationId: DeleteDashboardsIDLabelsID
export def "dashboards-labels DeleteDashboardsIDLabelsID" [
  dashboardID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all dashboard members
#
# GET /dashboards/{dashboardID}/members
# operationId: GetDashboardsIDMembers
export def "dashboards-members GetDashboardsIDMembers" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a dashboard
#
# POST /dashboards/{dashboardID}/members
# operationId: PostDashboardsIDMembers
export def "dashboards-members PostDashboardsIDMembers" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a dashboard
#
# DELETE /dashboards/{dashboardID}/members/{userID}
# operationId: DeleteDashboardsIDMembersID
export def "dashboards-members DeleteDashboardsIDMembersID" [
  userID: string
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all dashboard owners
#
# GET /dashboards/{dashboardID}/owners
# operationId: GetDashboardsIDOwners
export def "dashboards-owners GetDashboardsIDOwners" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a dashboard
#
# POST /dashboards/{dashboardID}/owners
# operationId: PostDashboardsIDOwners
export def "dashboards-owners PostDashboardsIDOwners" [
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a dashboard
#
# DELETE /dashboards/{dashboardID}/owners/{userID}
# operationId: DeleteDashboardsIDOwnersID
export def "dashboards-owners DeleteDashboardsIDOwnersID" [
  userID: string
  dashboardID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/($dashboardID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all database retention policy mappings
#
# GET /dbrps
# operationId: GetDBRPs
export def "dbrps GetDBRPs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # Specifies the organization ID to filter on
  --id: string # Specifies the mapping ID to filter on
  --bucketID: string # Specifies the bucket ID to filter on
  --default: oneof<nothing, bool> # Specifies filtering on default
  --db: string # Specifies the database to filter on
  --rp: string # Specifies the retention policy to filter on
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<content: table<bucketID: string, database: string, default: bool, id: string, links: record, org: string, orgID: string, retention_policy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "bucketID" $bucketID "scalar") (serialize-qp "default" $default "scalar") (serialize-qp "db" $db "scalar") (serialize-qp "rp" $rp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dbrps" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a database retention policy mapping
#
# POST /dbrps
# operationId: PostDBRP
export def "dbrps PostDBRP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --bucketID: string # the bucket ID used as target for the translation.
  --database: string # InfluxDB v1 database
  --default: oneof<nothing, bool> # Specify if this mapping represents the default retention policy for the database specificed.
  --links: record
  --org: string # the organization that owns this mapping.
  --orgID: string # the organization ID that owns this mapping.
  --retention-policy: string # InfluxDB v1 retention policy
]: any -> record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbrps")
  let body = {bucketID: $bucketID, database: $database, default: $default, links: $links, org: $org, orgID: $orgID, retention_policy: $retention_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a database retention policy
#
# DELETE /dbrps/{dbrpID}
# operationId: DeleteDBRPID
export def "dbrps DeleteDBRPID" [
  dbrpID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # Specifies the organization ID of the mapping
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dbrps/($dbrpID)" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a database retention policy mapping
#
# GET /dbrps/{dbrpID}
# operationId: GetDBRPsID
export def "dbrps GetDBRPsID" [
  dbrpID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # Specifies the organization ID of the mapping
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dbrps/($dbrpID)" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a database retention policy mapping
#
# PATCH /dbrps/{dbrpID}
# operationId: PatchDBRPID
export def "dbrps PatchDBRPID" [
  dbrpID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # Specifies the organization ID of the mapping
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --database: string # InfluxDB v1 database
  --default: oneof<nothing, bool>
  --links: record
  --retention-policy: string # InfluxDB v1 retention policy
]: any -> record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dbrps/($dbrpID)" $qp)
  let body = {database: $database, default: $default, links: $links, retention_policy: $retention_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete time series data from InfluxDB
#
# POST /delete
# operationId: PostDelete
export def "delete PostDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the organization to delete data from.
  --bucket: string # Specifies the bucket to delete data from.
  --orgID: string # Specifies the organization ID of the resource.
  --bucketID: string # Specifies the bucket ID to delete data from.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --predicate: string # InfluxQL-like delete statement (e.g. tag1="value1" and (tag2="value2" and tag3!="value3"))
  start: string # RFC3339Nano (format: date-time)
  stop: string # RFC3339Nano (format: date-time)
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "bucketID" $bucketID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/delete" $qp)
  let body = {predicate: $predicate, start: $start, stop: $stop} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all templates
#
# GET /documents/templates
# operationId: GetDocumentsTemplates
export def "documents-templates GetDocumentsTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the name of the organization of the template.
  --orgID: string # Specifies the organization ID of the template.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<documents: table<id: string, labels: list, links: record, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents/templates" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /documents/templates
# operationId: PostDocumentsTemplates
# --meta shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
export def "documents-templates PostDocumentsTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  content: record
  --labels: list # An array of label IDs to be added as labels to the document.
  meta: record # shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
  --org: string # The organization Name. Specify either `orgID` or `org`.
  --orgID: string # The organization Name. Specify either `orgID` or `org`.
]: any -> record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/templates")
  let body = {content: $content, labels: $labels, meta: $meta, org: $org, orgID: $orgID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /documents/templates/{templateID}
# operationId: DeleteDocumentsTemplatesID
export def "documents-templates DeleteDocumentsTemplatesID" [
  templateID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/templates/($templateID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a template
#
# GET /documents/templates/{templateID}
# operationId: GetDocumentsTemplatesID
export def "documents-templates GetDocumentsTemplatesID" [
  templateID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/templates/($templateID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a template
#
# PUT /documents/templates/{templateID}
# operationId: PutDocumentsTemplatesID
# --meta shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
export def "documents-templates PutDocumentsTemplatesID" [
  templateID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content: record
  --meta: record # shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
]: any -> record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/templates/($templateID)")
  let body = {content: $content, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a template
#
# GET /documents/templates/{templateID}/labels
# operationId: GetDocumentsTemplatesIDLabels
export def "documents-templates-labels GetDocumentsTemplatesIDLabels" [
  templateID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/templates/($templateID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a template
#
# POST /documents/templates/{templateID}/labels
# operationId: PostDocumentsTemplatesIDLabels
export def "documents-templates-labels PostDocumentsTemplatesIDLabels" [
  templateID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/templates/($templateID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a template
#
# DELETE /documents/templates/{templateID}/labels/{labelID}
# operationId: DeleteDocumentsTemplatesIDLabelsID
export def "documents-templates-labels DeleteDocumentsTemplatesIDLabelsID" [
  templateID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/templates/($templateID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the feature flags for the currently authenticated user
#
# GET /flags
# operationId: GetFlags
export def "flags GetFlags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flags")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the health of an instance
#
# GET /health
# operationId: GetHealth
export def "health GetHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all labels
#
# GET /labels
# operationId: GetLabels
export def "labels GetLabels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # The organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a label
#
# POST /labels
# operationId: PostLabels
export def "labels PostLabels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  orgID: string
  --properties: record # Key/Value pairs associated with this label. Keys can be removed by sending an update with an empty value. (e.g. {color: ffb3b3, description: this is a description})
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/labels")
  let body = {name: $name, orgID: $orgID, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /labels/{labelID}
# operationId: DeleteLabelsID
export def "labels DeleteLabelsID" [
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a label
#
# GET /labels/{labelID}
# operationId: GetLabelsID
export def "labels GetLabelsID" [
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a label
#
# PATCH /labels/{labelID}
# operationId: PatchLabelsID
export def "labels PatchLabelsID" [
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --name: string
  --properties: record # Key/Value pairs associated with this label. Keys can be removed by sending an update with an empty value. (e.g. {color: ffb3b3, description: this is a description})
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($labelID)")
  let body = {name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the currently authenticated user
#
# GET /me
# operationId: GetMe
export def "me GetMe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a password
#
# PUT /me/password
# operationId: PutMePassword
export def "me-password PutMePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  password: string
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all notification endpoints
#
# GET /notificationEndpoints
# operationId: GetNotificationEndpoints
export def "notification-endpoints GetNotificationEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --orgID: string # Only show notification endpoints that belong to specific organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, notificationEndpoints: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notificationEndpoints" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a notification endpoint
#
# POST /notificationEndpoints
# operationId: CreateNotificationEndpoint
export def "notification-endpoints CreateNotificationEndpoint" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notificationEndpoints")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}
# operationId: DeleteNotificationEndpointsID
export def "notification-endpoints DeleteNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a notification endpoint
#
# GET /notificationEndpoints/{endpointID}
# operationId: GetNotificationEndpointsID
export def "notification-endpoints GetNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a notification endpoint
#
# PATCH /notificationEndpoints/{endpointID}
# operationId: PatchNotificationEndpointsID
export def "notification-endpoints PatchNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let body = {description: $description, name: $name, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a notification endpoint
#
# PUT /notificationEndpoints/{endpointID}
# operationId: PutNotificationEndpointsID
export def "notification-endpoints PutNotificationEndpointsID" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a notification endpoint
#
# GET /notificationEndpoints/{endpointID}/labels
# operationId: GetNotificationEndpointsIDLabels
export def "notification-endpoints-labels GetNotificationEndpointsIDLabels" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a notification endpoint
#
# POST /notificationEndpoints/{endpointID}/labels
# operationId: PostNotificationEndpointIDLabels
export def "notification-endpoints-labels PostNotificationEndpointIDLabels" [
  endpointID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}/labels/{labelID}
# operationId: DeleteNotificationEndpointsIDLabelsID
export def "notification-endpoints-labels DeleteNotificationEndpointsIDLabelsID" [
  endpointID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationEndpoints/($endpointID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all notification rules
#
# GET /notificationRules
# operationId: GetNotificationRules
export def "notification-rules GetNotificationRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --orgID: string # Only show notification rules that belong to a specific organization ID.
  --checkID: string # Only show notifications that belong to the specific check ID.
  --tag: string # Only return notification rules that "would match" statuses which contain the tag key value pairs provided. (e.g. env:prod)
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, notificationRules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "checkID" $checkID "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notificationRules" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a notification rule
#
# POST /notificationRules
# operationId: CreateNotificationRule
export def "notification-rules CreateNotificationRule" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notificationRules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a notification rule
#
# DELETE /notificationRules/{ruleID}
# operationId: DeleteNotificationRulesID
export def "notification-rules DeleteNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a notification rule
#
# GET /notificationRules/{ruleID}
# operationId: GetNotificationRulesID
export def "notification-rules GetNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a notification rule
#
# PATCH /notificationRules/{ruleID}
# operationId: PatchNotificationRulesID
export def "notification-rules PatchNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let body = {description: $description, name: $name, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a notification rule
#
# PUT /notificationRules/{ruleID}
# operationId: PutNotificationRulesID
export def "notification-rules PutNotificationRulesID" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a notification rule
#
# GET /notificationRules/{ruleID}/labels
# operationId: GetNotificationRulesIDLabels
export def "notification-rules-labels GetNotificationRulesIDLabels" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a notification rule
#
# POST /notificationRules/{ruleID}/labels
# operationId: PostNotificationRuleIDLabels
export def "notification-rules-labels PostNotificationRuleIDLabels" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete label from a notification rule
#
# DELETE /notificationRules/{ruleID}/labels/{labelID}
# operationId: DeleteNotificationRulesIDLabelsID
export def "notification-rules-labels DeleteNotificationRulesIDLabelsID" [
  ruleID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a notification rule query
#
# GET /notificationRules/{ruleID}/query
# operationId: GetNotificationRulesIDQuery
export def "notification-rules-query GetNotificationRulesIDQuery" [
  ruleID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<flux: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notificationRules/($ruleID)/query")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all organizations
#
# GET /orgs
# operationId: GetOrgs
export def "orgs GetOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --descending: oneof<nothing, bool> # default: false
  --org: string # Filter organizations to a specific organization name.
  --orgID: string # Filter organizations to a specific organization ID.
  --userID: string # Filter organizations to a specific user ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, orgs: table<createdAt: string, description: string, id: string, links: record, name: string, status: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "userID" $userID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /orgs
# operationId: PostOrgs
export def "orgs PostOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  name: string
]: any -> record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgs")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# DELETE /orgs/{orgID}
# operationId: DeleteOrgsID
export def "orgs DeleteOrgsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an organization
#
# GET /orgs/{orgID}
# operationId: GetOrgsID
export def "orgs GetOrgsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /orgs/{orgID}
# operationId: PatchOrgsID
export def "orgs PatchOrgsID" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # New description to set on the organization
  --name: string # New name to set on the organization
]: any -> record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all members of an organization
#
# GET /orgs/{orgID}/members
# operationId: GetOrgsIDMembers
export def "orgs-members GetOrgsIDMembers" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to an organization
#
# POST /orgs/{orgID}/members
# operationId: PostOrgsIDMembers
export def "orgs-members PostOrgsIDMembers" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from an organization
#
# DELETE /orgs/{orgID}/members/{userID}
# operationId: DeleteOrgsIDMembersID
export def "orgs-members DeleteOrgsIDMembersID" [
  userID: string
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of an organization
#
# GET /orgs/{orgID}/owners
# operationId: GetOrgsIDOwners
export def "orgs-owners GetOrgsIDOwners" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to an organization
#
# POST /orgs/{orgID}/owners
# operationId: PostOrgsIDOwners
export def "orgs-owners PostOrgsIDOwners" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from an organization
#
# DELETE /orgs/{orgID}/owners/{userID}
# operationId: DeleteOrgsIDOwnersID
export def "orgs-owners DeleteOrgsIDOwnersID" [
  userID: string
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all secret keys for an organization
#
# GET /orgs/{orgID}/secrets
# operationId: GetOrgsIDSecrets
export def "orgs-secrets GetOrgsIDSecrets" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<secrets: list<string>, links: record<org: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update secrets in an organization
#
# PATCH /orgs/{orgID}/secrets
# operationId: PatchOrgsIDSecrets
export def "orgs-secrets PatchOrgsIDSecrets" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete secrets from an organization
#
# POST /orgs/{orgID}/secrets/delete
# operationId: PostOrgsIDSecrets
export def "orgs-secrets-delete PostOrgsIDSecrets" [
  orgID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --secrets: list
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($orgID)/secrets/delete")
  let body = {secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query InfluxDB
#
# POST /query
# operationId: PostQuery
# --dialect shape: {annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
# --extern shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
export def "query PostQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --org: string # Specifies the name of the organization executing the query. Takes either the ID or Name interchangeably. If both `orgID` and `org` are specified, `org` takes precedence.
  --orgID: string # Specifies the ID of the organization executing the query. If both `orgID` and `org` are specified, `org` takes precedence.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --Accept-Encoding: string@Accept-Encoding-completer # The Accept-Encoding request HTTP header advertises which content encoding, usually a compression algorithm, the client is able to understand.
  --Content-Type: string@Content-Type-completer
  --dialect: record # Dialect are options to change the default CSV output format; https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions — shape: {annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
  --extern: record # Represents a source from a single file — shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
  --now: string # Specifies the time that should be reported as "now" in the query. Default is the server's now time. (format: date-time)
  --params: record # Enumeration of key/value pairs that respresent parameters to be injected into query (can only specify either this field or extern and not both)
  --body-query: string # Query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
  --bucket: string # Bucket is to be used instead of the database and retention policy specified in the InfluxQL query.
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query" $qp)
  let body = {dialect: $dialect, extern: $extern, now: $now, params: $params, query: $body_query, type: $type, bucket: $bucket} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Accept-Encoding": $Accept_Encoding, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/vnd.influx.arrow")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Analyze an InfluxQL or Flux query
#
# POST /query/analyze
# operationId: PostQueryAnalyze
# --dialect shape: {annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
# --extern shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
export def "query-analyze PostQueryAnalyze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --Content-Type: string@Content-Type-completer-1
  --dialect: record # Dialect are options to change the default CSV output format; https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions — shape: {annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
  --extern: record # Represents a source from a single file — shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
  --now: string # Specifies the time that should be reported as "now" in the query. Default is the server's now time. (format: date-time)
  --params: record # Enumeration of key/value pairs that respresent parameters to be injected into query (can only specify either this field or extern and not both)
  --body-query: string # Query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
]: any -> record<errors: table<character: int, column: int, line: int, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/analyze")
  let body = {dialect: $dialect, extern: $extern, now: $now, params: $params, query: $body_query, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate an Abstract Syntax Tree (AST) from a query
#
# POST /query/ast
# operationId: PostQueryAst
export def "query-ast PostQueryAst" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --Content-Type: string@Content-Type-completer-1
  --body-query: string # Flux query script to be analyzed
]: any -> record<ast: record<files: list<record>, package: string, path: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/ast")
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve query suggestions
#
# GET /query/suggestions
# operationId: GetQuerySuggestions
export def "query-suggestions GetQuerySuggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<funcs: table<name: string, params: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/suggestions")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve query suggestions for a branching suggestion
#
# GET /query/suggestions/{name}
# operationId: GetQuerySuggestionsName
export def "query-suggestions GetQuerySuggestionsName" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<name: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/query/suggestions/($name)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the readiness of an instance at startup
#
# GET /ready
# operationId: GetReady
export def "ready GetReady" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<started: string, status: string, up: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ready")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all scraper targets
#
# GET /scrapers
# operationId: GetScrapers
export def "scrapers GetScrapers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Specifies the name of the scraper target.
  --id: list # List of scraper target IDs to return. If both `id` and `owner` are specified, only `id` is used.
  --orgID: string # Specifies the organization ID of the scraper target.
  --org: string # Specifies the organization name of the scraper target.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<configurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scrapers" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a scraper target
#
# POST /scrapers
# operationId: PostScrapers
export def "scrapers PostScrapers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --allowInsecure: oneof<nothing, bool> # Skip TLS verification on endpoint. (default: false)
  --bucketID: string # The ID of the bucket to write to.
  --name: string # The name of the scraper target.
  --orgID: string # The organization ID.
  --type: string@type-completer-1 # The type of the metrics to be parsed.
  --body-url: string # The URL of the metrics endpoint. (e.g. http://localhost:9090/metrics)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scrapers")
  let body = {allowInsecure: $allowInsecure, bucketID: $bucketID, name: $name, orgID: $orgID, type: $type, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a scraper target
#
# DELETE /scrapers/{scraperTargetID}
# operationId: DeleteScrapersID
export def "scrapers DeleteScrapersID" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a scraper target
#
# GET /scrapers/{scraperTargetID}
# operationId: GetScrapersID
export def "scrapers GetScrapersID" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a scraper target
#
# PATCH /scrapers/{scraperTargetID}
# operationId: PatchScrapersID
export def "scrapers PatchScrapersID" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --allowInsecure: oneof<nothing, bool> # Skip TLS verification on endpoint. (default: false)
  --bucketID: string # The ID of the bucket to write to.
  --name: string # The name of the scraper target.
  --orgID: string # The organization ID.
  --type: string@type-completer-1 # The type of the metrics to be parsed.
  --body-url: string # The URL of the metrics endpoint. (e.g. http://localhost:9090/metrics)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)")
  let body = {allowInsecure: $allowInsecure, bucketID: $bucketID, name: $name, orgID: $orgID, type: $type, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a scraper target
#
# GET /scrapers/{scraperTargetID}/labels
# operationId: GetScrapersIDLabels
export def "scrapers-labels GetScrapersIDLabels" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a scraper target
#
# POST /scrapers/{scraperTargetID}/labels
# operationId: PostScrapersIDLabels
export def "scrapers-labels PostScrapersIDLabels" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/labels/{labelID}
# operationId: DeleteScrapersIDLabelsID
export def "scrapers-labels DeleteScrapersIDLabelsID" [
  scraperTargetID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users with member privileges for a scraper target
#
# GET /scrapers/{scraperTargetID}/members
# operationId: GetScrapersIDMembers
export def "scrapers-members GetScrapersIDMembers" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a scraper target
#
# POST /scrapers/{scraperTargetID}/members
# operationId: PostScrapersIDMembers
export def "scrapers-members PostScrapersIDMembers" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/members/{userID}
# operationId: DeleteScrapersIDMembersID
export def "scrapers-members DeleteScrapersIDMembersID" [
  userID: string
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a scraper target
#
# GET /scrapers/{scraperTargetID}/owners
# operationId: GetScrapersIDOwners
export def "scrapers-owners GetScrapersIDOwners" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a scraper target
#
# POST /scrapers/{scraperTargetID}/owners
# operationId: PostScrapersIDOwners
export def "scrapers-owners PostScrapersIDOwners" [
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/owners/{userID}
# operationId: DeleteScrapersIDOwnersID
export def "scrapers-owners DeleteScrapersIDOwnersID" [
  userID: string
  scraperTargetID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scrapers/($scraperTargetID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if database has default user, org, bucket
#
# GET /setup
# operationId: GetSetup
export def "setup GetSetup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<allowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set up initial user, org and bucket
#
# POST /setup
# operationId: PostSetup
@deprecated --flag retentionPeriodHrs
export def "setup PostSetup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  bucket: string
  org: string
  --password: string
  --retentionPeriodHrs: int # Retention period *in nanoseconds* for the new bucket. This key's name has been misleading since OSS 2.0 GA, please transition to use `retentionPeriodSeconds`  (DEPRECATED)
  --retentionPeriodSeconds: int # format: int64
  --body-token: string # Authentication token to set on the initial user. If not specified, the server will generate a token.
  username: string
]: any -> record<auth: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: list<record>, token: string, updatedAt: string, user: string, userID: string>, bucket: record<createdAt: string, description: string, id: string, labels: list<record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: list<record>, rp: string, schemaType: string, type: string, updatedAt: string>, org: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>, user: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup")
  let body = {bucket: $bucket, org: $org, password: $password, retentionPeriodHrs: $retentionPeriodHrs, retentionPeriodSeconds: $retentionPeriodSeconds, token: $body_token, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exchange basic auth credentials for session
#
# POST /signin
# operationId: PostSignin
export def "signin PostSignin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signin")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Expire the current session
#
# POST /signout
# operationId: PostSignout
export def "signout PostSignout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signout")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all sources
#
# GET /sources
# operationId: GetSources
export def "sources GetSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, sources: table<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list, links: record, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sources" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a source
#
# POST /sources
# operationId: PostSources
# --links shape: {buckets?: string, health?: string, query?: string, self?: string}
export def "sources PostSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --default: oneof<nothing, bool>
  --defaultRP: string
  --id: string
  --insecureSkipVerify: oneof<nothing, bool>
  --links: record # shape: {buckets?: string, health?: string, query?: string, self?: string}
  --metaUrl: string # format: uri
  --name: string
  --orgID: string
  --password: string
  --sharedSecret: string
  --telegraf: string
  --body-token: string
  --type: string@type-completer-2
  --body-url: string # format: uri
  --username: string
]: any -> record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sources")
  let body = {default: $default, defaultRP: $defaultRP, id: $id, insecureSkipVerify: $insecureSkipVerify, links: $links, metaUrl: $metaUrl, name: $name, orgID: $orgID, password: $password, sharedSecret: $sharedSecret, telegraf: $telegraf, token: $body_token, type: $type, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a source
#
# DELETE /sources/{sourceID}
# operationId: DeleteSourcesID
export def "sources DeleteSourcesID" [
  sourceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sources/($sourceID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a source
#
# GET /sources/{sourceID}
# operationId: GetSourcesID
export def "sources GetSourcesID" [
  sourceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sources/($sourceID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Source
#
# PATCH /sources/{sourceID}
# operationId: PatchSourcesID
# --links shape: {buckets?: string, health?: string, query?: string, self?: string}
export def "sources PatchSourcesID" [
  sourceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --default: oneof<nothing, bool>
  --defaultRP: string
  --id: string
  --insecureSkipVerify: oneof<nothing, bool>
  --links: record # shape: {buckets?: string, health?: string, query?: string, self?: string}
  --metaUrl: string # format: uri
  --name: string
  --orgID: string
  --password: string
  --sharedSecret: string
  --telegraf: string
  --body-token: string
  --type: string@type-completer-2
  --body-url: string # format: uri
  --username: string
]: any -> record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sources/($sourceID)")
  let body = {default: $default, defaultRP: $defaultRP, id: $id, insecureSkipVerify: $insecureSkipVerify, links: $links, metaUrl: $metaUrl, name: $name, orgID: $orgID, password: $password, sharedSecret: $sharedSecret, telegraf: $telegraf, token: $body_token, type: $type, url: $body_url, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get buckets in a source
#
# GET /sources/{sourceID}/buckets
# operationId: GetSourcesIDBuckets
export def "sources-buckets GetSourcesIDBuckets" [
  sourceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sources/($sourceID)/buckets" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the health of a source
#
# GET /sources/{sourceID}/health
# operationId: GetSourcesIDHealth
export def "sources-health GetSourcesIDHealth" [
  sourceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sources/($sourceID)/health")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all installed InfluxDB templates
#
# GET /stacks
# operationId: ListStacks
export def "stacks ListStacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # The organization id of the stacks
  --name: string # A collection of names to filter the list by.
  --stackID: string # A collection of stackIDs to filter the list by.
]: nothing -> record<stacks: table<createdAt: string, events: list, id: string, orgID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "stackID" $stackID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new stack
#
# POST /stacks
# operationId: CreateStack
export def "stacks CreateStack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --name: string
  --orgID: string
  --urls: list
]: any -> record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stacks")
  let body = {description: $description, name: $name, orgID: $orgID, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a stack and associated resources
#
# DELETE /stacks/{stack_id}
# operationId: DeleteStack
export def "stacks DeleteStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # The identifier of the organization.
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stacks/($stack_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a stack
#
# GET /stacks/{stack_id}
# operationId: ReadStack
export def "stacks ReadStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($stack_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an InfluxDB Stack
#
# PATCH /stacks/{stack_id}
# operationId: UpdateStack
# --additionalResources item shape: {kind: string, resourceID: string, templateMetaName?: string}
export def "stacks UpdateStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalResources: list # item shape: {kind: string, resourceID: string, templateMetaName?: string}
  --description: string # nullable
  --name: string # nullable
  --templateURLs: list # nullable
]: any -> record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($stack_id)")
  let body = {additionalResources: $additionalResources, description: $description, name: $name, templateURLs: $templateURLs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uninstall an InfluxDB Stack
#
# POST /stacks/{stack_id}/uninstall
# operationId: UninstallStack
export def "stacks-uninstall UninstallStack" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stacks/($stack_id)/uninstall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all tasks
#
# GET /tasks
# operationId: GetTasks
export def "tasks GetTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Returns task with a specific name.
  --after: string # Return tasks after a specified ID.
  --user: string # Filter tasks to a specific user ID.
  --org: string # Filter tasks to a specific organization name.
  --orgID: string # Filter tasks to a specific organization ID.
  --status: string@status-completer # Filter tasks by a status--"inactive" or "active".
  --limit: int # The number of tasks to return (default: 100)
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, tasks: table<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: list, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new task
#
# POST /tasks
# operationId: PostTasks
export def "tasks PostTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # An optional description of the task.
  flux: string # The Flux script to run for this task.
  --org: string # The name of the organization that owns this Task.
  --orgID: string # The ID of the organization that owns this Task.
  --status: string@status-completer
]: any -> record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {description: $description, flux: $flux, org: $org, orgID: $orgID, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /tasks/{taskID}
# operationId: DeleteTasksID
export def "tasks DeleteTasksID" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a task
#
# GET /tasks/{taskID}
# operationId: GetTasksID
export def "tasks GetTasksID" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a task
#
# PATCH /tasks/{taskID}
# operationId: PatchTasksID
export def "tasks PatchTasksID" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --cron: string # Override the 'cron' option in the flux script.
  --description: string # An optional description of the task.
  --every: string # Override the 'every' option in the flux script.
  --flux: string # The Flux script to run for this task.
  --name: string # Override the 'name' option in the flux script.
  --offset: string # Override the 'offset' option in the flux script.
  --status: string@status-completer
]: any -> record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)")
  let body = {cron: $cron, description: $description, every: $every, flux: $flux, name: $name, offset: $offset, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a task
#
# GET /tasks/{taskID}/labels
# operationId: GetTasksIDLabels
export def "tasks-labels GetTasksIDLabels" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a task
#
# POST /tasks/{taskID}/labels
# operationId: PostTasksIDLabels
export def "tasks-labels PostTasksIDLabels" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a task
#
# DELETE /tasks/{taskID}/labels/{labelID}
# operationId: DeleteTasksIDLabelsID
export def "tasks-labels DeleteTasksIDLabelsID" [
  taskID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all logs for a task
#
# GET /tasks/{taskID}/logs
# operationId: GetTasksIDLogs
export def "tasks-logs GetTasksIDLogs" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<events: table<message: string, runID: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/logs")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all task members
#
# GET /tasks/{taskID}/members
# operationId: GetTasksIDMembers
export def "tasks-members GetTasksIDMembers" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a task
#
# POST /tasks/{taskID}/members
# operationId: PostTasksIDMembers
export def "tasks-members PostTasksIDMembers" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a task
#
# DELETE /tasks/{taskID}/members/{userID}
# operationId: DeleteTasksIDMembersID
export def "tasks-members DeleteTasksIDMembersID" [
  userID: string
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a task
#
# GET /tasks/{taskID}/owners
# operationId: GetTasksIDOwners
export def "tasks-owners GetTasksIDOwners" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a task
#
# POST /tasks/{taskID}/owners
# operationId: PostTasksIDOwners
export def "tasks-owners PostTasksIDOwners" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a task
#
# DELETE /tasks/{taskID}/owners/{userID}
# operationId: DeleteTasksIDOwnersID
export def "tasks-owners DeleteTasksIDOwnersID" [
  userID: string
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List runs for a task
#
# GET /tasks/{taskID}/runs
# operationId: GetTasksIDRuns
export def "tasks-runs GetTasksIDRuns" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Returns runs after a specific ID.
  --limit: int # The number of runs to return (default: 100)
  --afterTime: string # Filter runs to those scheduled after this time, RFC3339 (format: date-time)
  --beforeTime: string # Filter runs to those scheduled before this time, RFC3339 (format: date-time)
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, runs: table<finishedAt: string, id: string, links: record, log: list, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "afterTime" $afterTime "scalar") (serialize-qp "beforeTime" $beforeTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskID)/runs" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manually start a task run, overriding the current schedule
#
# POST /tasks/{taskID}/runs
# operationId: PostTasksIDRuns
export def "tasks-runs PostTasksIDRuns" [
  taskID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --scheduledFor: string # Time used for run's "now" option, RFC3339.  Default is the server's now time. (nullable, format: date-time)
]: any -> record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs")
  let body = {scheduledFor: $scheduledFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a running task
#
# DELETE /tasks/{taskID}/runs/{runID}
# operationId: DeleteTasksIDRunsID
export def "tasks-runs DeleteTasksIDRunsID" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single run for a task
#
# GET /tasks/{taskID}/runs/{runID}
# operationId: GetTasksIDRunsID
export def "tasks-runs GetTasksIDRunsID" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all logs for a run
#
# GET /tasks/{taskID}/runs/{runID}/logs
# operationId: GetTasksIDRunsIDLogs
export def "tasks-runs-logs GetTasksIDRunsIDLogs" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<events: table<message: string, runID: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)/logs")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry a task run
#
# POST /tasks/{taskID}/runs/{runID}/retry
# operationId: PostTasksIDRunsIDRetry
export def "tasks-runs-retry PostTasksIDRunsIDRetry" [
  taskID: string
  runID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskID)/runs/($runID)/retry")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List all Telegraf plugins
#
# GET /telegraf/plugins
# operationId: GetTelegrafPlugins
export def "telegraf-plugins GetTelegrafPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type of plugin desired.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<os: string, plugins: table<config: string, description: string, name: string, type: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telegraf/plugins" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Telegraf configurations
#
# GET /telegrafs
# operationId: GetTelegrafs
export def "telegrafs GetTelegrafs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgID: string # The organization ID the Telegraf config belongs to.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<configurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telegrafs" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Telegraf configuration
#
# POST /telegrafs
# operationId: PostTelegrafs
# --metadata shape: {buckets?: list}
export def "telegrafs PostTelegrafs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --config: string
  --description: string
  --metadata: record # shape: {buckets?: list}
  --name: string
  --orgID: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/telegrafs")
  let body = {config: $config, description: $description, metadata: $metadata, name: $name, orgID: $orgID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Telegraf configuration
#
# DELETE /telegrafs/{telegrafID}
# operationId: DeleteTelegrafsID
export def "telegrafs DeleteTelegrafsID" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Telegraf configuration
#
# GET /telegrafs/{telegrafID}
# operationId: GetTelegrafsID
export def "telegrafs GetTelegrafsID" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --Accept: string@Accept-completer
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Telegraf configuration
#
# PUT /telegrafs/{telegrafID}
# operationId: PutTelegrafsID
# --metadata shape: {buckets?: list}
export def "telegrafs PutTelegrafsID" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --config: string
  --description: string
  --metadata: record # shape: {buckets?: list}
  --name: string
  --orgID: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)")
  let body = {config: $config, description: $description, metadata: $metadata, name: $name, orgID: $orgID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a Telegraf config
#
# GET /telegrafs/{telegrafID}/labels
# operationId: GetTelegrafsIDLabels
export def "telegrafs-labels GetTelegrafsIDLabels" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a Telegraf config
#
# POST /telegrafs/{telegrafID}/labels
# operationId: PostTelegrafsIDLabels
export def "telegrafs-labels PostTelegrafsIDLabels" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/labels/{labelID}
# operationId: DeleteTelegrafsIDLabelsID
export def "telegrafs-labels DeleteTelegrafsIDLabelsID" [
  telegrafID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users with member privileges for a Telegraf config
#
# GET /telegrafs/{telegrafID}/members
# operationId: GetTelegrafsIDMembers
export def "telegrafs-members GetTelegrafsIDMembers" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/members")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a Telegraf config
#
# POST /telegrafs/{telegrafID}/members
# operationId: PostTelegrafsIDMembers
export def "telegrafs-members PostTelegrafsIDMembers" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/members")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/members/{userID}
# operationId: DeleteTelegrafsIDMembersID
export def "telegrafs-members DeleteTelegrafsIDMembersID" [
  userID: string
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/members/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a Telegraf configuration
#
# GET /telegrafs/{telegrafID}/owners
# operationId: GetTelegrafsIDOwners
export def "telegrafs-owners GetTelegrafsIDOwners" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/owners")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a Telegraf configuration
#
# POST /telegrafs/{telegrafID}/owners
# operationId: PostTelegrafsIDOwners
export def "telegrafs-owners PostTelegrafsIDOwners" [
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/owners")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/owners/{userID}
# operationId: DeleteTelegrafsIDOwnersID
export def "telegrafs-owners DeleteTelegrafsIDOwnersID" [
  userID: string
  telegrafID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/telegrafs/($telegrafID)/owners/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply or dry-run an InfluxDB Template
#
# POST /templates/apply
# operationId: ApplyTemplate
# --remotes item shape: {contentType?: string, url: string}
# --template shape: {contentType?: string, contents?: list, sources?: list}
# --templates item shape: {contentType?: string, contents?: list, sources?: list}
export def "templates-apply ApplyTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list
  --dryRun: oneof<nothing, bool>
  --envRefs: record
  --orgID: string
  --remotes: list # item shape: {contentType?: string, url: string}
  --secrets: record
  --stackID: string
  --template: record # shape: {contentType?: string, contents?: list, sources?: list}
  --templates: list # item shape: {contentType?: string, contents?: list, sources?: list}
]: any -> record<diff: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>, errors: table<fields: list, indexes: list, kind: string, reason: string>, sources: list<string>, stackID: string, summary: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, missingEnvRefs: list<string>, missingSecrets: list<string>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/apply")
  let body = {actions: $actions, dryRun: $dryRun, envRefs: $envRefs, orgID: $orgID, remotes: $remotes, secrets: $secrets, stackID: $stackID, template: $template, templates: $templates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export a new Influx Template
#
# POST /templates/export
# operationId: ExportTemplate
# --orgIDs item shape: {orgID?: string, resourceFilters?: record}
# --resources shape: {id: string, kind: "Bucket"|"Check"|"CheckDeadman"|"CheckThreshold"|"Dashboard"|"Label"|"NotificationEndpoint"|"NotificationEndpointHTTP"|"NotificationEndpointPagerDuty"|"NotificationEndpointSlack"|"NotificationRule"|"Task"|"Telegraf"|"Variable", name?: string}
export def "templates-export ExportTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --orgIDs: list # item shape: {orgID?: string, resourceFilters?: record}
  --resources: record # shape: {id: string, kind: "Bucket"|"Check"|"CheckDeadman"|"CheckThreshold"|"Dashboard"|"Label"|"NotificationEndpoint"|"NotificationEndpointHTTP"|"NotificationEndpointPagerDuty"|"NotificationEndpointSlack"|"NotificationRule"|"Task"|"Telegraf"|"Variable", name?: string}
  --stackID: string
]: any -> table<apiVersion: string, kind: string, meta: record<name: string>, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/export")
  let body = {orgIDs: $orgIDs, resources: $resources, stackID: $stackID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all users
#
# GET /users
# operationId: GetUsers
export def "users GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --limit: int # default: 20
  --after: string # The last resource ID from which to seek from (but not including). This is to be used instead of `offset`.
  --name: string
  --id: string
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: PostUsers
export def "users PostUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  --oauthID: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {name: $name, oauthID: $oauthID, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/{userID}
# operationId: DeleteUsersID
export def "users DeleteUsersID" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a user
#
# GET /users/{userID}
# operationId: GetUsersID
export def "users GetUsersID" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{userID}
# operationId: PatchUsersID
export def "users PatchUsersID" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  --oauthID: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)")
  let body = {name: $name, oauthID: $oauthID, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a password
#
# POST /users/{userID}/password
# operationId: PostUsersIDPassword
export def "users-password PostUsersIDPassword" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  password: string
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userID)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all variables
#
# GET /variables
# operationId: GetVariables
export def "variables GetVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --orgID: string # The organization ID.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<variables: table<arguments: record, createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, selected: list, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variables" $qp)
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a variable
#
# POST /variables
# operationId: PostVariables
# --arguments shape: {type?: "query", values?: record}
# --labels item shape: {name?: string, properties?: record}
# --links shape: {labels?: string, org?: string, self?: string}
export def "variables PostVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --createdAt: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  orgID: string
  --selected: list
  --updatedAt: string # format: date-time
]: any -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/variables")
  let body = {arguments: $arguments, createdAt: $createdAt, description: $description, labels: $labels, name: $name, orgID: $orgID, selected: $selected, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a variable
#
# DELETE /variables/{variableID}
# operationId: DeleteVariablesID
export def "variables DeleteVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a variable
#
# GET /variables/{variableID}
# operationId: GetVariablesID
export def "variables GetVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a variable
#
# PATCH /variables/{variableID}
# operationId: PatchVariablesID
# --arguments shape: {type?: "query", values?: record}
# --labels item shape: {name?: string, properties?: record}
# --links shape: {labels?: string, org?: string, self?: string}
export def "variables PatchVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --createdAt: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  orgID: string
  --selected: list
  --updatedAt: string # format: date-time
]: any -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let body = {arguments: $arguments, createdAt: $createdAt, description: $description, labels: $labels, name: $name, orgID: $orgID, selected: $selected, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace a variable
#
# PUT /variables/{variableID}
# operationId: PutVariablesID
# --arguments shape: {type?: "query", values?: record}
# --labels item shape: {name?: string, properties?: record}
# --links shape: {labels?: string, org?: string, self?: string}
export def "variables PutVariablesID" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --createdAt: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  orgID: string
  --selected: list
  --updatedAt: string # format: date-time
]: any -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)")
  let body = {arguments: $arguments, createdAt: $createdAt, description: $description, labels: $labels, name: $name, orgID: $orgID, selected: $selected, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a variable
#
# GET /variables/{variableID}/labels
# operationId: GetVariablesIDLabels
export def "variables-labels GetVariablesIDLabels" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)/labels")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a variable
#
# POST /variables/{variableID}/labels
# operationId: PostVariablesIDLabels
export def "variables-labels PostVariablesIDLabels" [
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --labelID: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)/labels")
  let body = {labelID: $labelID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a variable
#
# DELETE /variables/{variableID}/labels/{labelID}
# operationId: DeleteVariablesIDLabelsID
export def "variables-labels DeleteVariablesIDLabelsID" [
  variableID: string
  labelID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($variableID)/labels/($labelID)")
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write time series data into InfluxDB
#
# POST /write
# operationId: PostWrite
export def "write PostWrite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the destination organization for writes. Takes either the ID or Name interchangeably. If both `orgID` and `org` are specified, `org` takes precedence.
  --orgID: string # Specifies the ID of the destination organization for writes. If both `orgID` and `org` are specified, `org` takes precedence.
  --bucket: string # The destination bucket for writes.
  --precision: string@precision-completer # The precision for the unix timestamps within the body line-protocol.
  --Zap-Trace-Span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --Content-Encoding: string@Content-Encoding-completer # When present, its value indicates to the database that compression is applied to the line-protocol body.
  --Content-Type: string@Content-Type-completer-2 # Content-Type is used to indicate the format of the data sent to the server.
  --Content-Length: int # Content-Length is an entity header is indicating the size of the entity-body, in bytes, sent to the database. If the length is greater than the database max body configuration option, a 413 response is sent.
  --Accept: string@Accept-completer-1 # Specifies the return content format.
  --body: record
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $orgID "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/write" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $Zap_Trace_Span, "Content-Encoding": $Content_Encoding, "Content-Type": $Content_Type, "Content-Length": $Content_Length, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}
