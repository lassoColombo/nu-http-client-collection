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
def schema-type-completer [] { ["explicit" "implicit"] }
def sort-by-completer [] { ["CreatedAt" "ID" "UpdatedAt"] }
def include-completer [] { ["properties"] }
def type-completer [] { ["flux"] }
def accept-encoding-completer [] { ["gzip" "identity"] }
def content-type-completer [] { ["application/json" "application/vnd.flux"] }
def accept-completer [] { ["application/json" "application/vnd.influx.arrow" "text/csv"] }
def content-type-completer-1 [] { ["application/json"] }
def type-completer-1 [] { ["prometheus"] }
def type-completer-2 [] { ["self" "v1" "v2"] }
def accept-completer-1 [] { ["application/json" "application/octet-stream" "application/toml"] }
def accept-completer-2 [] { ["application/json" "application/x-yaml"] }
def precision-completer [] { ["ms" "ns" "s" "us"] }
def content-encoding-completer [] { ["gzip" "identity"] }
def content-type-completer-2 [] { ["application/vnd.influx.arrow" "text/plain" "text/plain; charset=utf-8"] }
def accept-completer-3 [] { ["application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "routes get" } } | get name | first)
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
export def "routes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<authorizations: string, buckets: string, dashboards: string, external: record<statusFeed: string>, flags: string, me: string, orgs: string, query: record<analyze: string, ast: string, self: string, suggestions: string>, setup: string, signin: string, signout: string, sources: string, system: record<debug: string, health: string, metrics: string>, tasks: string, telegrafs: string, users: string, variables: string, write: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all authorizations
#
# GET /authorizations
# operationId: GetAuthorizations
export def "authorizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # Only show authorizations that belong to a user ID.
  --user: string # Only show authorizations that belong to a user name.
  --org-id: string # Only show authorizations that belong to an organization ID.
  --org: string # Only show authorizations that belong to a organization name.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<authorizations: table<description: string, status: string, createdAt: string, id: string, links: record, org: string, orgID: string, permissions: list, token: string, updatedAt: string, user: string, userID: string>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userID" $user_id "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorizations" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "authorizations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # A description of the token.
  --status: string@status-completer # If inactive the token is inactive and requests using the token will be rejected. (default: active)
  org_id: string # ID of org that authorization is scoped to.
  permissions: list # List of permissions for an auth.  An auth must have at least one Permission. — item shape: {action: "read"|"write", resource: record}
  --user-id: string # ID of user that authorization is scoped to.
]: any -> record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorizations")
  let body = {"description": $description, "status": $status, "orgID": $org_id, "permissions": $permissions, "userID": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an authorization
#
# DELETE /authorizations/{authID}
# operationId: DeleteAuthorizationsID
export def "authorizations delete" [
  auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({auth_id: $auth_id} | format pattern "/authorizations/{auth_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an authorization
#
# GET /authorizations/{authID}
# operationId: GetAuthorizationsID
export def "authorizations get" [
  auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({auth_id: $auth_id} | format pattern "/authorizations/{auth_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an authorization to be active or inactive
#
# PATCH /authorizations/{authID}
# operationId: PatchAuthorizationsID
export def "authorizations update" [
  auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # A description of the token.
  --status: string@status-completer # If inactive the token is inactive and requests using the token will be rejected. (default: active)
]: any -> record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: table<action: string, resource: record>, token: string, updatedAt: string, user: string, userID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({auth_id: $auth_id} | format pattern "/authorizations/{auth_id}"))
  let body = {"description": $description, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all buckets
#
# GET /buckets
# operationId: GetBuckets
export def "buckets list" [
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
  --org-id: string # The organization ID.
  --name: string # Only returns buckets with a specific name.
  --id: string # Only returns buckets with a specific ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buckets" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "buckets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  name: string
  org_id: string
  retention_rules: list # Rules to expire or retain data.  No rules means data never expires. — item shape: {everySeconds: int, shardGroupDurationSeconds?: int, type: "expire"}
  --rp: string
  --schema-type: string@schema-type-completer
]: any -> record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buckets")
  let body = {"description": $description, "name": $name, "orgID": $org_id, "retentionRules": $retention_rules, "rp": $rp, "schemaType": $schema_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a bucket
#
# DELETE /buckets/{bucketID}
# operationId: DeleteBucketsID
export def "buckets delete" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a bucket
#
# GET /buckets/{bucketID}
# operationId: GetBucketsID
export def "buckets get" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "buckets update" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --retention-rules: list # Updates to rules to expire or retain data. No rules means no updates. — item shape: {everySeconds?: int, shardGroupDurationSeconds?: int, type: "expire"}
]: any -> record<createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: table<everySeconds: int, shardGroupDurationSeconds: int, type: string>, rp: string, schemaType: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}"))
  let body = {"description": $description, "name": $name, "retentionRules": $retention_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a bucket
#
# GET /buckets/{bucketID}/labels
# operationId: GetBucketsIDLabels
export def "buckets-labels get" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a bucket
#
# POST /buckets/{bucketID}/labels
# operationId: PostBucketsIDLabels
export def "buckets-labels create" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a bucket
#
# DELETE /buckets/{bucketID}/labels/{labelID}
# operationId: DeleteBucketsIDLabelsID
export def "buckets-labels delete" [
  bucket_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id, label_id: $label_id} | format pattern "/buckets/{bucket_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users with member privileges for a bucket
#
# GET /buckets/{bucketID}/members
# operationId: GetBucketsIDMembers
export def "buckets-members get" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}/members"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a bucket
#
# POST /buckets/{bucketID}/members
# operationId: PostBucketsIDMembers
export def "buckets-members create" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}/members"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a bucket
#
# DELETE /buckets/{bucketID}/members/{userID}
# operationId: DeleteBucketsIDMembersID
export def "buckets-members delete" [
  bucket_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id, user_id: $user_id} | format pattern "/buckets/{bucket_id}/members/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a bucket
#
# GET /buckets/{bucketID}/owners
# operationId: GetBucketsIDOwners
export def "buckets-owners get" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}/owners"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a bucket
#
# POST /buckets/{bucketID}/owners
# operationId: PostBucketsIDOwners
export def "buckets-owners create" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id} | format pattern "/buckets/{bucket_id}/owners"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a bucket
#
# DELETE /buckets/{bucketID}/owners/{userID}
# operationId: DeleteBucketsIDOwnersID
export def "buckets-owners delete" [
  bucket_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bucket_id: $bucket_id, user_id: $user_id} | format pattern "/buckets/{bucket_id}/owners/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all checks
#
# GET /checks
# operationId: GetChecks
export def "checks list" [
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
  --org-id: string # Only show checks that belong to a specific organization ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<checks: list<record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checks" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new check
#
# POST /checks
# operationId: CreateCheck
export def "checks create" [
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
export def "checks delete" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a check
#
# GET /checks/{checkID}
# operationId: GetChecksID
export def "checks get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a check
#
# PATCH /checks/{checkID}
# operationId: PatchChecksID
export def "checks update-by-checkID" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}"))
  let body = {"description": $description, "name": $name, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a check
#
# PUT /checks/{checkID}
# operationId: PutChecksID
export def "checks update-by-checkID-1" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a check
#
# GET /checks/{checkID}/labels
# operationId: GetChecksIDLabels
export def "checks-labels get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a check
#
# POST /checks/{checkID}/labels
# operationId: PostChecksIDLabels
export def "checks-labels create" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete label from a check
#
# DELETE /checks/{checkID}/labels/{labelID}
# operationId: DeleteChecksIDLabelsID
export def "checks-labels delete" [
  check_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id, label_id: $label_id} | format pattern "/checks/{check_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a check query
#
# GET /checks/{checkID}/query
# operationId: GetChecksIDQuery
export def "checks-query get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<flux: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({check_id: $check_id} | format pattern "/checks/{check_id}/query"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all dashboards
#
# GET /dashboards
# operationId: GetDashboards
export def "dashboards list" [
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
  --sort-by: string@sort-by-completer # The column to sort by.
  --id: list # A list of dashboard identifiers. Returns only the listed dashboards. If both `id` and `owner` are specified, only `id` is used.
  --org-id: string # The identifier of the organization.
  --org: string # The name of the organization.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<dashboards: list<record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboards" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a dashboard
#
# POST /dashboards
# operationId: PostDashboards
export def "dashboards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # The user-facing description of the dashboard.
  name: string # The user-facing name of the dashboard.
  org_id: string # The ID of the organization that owns the dashboard.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards")
  let body = {"description": $description, "name": $name, "orgID": $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a dashboard
#
# DELETE /dashboards/{dashboardID}
# operationId: DeleteDashboardsID
export def "dashboards delete" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Dashboard
#
# GET /dashboards/{dashboardID}
# operationId: GetDashboardsID
export def "dashboards get" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Includes the cell view properties in the response if set to `properties`
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}") $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "dashboards update" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --cells: record # shape: {h?: int, id?: string, links?: record, viewID?: string, w?: int, x?: int, y?: int, name?: string, properties?: any}
  --description: string # optional, when provided will replace the description
  --name: string # optional, when provided will replace the name
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}"))
  let body = {"cells": $cells, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a dashboard cell
#
# POST /dashboards/{dashboardID}/cells
# operationId: PostDashboardsIDCells
export def "dashboards-cells create" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --h: int # format: int32
  --name: string
  --using-view: string # Makes a copy of the provided view.
  --w: int # format: int32
  --x: int # format: int32
  --y: int # format: int32
]: any -> record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/cells"))
  let body = {"h": $h, "name": $name, "usingView": $using_view, "w": $w, "x": $x, "y": $y} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace cells in a dashboard
#
# PUT /dashboards/{dashboardID}/cells
# operationId: PutDashboardsIDCells
export def "dashboards-cells update-by-dashboardID" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/cells"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a dashboard cell
#
# DELETE /dashboards/{dashboardID}/cells/{cellID}
# operationId: DeleteDashboardsIDCellsID
export def "dashboards-cells delete" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, cell_id: $cell_id} | format pattern "/dashboards/{dashboard_id}/cells/{cell_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the non-positional information related to a cell
#
# PATCH /dashboards/{dashboardID}/cells/{cellID}
# operationId: PatchDashboardsIDCellsID
export def "dashboards-cells update-by-dashboardID-cellID" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --h: int # format: int32
  --w: int # format: int32
  --x: int # format: int32
  --y: int # format: int32
]: any -> record<h: int, id: string, links: record<self: string, view: string>, viewID: string, w: int, x: int, y: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, cell_id: $cell_id} | format pattern "/dashboards/{dashboard_id}/cells/{cell_id}"))
  let body = {"h": $h, "w": $w, "x": $x, "y": $y} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the view for a cell
#
# GET /dashboards/{dashboardID}/cells/{cellID}/view
# operationId: GetDashboardsIDCellsIDView
export def "dashboards-cells-view get" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<id: string, links: record<self: string>, name: string, properties: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, cell_id: $cell_id} | format pattern "/dashboards/{dashboard_id}/cells/{cell_id}/view"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "dashboards-cells-view update" [
  dashboard_id: string
  cell_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  properties: any
]: any -> record<id: string, links: record<self: string>, name: string, properties: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, cell_id: $cell_id} | format pattern "/dashboards/{dashboard_id}/cells/{cell_id}/view"))
  let body = {"name": $name, "properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a dashboard
#
# GET /dashboards/{dashboardID}/labels
# operationId: GetDashboardsIDLabels
export def "dashboards-labels get" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a dashboard
#
# POST /dashboards/{dashboardID}/labels
# operationId: PostDashboardsIDLabels
export def "dashboards-labels create" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a dashboard
#
# DELETE /dashboards/{dashboardID}/labels/{labelID}
# operationId: DeleteDashboardsIDLabelsID
export def "dashboards-labels delete" [
  dashboard_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, label_id: $label_id} | format pattern "/dashboards/{dashboard_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all dashboard members
#
# GET /dashboards/{dashboardID}/members
# operationId: GetDashboardsIDMembers
export def "dashboards-members get" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/members"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a dashboard
#
# POST /dashboards/{dashboardID}/members
# operationId: PostDashboardsIDMembers
export def "dashboards-members create" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/members"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a dashboard
#
# DELETE /dashboards/{dashboardID}/members/{userID}
# operationId: DeleteDashboardsIDMembersID
export def "dashboards-members delete" [
  dashboard_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, user_id: $user_id} | format pattern "/dashboards/{dashboard_id}/members/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all dashboard owners
#
# GET /dashboards/{dashboardID}/owners
# operationId: GetDashboardsIDOwners
export def "dashboards-owners get" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/owners"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a dashboard
#
# POST /dashboards/{dashboardID}/owners
# operationId: PostDashboardsIDOwners
export def "dashboards-owners create" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id} | format pattern "/dashboards/{dashboard_id}/owners"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a dashboard
#
# DELETE /dashboards/{dashboardID}/owners/{userID}
# operationId: DeleteDashboardsIDOwnersID
export def "dashboards-owners delete" [
  dashboard_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dashboard_id: $dashboard_id, user_id: $user_id} | format pattern "/dashboards/{dashboard_id}/owners/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all database retention policy mappings
#
# GET /dbrps
# operationId: GetDBRPs
export def "dbrps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID to filter on
  --id: string # Specifies the mapping ID to filter on
  --bucket-id: string # Specifies the bucket ID to filter on
  --default: oneof<nothing, bool> # Specifies filtering on default
  --db: string # Specifies the database to filter on
  --rp: string # Specifies the retention policy to filter on
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<content: table<bucketID: string, database: string, default: bool, id: string, links: record, org: string, orgID: string, retention_policy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "bucketID" $bucket_id "scalar") (serialize-qp "default" $default "scalar") (serialize-qp "db" $db "scalar") (serialize-qp "rp" $rp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dbrps" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a database retention policy mapping
#
# POST /dbrps
# operationId: PostDBRP
export def "dbrps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --bucket-id: string # the bucket ID used as target for the translation.
  --database: string # InfluxDB v1 database
  --default: oneof<nothing, bool> # Specify if this mapping represents the default retention policy for the database specificed.
  --links: record
  --org: string # the organization that owns this mapping.
  --org-id: string # the organization ID that owns this mapping.
  --retention-policy: string # InfluxDB v1 retention policy
]: any -> record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dbrps")
  let body = {"bucketID": $bucket_id, "database": $database, "default": $default, "links": $links, "org": $org, "orgID": $org_id, "retention_policy": $retention_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a database retention policy
#
# DELETE /dbrps/{dbrpID}
# operationId: DeleteDBRPID
export def "dbrps delete" [
  dbrp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID of the mapping
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dbrp_id: $dbrp_id} | format pattern "/dbrps/{dbrp_id}") $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a database retention policy mapping
#
# GET /dbrps/{dbrpID}
# operationId: GetDBRPsID
export def "dbrps get" [
  dbrp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID of the mapping
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dbrp_id: $dbrp_id} | format pattern "/dbrps/{dbrp_id}") $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a database retention policy mapping
#
# PATCH /dbrps/{dbrpID}
# operationId: PatchDBRPID
export def "dbrps update" [
  dbrp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Specifies the organization ID of the mapping
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --database: string # InfluxDB v1 database
  --default: oneof<nothing, bool>
  --links: record
  --retention-policy: string # InfluxDB v1 retention policy
]: any -> record<bucketID: string, database: string, default: bool, id: string, links: record<next: string, prev: string, self: string>, org: string, orgID: string, retention_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dbrp_id: $dbrp_id} | format pattern "/dbrps/{dbrp_id}") $qp)
  let body = {"database": $database, "default": $default, "links": $links, "retention_policy": $retention_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete time series data from InfluxDB
#
# POST /delete
# operationId: PostDelete
export def "delete create" [
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
  --org-id: string # Specifies the organization ID of the resource.
  --bucket-id: string # Specifies the bucket ID to delete data from.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --predicate: string # InfluxQL-like delete statement (e.g. tag1="value1" and (tag2="value2" and tag3!="value3"))
  start: string # RFC3339Nano (format: date-time)
  stop: string # RFC3339Nano (format: date-time)
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "bucketID" $bucket_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/delete" $qp)
  let body = {"predicate": $predicate, "start": $start, "stop": $stop} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all templates
#
# GET /documents/templates
# operationId: GetDocumentsTemplates
export def "documents-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the name of the organization of the template.
  --org-id: string # Specifies the organization ID of the template.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<documents: table<id: string, labels: list, links: record, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents/templates" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "documents-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  content: record
  --labels: list # An array of label IDs to be added as labels to the document.
  meta: record # shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
  --org: string # The organization Name. Specify either `orgID` or `org`.
  --org-id: string # The organization Name. Specify either `orgID` or `org`.
]: any -> record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/templates")
  let body = {"content": $content, "labels": $labels, "meta": $meta, "org": $org, "orgID": $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /documents/templates/{templateID}
# operationId: DeleteDocumentsTemplatesID
export def "documents-templates delete" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id} | format pattern "/documents/templates/{template_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a template
#
# GET /documents/templates/{templateID}
# operationId: GetDocumentsTemplatesID
export def "documents-templates get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id} | format pattern "/documents/templates/{template_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "documents-templates update" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content: record
  --meta: record # shape: {description?: string, name: string, templateID?: string, type?: string, version: string}
]: any -> record<content: record, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<self: string>, meta: record<createdAt: string, description: string, name: string, templateID: string, type: string, updatedAt: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id} | format pattern "/documents/templates/{template_id}"))
  let body = {"content": $content, "meta": $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a template
#
# GET /documents/templates/{templateID}/labels
# operationId: GetDocumentsTemplatesIDLabels
export def "documents-templates-labels get" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id} | format pattern "/documents/templates/{template_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a template
#
# POST /documents/templates/{templateID}/labels
# operationId: PostDocumentsTemplatesIDLabels
export def "documents-templates-labels create" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id} | format pattern "/documents/templates/{template_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a template
#
# DELETE /documents/templates/{templateID}/labels/{labelID}
# operationId: DeleteDocumentsTemplatesIDLabelsID
export def "documents-templates-labels delete" [
  template_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id, label_id: $label_id} | format pattern "/documents/templates/{template_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the feature flags for the currently authenticated user
#
# GET /flags
# operationId: GetFlags
export def "flags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/flags")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the health of an instance
#
# GET /health
# operationId: GetHealth
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all labels
#
# GET /labels
# operationId: GetLabels
export def "labels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The organization ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a label
#
# POST /labels
# operationId: PostLabels
export def "labels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  org_id: string
  --properties: record # Key/Value pairs associated with this label. Keys can be removed by sending an update with an empty value. (e.g. {color: ffb3b3, description: this is a description})
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/labels")
  let body = {"name": $name, "orgID": $org_id, "properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /labels/{labelID}
# operationId: DeleteLabelsID
export def "labels delete" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({label_id: $label_id} | format pattern "/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a label
#
# GET /labels/{labelID}
# operationId: GetLabelsID
export def "labels get" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({label_id: $label_id} | format pattern "/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a label
#
# PATCH /labels/{labelID}
# operationId: PatchLabelsID
export def "labels update" [
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --name: string
  --properties: record # Key/Value pairs associated with this label. Keys can be removed by sending an update with an empty value. (e.g. {color: ffb3b3, description: this is a description})
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({label_id: $label_id} | format pattern "/labels/{label_id}"))
  let body = {"name": $name, "properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the currently authenticated user
#
# GET /me
# operationId: GetMe
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a password
#
# PUT /me/password
# operationId: PutMePassword
export def "me-password update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  password: string
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/password")
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all notification endpoints
#
# GET /notificationEndpoints
# operationId: GetNotificationEndpoints
export def "notification-endpoints list" [
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
  --org-id: string # Only show notification endpoints that belong to specific organization ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, notificationEndpoints: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notificationEndpoints" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a notification endpoint
#
# POST /notificationEndpoints
# operationId: CreateNotificationEndpoint
export def "notification-endpoints create" [
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
export def "notification-endpoints delete" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id} | format pattern "/notificationEndpoints/{endpoint_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a notification endpoint
#
# GET /notificationEndpoints/{endpointID}
# operationId: GetNotificationEndpointsID
export def "notification-endpoints get" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id} | format pattern "/notificationEndpoints/{endpoint_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a notification endpoint
#
# PATCH /notificationEndpoints/{endpointID}
# operationId: PatchNotificationEndpointsID
export def "notification-endpoints update-by-endpointID" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id} | format pattern "/notificationEndpoints/{endpoint_id}"))
  let body = {"description": $description, "name": $name, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a notification endpoint
#
# PUT /notificationEndpoints/{endpointID}
# operationId: PutNotificationEndpointsID
export def "notification-endpoints update-by-endpointID-1" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id} | format pattern "/notificationEndpoints/{endpoint_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a notification endpoint
#
# GET /notificationEndpoints/{endpointID}/labels
# operationId: GetNotificationEndpointsIDLabels
export def "notification-endpoints-labels get" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id} | format pattern "/notificationEndpoints/{endpoint_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a notification endpoint
#
# POST /notificationEndpoints/{endpointID}/labels
# operationId: PostNotificationEndpointIDLabels
export def "notification-endpoints-labels create" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id} | format pattern "/notificationEndpoints/{endpoint_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a notification endpoint
#
# DELETE /notificationEndpoints/{endpointID}/labels/{labelID}
# operationId: DeleteNotificationEndpointsIDLabelsID
export def "notification-endpoints-labels delete" [
  endpoint_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({endpoint_id: $endpoint_id, label_id: $label_id} | format pattern "/notificationEndpoints/{endpoint_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all notification rules
#
# GET /notificationRules
# operationId: GetNotificationRules
export def "notification-rules list" [
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
  --org-id: string # Only show notification rules that belong to a specific organization ID.
  --check-id: string # Only show notifications that belong to the specific check ID.
  --tag: string # Only return notification rules that "would match" statuses which contain the tag key value pairs provided. (e.g. env:prod)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, notificationRules: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "checkID" $check_id "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notificationRules" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a notification rule
#
# POST /notificationRules
# operationId: CreateNotificationRule
export def "notification-rules create" [
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
export def "notification-rules delete" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a notification rule
#
# GET /notificationRules/{ruleID}
# operationId: GetNotificationRulesID
export def "notification-rules get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a notification rule
#
# PATCH /notificationRules/{ruleID}
# operationId: PatchNotificationRulesID
export def "notification-rules update-by-ruleID" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  --name: string
  --status: string@status-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}"))
  let body = {"description": $description, "name": $name, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a notification rule
#
# PUT /notificationRules/{ruleID}
# operationId: PutNotificationRulesID
export def "notification-rules update-by-ruleID-1" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a notification rule
#
# GET /notificationRules/{ruleID}/labels
# operationId: GetNotificationRulesIDLabels
export def "notification-rules-labels get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a notification rule
#
# POST /notificationRules/{ruleID}/labels
# operationId: PostNotificationRuleIDLabels
export def "notification-rules-labels create" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete label from a notification rule
#
# DELETE /notificationRules/{ruleID}/labels/{labelID}
# operationId: DeleteNotificationRulesIDLabelsID
export def "notification-rules-labels delete" [
  rule_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id, label_id: $label_id} | format pattern "/notificationRules/{rule_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a notification rule query
#
# GET /notificationRules/{ruleID}/query
# operationId: GetNotificationRulesIDQuery
export def "notification-rules-query get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<flux: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/notificationRules/{rule_id}/query"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all organizations
#
# GET /orgs
# operationId: GetOrgs
export def "orgs list" [
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
  --org-id: string # Filter organizations to a specific organization ID.
  --user-id: string # Filter organizations to a specific user ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, orgs: table<createdAt: string, description: string, id: string, links: record, name: string, status: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "userID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /orgs
# operationId: PostOrgs
export def "orgs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string
  name: string
]: any -> record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgs")
  let body = {"description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organization
#
# DELETE /orgs/{orgID}
# operationId: DeleteOrgsID
export def "orgs delete" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an organization
#
# GET /orgs/{orgID}
# operationId: GetOrgsID
export def "orgs get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /orgs/{orgID}
# operationId: PatchOrgsID
export def "orgs update" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # New description to set on the organization
  --name: string # New name to set on the organization
]: any -> record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}"))
  let body = {"description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all members of an organization
#
# GET /orgs/{orgID}/members
# operationId: GetOrgsIDMembers
export def "orgs-members get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/members"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to an organization
#
# POST /orgs/{orgID}/members
# operationId: PostOrgsIDMembers
export def "orgs-members create" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/members"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from an organization
#
# DELETE /orgs/{orgID}/members/{userID}
# operationId: DeleteOrgsIDMembersID
export def "orgs-members delete" [
  org_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id, user_id: $user_id} | format pattern "/orgs/{org_id}/members/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of an organization
#
# GET /orgs/{orgID}/owners
# operationId: GetOrgsIDOwners
export def "orgs-owners get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/owners"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to an organization
#
# POST /orgs/{orgID}/owners
# operationId: PostOrgsIDOwners
export def "orgs-owners create" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/owners"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from an organization
#
# DELETE /orgs/{orgID}/owners/{userID}
# operationId: DeleteOrgsIDOwnersID
export def "orgs-owners delete" [
  org_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id, user_id: $user_id} | format pattern "/orgs/{org_id}/owners/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all secret keys for an organization
#
# GET /orgs/{orgID}/secrets
# operationId: GetOrgsIDSecrets
export def "orgs-secrets get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<secrets: list<string>, links: record<org: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/secrets"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update secrets in an organization
#
# PATCH /orgs/{orgID}/secrets
# operationId: PatchOrgsIDSecrets
export def "orgs-secrets update" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/secrets"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete secrets from an organization
#
# POST /orgs/{orgID}/secrets/delete
# operationId: PostOrgsIDSecrets
export def "orgs-secrets-delete create" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --secrets: list
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: $org_id} | format pattern "/orgs/{org_id}/secrets/delete"))
  let body = {"secrets": $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "query create" [
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
  --org-id: string # Specifies the ID of the organization executing the query. If both `orgID` and `org` are specified, `org` takes precedence.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --accept-encoding: string@accept-encoding-completer # The Accept-Encoding request HTTP header advertises which content encoding, usually a compression algorithm, the client is able to understand.
  --content-type: string@content-type-completer
  --dialect: record # Dialect are options to change the default CSV output format; https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions — shape: {annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
  --extern: record # Represents a source from a single file — shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
  --now: string # Specifies the time that should be reported as "now" in the query. Default is the server's now time. (format: date-time)
  --params: record # Enumeration of key/value pairs that respresent parameters to be injected into query (can only specify either this field or extern and not both)
  --query: string # Query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
  --bucket: string # Bucket is to be used instead of the database and retention policy specified in the InfluxQL query.
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query" $qp)
  let body = {"dialect": $dialect, "extern": $extern, "now": $now, "params": $params, "query": $query, "type": $type, "bucket": $bucket} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span, "Accept-Encoding": $accept_encoding, "Content-Type": $content_type} | compact
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
export def "query-analyze create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content-type: string@content-type-completer-1
  --dialect: record # Dialect are options to change the default CSV output format; https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions — shape: {annotations?: list, commentPrefix?: string, dateTimeFormat?: "RFC3339"|"RFC3339Nano", delimiter?: string, header?: bool}
  --extern: record # Represents a source from a single file — shape: {body?: list, imports?: list, name?: string, package?: record, type?: string}
  --now: string # Specifies the time that should be reported as "now" in the query. Default is the server's now time. (format: date-time)
  --params: record # Enumeration of key/value pairs that respresent parameters to be injected into query (can only specify either this field or extern and not both)
  query: string # Query script to execute.
  --type: string@type-completer # The type of query. Must be "flux".
]: any -> record<errors: table<character: int, column: int, line: int, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/analyze")
  let body = {"dialect": $dialect, "extern": $extern, "now": $now, "params": $params, "query": $query, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate an Abstract Syntax Tree (AST) from a query
#
# POST /query/ast
# operationId: PostQueryAst
export def "query-ast create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content-type: string@content-type-completer-1
  query: string # Flux query script to be analyzed
]: any -> record<ast: record<files: list<record>, package: string, path: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/ast")
  let body = {"query": $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve query suggestions
#
# GET /query/suggestions
# operationId: GetQuerySuggestions
export def "query-suggestions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<funcs: table<name: string, params: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query/suggestions")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve query suggestions for a branching suggestion
#
# GET /query/suggestions/{name}
# operationId: GetQuerySuggestionsName
export def "query-suggestions get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<name: string, params: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: $name} | format pattern "/query/suggestions/{name}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the readiness of an instance at startup
#
# GET /ready
# operationId: GetReady
export def "ready get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<started: string, status: string, up: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ready")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all scraper targets
#
# GET /scrapers
# operationId: GetScrapers
export def "scrapers list" [
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
  --org-id: string # Specifies the organization ID of the scraper target.
  --org: string # Specifies the organization name of the scraper target.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<configurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "id" $id "multi") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scrapers" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a scraper target
#
# POST /scrapers
# operationId: PostScrapers
export def "scrapers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --allow-insecure: oneof<nothing, bool> # Skip TLS verification on endpoint. (default: false)
  --bucket-id: string # The ID of the bucket to write to.
  --name: string # The name of the scraper target.
  --org-id: string # The organization ID.
  --type: string@type-completer-1 # The type of the metrics to be parsed.
  --body-url: string # The URL of the metrics endpoint. (e.g. http://localhost:9090/metrics)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scrapers")
  let body = {"allowInsecure": $allow_insecure, "bucketID": $bucket_id, "name": $name, "orgID": $org_id, "type": $type, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a scraper target
#
# DELETE /scrapers/{scraperTargetID}
# operationId: DeleteScrapersID
export def "scrapers delete" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a scraper target
#
# GET /scrapers/{scraperTargetID}
# operationId: GetScrapersID
export def "scrapers get" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a scraper target
#
# PATCH /scrapers/{scraperTargetID}
# operationId: PatchScrapersID
export def "scrapers update" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --allow-insecure: oneof<nothing, bool> # Skip TLS verification on endpoint. (default: false)
  --bucket-id: string # The ID of the bucket to write to.
  --name: string # The name of the scraper target.
  --org-id: string # The organization ID.
  --type: string@type-completer-1 # The type of the metrics to be parsed.
  --body-url: string # The URL of the metrics endpoint. (e.g. http://localhost:9090/metrics)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}"))
  let body = {"allowInsecure": $allow_insecure, "bucketID": $bucket_id, "name": $name, "orgID": $org_id, "type": $type, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a scraper target
#
# GET /scrapers/{scraperTargetID}/labels
# operationId: GetScrapersIDLabels
export def "scrapers-labels get" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a scraper target
#
# POST /scrapers/{scraperTargetID}/labels
# operationId: PostScrapersIDLabels
export def "scrapers-labels create" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/labels/{labelID}
# operationId: DeleteScrapersIDLabelsID
export def "scrapers-labels delete" [
  scraper_target_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id, label_id: $label_id} | format pattern "/scrapers/{scraper_target_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users with member privileges for a scraper target
#
# GET /scrapers/{scraperTargetID}/members
# operationId: GetScrapersIDMembers
export def "scrapers-members get" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}/members"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a scraper target
#
# POST /scrapers/{scraperTargetID}/members
# operationId: PostScrapersIDMembers
export def "scrapers-members create" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}/members"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/members/{userID}
# operationId: DeleteScrapersIDMembersID
export def "scrapers-members delete" [
  scraper_target_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id, user_id: $user_id} | format pattern "/scrapers/{scraper_target_id}/members/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a scraper target
#
# GET /scrapers/{scraperTargetID}/owners
# operationId: GetScrapersIDOwners
export def "scrapers-owners get" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}/owners"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a scraper target
#
# POST /scrapers/{scraperTargetID}/owners
# operationId: PostScrapersIDOwners
export def "scrapers-owners create" [
  scraper_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id} | format pattern "/scrapers/{scraper_target_id}/owners"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a scraper target
#
# DELETE /scrapers/{scraperTargetID}/owners/{userID}
# operationId: DeleteScrapersIDOwnersID
export def "scrapers-owners delete" [
  scraper_target_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scraper_target_id: $scraper_target_id, user_id: $user_id} | format pattern "/scrapers/{scraper_target_id}/owners/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if database has default user, org, bucket
#
# GET /setup
# operationId: GetSetup
export def "setup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<allowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set up initial user, org and bucket
#
# POST /setup
# operationId: PostSetup
@deprecated --flag retention-period-hrs
export def "setup create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  bucket: string
  org: string
  --password: string
  --retention-period-hrs: int # Retention period *in nanoseconds* for the new bucket. This key's name has been misleading since OSS 2.0 GA, please transition to use `retentionPeriodSeconds`  (DEPRECATED)
  --retention-period-seconds: int # format: int64
  --body-token: string # Authentication token to set on the initial user. If not specified, the server will generate a token.
  username: string
]: any -> record<auth: record<description: string, status: string, createdAt: string, id: string, links: record<self: string, user: string>, org: string, orgID: string, permissions: list<record>, token: string, updatedAt: string, user: string, userID: string>, bucket: record<createdAt: string, description: string, id: string, labels: list<record>, links: record<labels: string, members: string, org: string, owners: string, self: string, write: string>, name: string, orgID: string, retentionRules: list<record>, rp: string, schemaType: string, type: string, updatedAt: string>, org: record<createdAt: string, description: string, id: string, links: record<buckets: string, dashboards: string, labels: string, members: string, owners: string, secrets: string, self: string, tasks: string>, name: string, status: string, updatedAt: string>, user: record<id: string, links: record<self: string>, name: string, oauthID: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup")
  let body = {"bucket": $bucket, "org": $org, "password": $password, "retentionPeriodHrs": $retention_period_hrs, "retentionPeriodSeconds": $retention_period_seconds, "token": $body_token, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exchange basic auth credentials for session
#
# POST /signin
# operationId: PostSignin
export def "signin create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signin")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Expire the current session
#
# POST /signout
# operationId: PostSignout
export def "signout create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signout")
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all sources
#
# GET /sources
# operationId: GetSources
export def "sources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, sources: table<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list, links: record, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sources" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "sources create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --default: oneof<nothing, bool>
  --default-rp: string
  --id: string
  --insecure-skip-verify: oneof<nothing, bool>
  --links: record # shape: {buckets?: string, health?: string, query?: string, self?: string}
  --meta-url: string # format: uri
  --name: string
  --org-id: string
  --password: string
  --shared-secret: string
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
  let body = {"default": $default, "defaultRP": $default_rp, "id": $id, "insecureSkipVerify": $insecure_skip_verify, "links": $links, "metaUrl": $meta_url, "name": $name, "orgID": $org_id, "password": $password, "sharedSecret": $shared_secret, "telegraf": $telegraf, "token": $body_token, "type": $type, "url": $body_url, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a source
#
# DELETE /sources/{sourceID}
# operationId: DeleteSourcesID
export def "sources delete" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({source_id: $source_id} | format pattern "/sources/{source_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a source
#
# GET /sources/{sourceID}
# operationId: GetSourcesID
export def "sources get" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({source_id: $source_id} | format pattern "/sources/{source_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "sources update" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --default: oneof<nothing, bool>
  --default-rp: string
  --id: string
  --insecure-skip-verify: oneof<nothing, bool>
  --links: record # shape: {buckets?: string, health?: string, query?: string, self?: string}
  --meta-url: string # format: uri
  --name: string
  --org-id: string
  --password: string
  --shared-secret: string
  --telegraf: string
  --body-token: string
  --type: string@type-completer-2
  --body-url: string # format: uri
  --username: string
]: any -> record<default: bool, defaultRP: string, id: string, insecureSkipVerify: bool, languages: list<string>, links: record<buckets: string, health: string, query: string, self: string>, metaUrl: string, name: string, orgID: string, password: string, sharedSecret: string, telegraf: string, token: string, type: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({source_id: $source_id} | format pattern "/sources/{source_id}"))
  let body = {"default": $default, "defaultRP": $default_rp, "id": $id, "insecureSkipVerify": $insecure_skip_verify, "links": $links, "metaUrl": $meta_url, "name": $name, "orgID": $org_id, "password": $password, "sharedSecret": $shared_secret, "telegraf": $telegraf, "token": $body_token, "type": $type, "url": $body_url, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get buckets in a source
#
# GET /sources/{sourceID}/buckets
# operationId: GetSourcesIDBuckets
export def "sources-buckets get" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<buckets: table<createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, retentionRules: list, rp: string, schemaType: string, type: string, updatedAt: string>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_id: $source_id} | format pattern "/sources/{source_id}/buckets") $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the health of a source
#
# GET /sources/{sourceID}/health
# operationId: GetSourcesIDHealth
export def "sources-health get" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<checks: list<any>, commit: string, message: string, name: string, status: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({source_id: $source_id} | format pattern "/sources/{source_id}/health"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all installed InfluxDB templates
#
# GET /stacks
# operationId: ListStacks
export def "stacks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The organization id of the stacks
  --name: string # A collection of names to filter the list by.
  --stack-id: string # A collection of stackIDs to filter the list by.
]: nothing -> record<stacks: table<createdAt: string, events: list, id: string, orgID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "stackID" $stack_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new stack
#
# POST /stacks
# operationId: CreateStack
export def "stacks create" [
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
  --org-id: string
  --urls: list
]: any -> record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stacks")
  let body = {"description": $description, "name": $name, "orgID": $org_id, "urls": $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a stack and associated resources
#
# DELETE /stacks/{stack_id}
# operationId: DeleteStack
export def "stacks delete" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The identifier of the organization.
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stack_id: $stack_id} | format pattern "/stacks/{stack_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a stack
#
# GET /stacks/{stack_id}
# operationId: ReadStack
export def "stacks get" [
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
  let full_url = (build-url $base ({stack_id: $stack_id} | format pattern "/stacks/{stack_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an InfluxDB Stack
#
# PATCH /stacks/{stack_id}
# operationId: UpdateStack
# --additionalResources item shape: {kind: string, resourceID: string, templateMetaName?: string}
export def "stacks update" [
  stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-resources: list # item shape: {kind: string, resourceID: string, templateMetaName?: string}
  --description: string # nullable
  --name: string # nullable
  --template-ur-ls: list # nullable
]: any -> record<createdAt: string, events: table<description: string, eventType: string, name: string, resources: list, sources: list, updatedAt: string, urls: list>, id: string, orgID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stack_id: $stack_id} | format pattern "/stacks/{stack_id}"))
  let body = {"additionalResources": $additional_resources, "description": $description, "name": $name, "templateURLs": $template_ur_ls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uninstall an InfluxDB Stack
#
# POST /stacks/{stack_id}/uninstall
# operationId: UninstallStack
export def "stacks-uninstall post" [
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
  let full_url = (build-url $base ({stack_id: $stack_id} | format pattern "/stacks/{stack_id}/uninstall"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all tasks
#
# GET /tasks
# operationId: GetTasks
export def "tasks list" [
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
  --org-id: string # Filter tasks to a specific organization ID.
  --status: string@status-completer # Filter tasks by a status--"inactive" or "active".
  --limit: int # The number of tasks to return (default: 100)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, tasks: table<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: list, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new task
#
# POST /tasks
# operationId: PostTasks
export def "tasks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --description: string # An optional description of the task.
  flux: string # The Flux script to run for this task.
  --org: string # The name of the organization that owns this Task.
  --org-id: string # The ID of the organization that owns this Task.
  --status: string@status-completer
]: any -> record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {"description": $description, "flux": $flux, "org": $org, "orgID": $org_id, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /tasks/{taskID}
# operationId: DeleteTasksID
export def "tasks delete" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a task
#
# GET /tasks/{taskID}
# operationId: GetTasksID
export def "tasks get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<authorizationID: string, createdAt: string, cron: string, description: string, every: string, flux: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, lastRunError: string, lastRunStatus: string, latestCompleted: string, links: record<labels: string, logs: string, members: string, owners: string, runs: string, self: string>, name: string, offset: string, org: string, orgID: string, status: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a task
#
# PATCH /tasks/{taskID}
# operationId: PatchTasksID
export def "tasks update" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
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
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}"))
  let body = {"cron": $cron, "description": $description, "every": $every, "flux": $flux, "name": $name, "offset": $offset, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a task
#
# GET /tasks/{taskID}/labels
# operationId: GetTasksIDLabels
export def "tasks-labels get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a task
#
# POST /tasks/{taskID}/labels
# operationId: PostTasksIDLabels
export def "tasks-labels create" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a task
#
# DELETE /tasks/{taskID}/labels/{labelID}
# operationId: DeleteTasksIDLabelsID
export def "tasks-labels delete" [
  task_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, label_id: $label_id} | format pattern "/tasks/{task_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all logs for a task
#
# GET /tasks/{taskID}/logs
# operationId: GetTasksIDLogs
export def "tasks-logs get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<events: table<message: string, runID: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/logs"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all task members
#
# GET /tasks/{taskID}/members
# operationId: GetTasksIDMembers
export def "tasks-members get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/members"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a task
#
# POST /tasks/{taskID}/members
# operationId: PostTasksIDMembers
export def "tasks-members create" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/members"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a task
#
# DELETE /tasks/{taskID}/members/{userID}
# operationId: DeleteTasksIDMembersID
export def "tasks-members delete" [
  task_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, user_id: $user_id} | format pattern "/tasks/{task_id}/members/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a task
#
# GET /tasks/{taskID}/owners
# operationId: GetTasksIDOwners
export def "tasks-owners get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/owners"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a task
#
# POST /tasks/{taskID}/owners
# operationId: PostTasksIDOwners
export def "tasks-owners create" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/owners"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a task
#
# DELETE /tasks/{taskID}/owners/{userID}
# operationId: DeleteTasksIDOwnersID
export def "tasks-owners delete" [
  task_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, user_id: $user_id} | format pattern "/tasks/{task_id}/owners/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List runs for a task
#
# GET /tasks/{taskID}/runs
# operationId: GetTasksIDRuns
export def "tasks-runs list" [
  task_id: string
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
  --after-time: string # Filter runs to those scheduled after this time, RFC3339 (format: date-time)
  --before-time: string # Filter runs to those scheduled before this time, RFC3339 (format: date-time)
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<next: string, prev: string, self: string>, runs: table<finishedAt: string, id: string, links: record, log: list, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "afterTime" $after_time "scalar") (serialize-qp "beforeTime" $before_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/runs") $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manually start a task run, overriding the current schedule
#
# POST /tasks/{taskID}/runs
# operationId: PostTasksIDRuns
export def "tasks-runs create" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --scheduled-for: string # Time used for run's "now" option, RFC3339.  Default is the server's now time. (nullable, format: date-time)
]: any -> record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/runs"))
  let body = {"scheduledFor": $scheduled_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a running task
#
# DELETE /tasks/{taskID}/runs/{runID}
# operationId: DeleteTasksIDRunsID
export def "tasks-runs delete" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, run_id: $run_id} | format pattern "/tasks/{task_id}/runs/{run_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single run for a task
#
# GET /tasks/{taskID}/runs/{runID}
# operationId: GetTasksIDRunsID
export def "tasks-runs get" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, run_id: $run_id} | format pattern "/tasks/{task_id}/runs/{run_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all logs for a run
#
# GET /tasks/{taskID}/runs/{runID}/logs
# operationId: GetTasksIDRunsIDLogs
export def "tasks-runs-logs get" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<events: table<message: string, runID: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, run_id: $run_id} | format pattern "/tasks/{task_id}/runs/{run_id}/logs"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry a task run
#
# POST /tasks/{taskID}/runs/{runID}/retry
# operationId: PostTasksIDRunsIDRetry
export def "tasks-runs-retry create" [
  task_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --body: record
]: any -> record<finishedAt: string, id: string, links: record<retry: string, self: string, task: string>, log: table<message: string, runID: string, time: string>, requestedAt: string, scheduledFor: string, startedAt: string, status: string, taskID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id, run_id: $run_id} | format pattern "/tasks/{task_id}/runs/{run_id}/retry"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json; charset=utf-8" $body
}

# List all Telegraf plugins
#
# GET /telegraf/plugins
# operationId: GetTelegrafPlugins
export def "telegraf-plugins get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type of plugin desired.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<os: string, plugins: table<config: string, description: string, name: string, type: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telegraf/plugins" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Telegraf configurations
#
# GET /telegrafs
# operationId: GetTelegrafs
export def "telegrafs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The organization ID the Telegraf config belongs to.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<configurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telegrafs" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "telegrafs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --config: string
  --description: string
  --metadata: record # shape: {buckets?: list}
  --name: string
  --org-id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/telegrafs")
  let body = {"config": $config, "description": $description, "metadata": $metadata, "name": $name, "orgID": $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Telegraf configuration
#
# DELETE /telegrafs/{telegrafID}
# operationId: DeleteTelegrafsID
export def "telegrafs delete" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Telegraf configuration
#
# GET /telegrafs/{telegrafID}
# operationId: GetTelegrafsID
export def "telegrafs get" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --hdr-accept: string@accept-completer-1
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span, "Accept": $hdr_accept} | compact
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
export def "telegrafs update" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --config: string
  --description: string
  --metadata: record # shape: {buckets?: list}
  --name: string
  --org-id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}"))
  let body = {"config": $config, "description": $description, "metadata": $metadata, "name": $name, "orgID": $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a Telegraf config
#
# GET /telegrafs/{telegrafID}/labels
# operationId: GetTelegrafsIDLabels
export def "telegrafs-labels get" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a Telegraf config
#
# POST /telegrafs/{telegrafID}/labels
# operationId: PostTelegrafsIDLabels
export def "telegrafs-labels create" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/labels/{labelID}
# operationId: DeleteTelegrafsIDLabelsID
export def "telegrafs-labels delete" [
  telegraf_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id, label_id: $label_id} | format pattern "/telegrafs/{telegraf_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users with member privileges for a Telegraf config
#
# GET /telegrafs/{telegrafID}/members
# operationId: GetTelegrafsIDMembers
export def "telegrafs-members get" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}/members"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a Telegraf config
#
# POST /telegrafs/{telegrafID}/members
# operationId: PostTelegrafsIDMembers
export def "telegrafs-members create" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}/members"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/members/{userID}
# operationId: DeleteTelegrafsIDMembersID
export def "telegrafs-members delete" [
  telegraf_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id, user_id: $user_id} | format pattern "/telegrafs/{telegraf_id}/members/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all owners of a Telegraf configuration
#
# GET /telegrafs/{telegrafID}/owners
# operationId: GetTelegrafsIDOwners
export def "telegrafs-owners get" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}/owners"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a Telegraf configuration
#
# POST /telegrafs/{telegrafID}/owners
# operationId: PostTelegrafsIDOwners
export def "telegrafs-owners create" [
  telegraf_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  id: string
  --name: string
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id} | format pattern "/telegrafs/{telegraf_id}/owners"))
  let body = {"id": $id, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an owner from a Telegraf config
#
# DELETE /telegrafs/{telegrafID}/owners/{userID}
# operationId: DeleteTelegrafsIDOwnersID
export def "telegrafs-owners delete" [
  telegraf_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({telegraf_id: $telegraf_id, user_id: $user_id} | format pattern "/telegrafs/{telegraf_id}/owners/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "templates-apply post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list
  --body-dry-run: oneof<nothing, bool>
  --env-refs: record
  --org-id: string
  --remotes: list # item shape: {contentType?: string, url: string}
  --secrets: record
  --stack-id: string
  --template: record # shape: {contentType?: string, contents?: list, sources?: list}
  --templates: list # item shape: {contentType?: string, contents?: list, sources?: list}
]: any -> record<diff: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>, errors: table<fields: list, indexes: list, kind: string, reason: string>, sources: list<string>, stackID: string, summary: record<buckets: list<record>, checks: list<record>, dashboards: list<record>, labelMappings: list<record>, labels: list<record>, missingEnvRefs: list<string>, missingSecrets: list<string>, notificationEndpoints: list<record>, notificationRules: list<record>, tasks: list<record>, telegrafConfigs: list<record>, variables: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/apply")
  let body = {"actions": $actions, "dryRun": $body_dry_run, "envRefs": $env_refs, "orgID": $org_id, "remotes": $remotes, "secrets": $secrets, "stackID": $stack_id, "template": $template, "templates": $templates} | compact
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
export def "templates-export export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --org-i-ds: list # item shape: {orgID?: string, resourceFilters?: record}
  --resources: record # shape: {id: string, kind: "Bucket"|"Check"|"CheckDeadman"|"CheckThreshold"|"Dashboard"|"Label"|"NotificationEndpoint"|"NotificationEndpointHTTP"|"NotificationEndpointPagerDuty"|"NotificationEndpointSlack"|"NotificationRule"|"Task"|"Telegraf"|"Variable", name?: string}
  --stack-id: string
]: any -> table<apiVersion: string, kind: string, meta: record<name: string>, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/export")
  let body = {"orgIDs": $org_i_ds, "resources": $resources, "stackID": $stack_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all users
#
# GET /users
# operationId: GetUsers
export def "users list" [
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
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<links: record<self: string>, users: table<id: string, links: record, name: string, oauthID: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: PostUsers
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  --oauth-id: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {"name": $name, "oauthID": $oauth_id, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/{userID}
# operationId: DeleteUsersID
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a user
#
# GET /users/{userID}
# operationId: GetUsersID
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{userID}
# operationId: PatchUsersID
export def "users update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  name: string
  --oauth-id: string
  --status: string@status-completer # If inactive the user is inactive. (default: active)
]: any -> record<id: string, links: record<self: string>, name: string, oauthID: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let body = {"name": $name, "oauthID": $oauth_id, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a password
#
# POST /users/{userID}/password
# operationId: PostUsersIDPassword
export def "users-password create" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  password: string
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/password"))
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all variables
#
# GET /variables
# operationId: GetVariables
export def "variables list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The name of the organization.
  --org-id: string # The organization ID.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<variables: table<arguments: record, createdAt: string, description: string, id: string, labels: list, links: record, name: string, orgID: string, selected: list, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variables" $qp)
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "variables create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --created-at: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  org_id: string
  --selected: list
  --updated-at: string # format: date-time
]: any -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/variables")
  let body = {"arguments": $arguments, "createdAt": $created_at, "description": $description, "labels": $labels, "name": $name, "orgID": $org_id, "selected": $selected, "updatedAt": $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a variable
#
# DELETE /variables/{variableID}
# operationId: DeleteVariablesID
export def "variables delete" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id} | format pattern "/variables/{variable_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a variable
#
# GET /variables/{variableID}
# operationId: GetVariablesID
export def "variables get" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id} | format pattern "/variables/{variable_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "variables update-by-variableID" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --created-at: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  org_id: string
  --selected: list
  --updated-at: string # format: date-time
]: any -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id} | format pattern "/variables/{variable_id}"))
  let body = {"arguments": $arguments, "createdAt": $created_at, "description": $description, "labels": $labels, "name": $name, "orgID": $org_id, "selected": $selected, "updatedAt": $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
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
export def "variables update-by-variableID-1" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  arguments: record # shape: {type?: "query", values?: record}
  --created-at: string # format: date-time
  --description: string
  --labels: list # item shape: {name?: string, properties?: record}
  name: string
  org_id: string
  --selected: list
  --updated-at: string # format: date-time
]: any -> record<arguments: record, createdAt: string, description: string, id: string, labels: table<id: string, name: string, orgID: string, properties: record>, links: record<labels: string, org: string, self: string>, name: string, orgID: string, selected: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id} | format pattern "/variables/{variable_id}"))
  let body = {"arguments": $arguments, "createdAt": $created_at, "description": $description, "labels": $labels, "name": $name, "orgID": $org_id, "selected": $selected, "updatedAt": $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all labels for a variable
#
# GET /variables/{variableID}/labels
# operationId: GetVariablesIDLabels
export def "variables-labels get" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<labels: table<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id} | format pattern "/variables/{variable_id}/labels"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a label to a variable
#
# POST /variables/{variableID}/labels
# operationId: PostVariablesIDLabels
export def "variables-labels create" [
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --label-id: string
]: any -> record<label: record<id: string, name: string, orgID: string, properties: record>, links: record<next: string, prev: string, self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id} | format pattern "/variables/{variable_id}/labels"))
  let body = {"labelID": $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label from a variable
#
# DELETE /variables/{variableID}/labels/{labelID}
# operationId: DeleteVariablesIDLabelsID
export def "variables-labels delete" [
  variable_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
]: nothing -> record<code: string, err: string, message: string, op: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_id: $variable_id, label_id: $label_id} | format pattern "/variables/{variable_id}/labels/{label_id}"))
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write time series data into InfluxDB
#
# POST /write
# operationId: PostWrite
export def "write create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # Specifies the destination organization for writes. Takes either the ID or Name interchangeably. If both `orgID` and `org` are specified, `org` takes precedence.
  --org-id: string # Specifies the ID of the destination organization for writes. If both `orgID` and `org` are specified, `org` takes precedence.
  --bucket: string # The destination bucket for writes.
  --precision: string@precision-completer # The precision for the unix timestamps within the body line-protocol.
  --zap-trace-span: string # OpenTracing span context (e.g. {baggage: {key: value}, span_id: 1, trace_id: 1})
  --content-encoding: string@content-encoding-completer # When present, its value indicates to the database that compression is applied to the line-protocol body.
  --content-type: string@content-type-completer-2 # Content-Type is used to indicate the format of the data sent to the server.
  --content-length: int # Content-Length is an entity header is indicating the size of the entity-body, in bytes, sent to the database. If the length is greater than the database max body configuration option, a 413 response is sent.
  --hdr-accept: string@accept-completer-3 # Specifies the return content format.
  --body: record
]: any -> record<code: string, err: string, message: string, op: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "orgID" $org_id "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/write" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Zap-Trace-Span": $zap_trace_span, "Content-Encoding": $content_encoding, "Content-Type": $content_type, "Content-Length": $content_length, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}
