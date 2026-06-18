# Auto-generated client for Airflow API (Stable) v2.5.1
# Source: https://api.apis.guru/v2/specs/apache.org/2.5.1/openapi.json
# Auth: --token flag or $env.AIRFLOW_API_STABLE_TOKEN

const BASE_URL = "http://localhost/api/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AIRFLOW_API_STABLE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "negotiate" => { {headers: {Authorization: $"Negotiate ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost/api/v1" "https://apache.local"] }
def auth-scheme-completer [] { ["basic" "bearer" "negotiate" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }
def accept-completer-1 [] { ["application/json" "plain/text"] }
def state-completer [] { ["failed" "queued" "running" "success"] }
def state-completer-1 [] { ["failed" "queued" "success"] }
def new-state-completer [] { ["failed" "success"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "config get" } } | get name | first)
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

# Get current configuration
#
# GET /config
# operationId: get_config
export def "config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<sections: table<name: string, options: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/config")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List connections
#
# GET /connections
# operationId: get_connections
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a connection
#
# POST /connections
# operationId: post_connection
export def "connections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conn-type: string # The connection type.
  --connection-id: string # The connection ID.
  --description: string # The description of the connection. (nullable)
  --host: string # Host of the connection. (nullable)
  --login: string # Login of the connection. (nullable)
  --port: int # Port of the connection. (nullable)
  --schema: string # Schema of the connection. (nullable)
  --extra: string # Other values that cannot be put into another field, e.g. RSA keys. (nullable)
  --password: string # Password of the connection. (format: password)
]: any -> record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connections")
  let req_body = {"conn_type": $conn_type, "connection_id": $connection_id, "description": $description, "host": $host, "login": $login, "port": $port, "schema": $schema, "extra": $extra, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test a connection
#
# POST /connections/test
# operationId: test_connection
export def "connections-test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conn-type: string # The connection type.
  --connection-id: string # The connection ID.
  --description: string # The description of the connection. (nullable)
  --host: string # Host of the connection. (nullable)
  --login: string # Login of the connection. (nullable)
  --port: int # Port of the connection. (nullable)
  --schema: string # Schema of the connection. (nullable)
  --extra: string # Other values that cannot be put into another field, e.g. RSA keys. (nullable)
  --password: string # Password of the connection. (format: password)
]: any -> record<message: string, status: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connections/test")
  let req_body = {"conn_type": $conn_type, "connection_id": $connection_id, "description": $description, "host": $host, "login": $login, "port": $port, "schema": $schema, "extra": $extra, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a connection
#
# DELETE /connections/{connection_id}
# operationId: delete_connection
export def "connections delete" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a connection
#
# GET /connections/{connection_id}
# operationId: get_connection
export def "connections get" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a connection
#
# PATCH /connections/{connection_id}
# operationId: patch_connection
export def "connections update" [
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --conn-type: string # The connection type.
  --body-connection-id: string # The connection ID.
  --description: string # The description of the connection. (nullable)
  --host: string # Host of the connection. (nullable)
  --login: string # Login of the connection. (nullable)
  --port: int # Port of the connection. (nullable)
  --schema: string # Schema of the connection. (nullable)
  --extra: string # Other values that cannot be put into another field, e.g. RSA keys. (nullable)
  --password: string # Password of the connection. (format: password)
]: any -> record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update_mask" $update_mask "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}") $qp)
  let req_body = {"conn_type": $conn_type, "connection_id": $body_connection_id, "description": $description, "host": $host, "login": $login, "port": $port, "schema": $schema, "extra": $extra, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get a source code
#
# GET /dagSources/{file_token}
# operationId: get_dag_source
export def "dag-sources get" [
  file_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_token: (encode-path-segment $file_token)} | format pattern "/dagSources/{file_token}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List dag warnings
#
# GET /dagWarnings
# operationId: get_dag_warnings
export def "dag-warnings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-id: string # If set, only return DAG warnings with this dag_id.
  --warning-type: string # If set, only return DAG warnings with this type.
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dag_id" $dag_id "scalar") (serialize-qp "warning_type" $warning_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dagWarnings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List DAGs
#
# GET /dags
# operationId: get_dags
export def "dags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --tags: list<string> # List of tags to filter results. *New in version 2.2.0*
  --only-active: oneof<nothing, bool> # Only filter active DAGs. *New in version 2.1.1* (default: true)
  --dag-id-pattern: string # If set, only return DAGs with dag_ids matching this pattern.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "only_active" $only_active "scalar") (serialize-qp "dag_id_pattern" $dag_id_pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update DAGs
#
# PATCH /dags
# operationId: patch_dags
# --tags item shape: {name?: string}
export def "dags update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --tags: list<string> # List of tags to filter results. *New in version 2.2.0* — item shape: {name?: string}
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --only-active: oneof<nothing, bool> # Only filter active DAGs. *New in version 2.1.1* (default: true)
  --dag-id-pattern: string # If set, only update DAGs with dag_ids matching this pattern.
  --is-paused: oneof<nothing, bool> # Whether the DAG is paused. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "update_mask" $update_mask "csv") (serialize-qp "only_active" $only_active "scalar") (serialize-qp "dag_id_pattern" $dag_id_pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dags" $qp)
  let req_body = {"is_paused": $is_paused} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a DAG
#
# DELETE /dags/{dag_id}
# operationId: delete_dag
export def "dags delete" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get basic information about a DAG
#
# GET /dags/{dag_id}
# operationId: get_dag
export def "dags get" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a DAG
#
# PATCH /dags/{dag_id}
# operationId: patch_dag
# --tags item shape: {name?: string}
export def "dags update-by-dag_id" [
  dag_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --is-paused: oneof<nothing, bool> # Whether the DAG is paused. (nullable)
]: any -> record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update_mask" $update_mask "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}") $qp)
  let req_body = {"is_paused": $is_paused} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Clear a set of task instances
#
# POST /dags/{dag_id}/clearTaskInstances
# operationId: post_clear_task_instances
export def "dags-clear-task-instances create" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-run-id: string # The DagRun ID for this task instance (nullable)
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain a list of task instances planned to be cleaned, but not modified in any way. (default: true)
  --end-date: string # The maximum execution date to clear. (format: datetime)
  --include-downstream: oneof<nothing, bool> # If set to true, downstream tasks are also affected. (default: false)
  --include-future: oneof<nothing, bool> # If set to True, also tasks from future DAG Runs are affected. (default: false)
  --include-parentdag: oneof<nothing, bool> # Clear tasks in the parent dag of the subdag.
  --include-past: oneof<nothing, bool> # If set to True, also tasks from past DAG Runs are affected. (default: false)
  --include-subdags: oneof<nothing, bool> # Clear tasks in subdags and clear external tasks indicated by ExternalTaskMarker.
  --include-upstream: oneof<nothing, bool> # If set to true, upstream tasks are also affected. (default: false)
  --only-failed: oneof<nothing, bool> # Only clear failed tasks. (default: true)
  --only-running: oneof<nothing, bool> # Only clear running tasks. (default: false)
  --reset-dag-runs: oneof<nothing, bool> # Set state of DAG runs to RUNNING.
  --start-date: string # The minimum execution date to clear. (format: datetime)
  --task-ids: list<string> # A list of task ids to clear. *New in version 2.1.0*
]: any -> record<task_instances: table<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}/clearTaskInstances"))
  let req_body = {"dag_run_id": $dag_run_id, "dry_run": $body_dry_run, "end_date": $end_date, "include_downstream": $include_downstream, "include_future": $include_future, "include_parentdag": $include_parentdag, "include_past": $include_past, "include_subdags": $include_subdags, "include_upstream": $include_upstream, "only_failed": $only_failed, "only_running": $only_running, "reset_dag_runs": $reset_dag_runs, "start_date": $start_date, "task_ids": $task_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List DAG runs
#
# GET /dags/{dag_id}/dagRuns
# operationId: get_dag_runs
export def "dags-dag-runs list" [
  dag_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "execution_date_gte" $execution_date_gte "scalar") (serialize-qp "execution_date_lte" $execution_date_lte "scalar") (serialize-qp "start_date_gte" $start_date_gte "scalar") (serialize-qp "start_date_lte" $start_date_lte "scalar") (serialize-qp "end_date_gte" $end_date_gte "scalar") (serialize-qp "end_date_lte" $end_date_lte "scalar") (serialize-qp "state" $state "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}/dagRuns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new DAG run
#
# POST /dags/{dag_id}/dagRuns
# operationId: post_dag_run
@deprecated --flag execution-date
export def "dags-dag-runs create" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conf: record # JSON object describing additional configuration parameters. The value of this field can be set only when creating the object. If you try to modify the field of an existing object, the request fails with an BAD_REQUEST error.
  --dag-run-id: string # Run ID. The value of this field can be set only when creating the object. If you try to modify the field of an existing object, the request fails with an BAD_REQUEST error. If not provided, a value will be generated based on execution_date. If the specified dag_run_id is in use, the creation request fails with an ALREADY_EXISTS error. This together with DAG_ID are a unique key. (nullable)
  --execution-date: string # The execution date. This is the same as logical_date, kept for backwards compatibility. If both this field and logical_date are provided but with different values, the request will fail with an BAD_REQUEST error. *Changed in version 2.2.0*&#58; Field becomes nullable. *Deprecated since version 2.2.0*&#58; Use 'logical_date' instead. (DEPRECATED, nullable, format: date-time)
  --logical-date: string # The logical date (previously called execution date). This is the time or interval covered by this DAG run, according to the DAG definition. The value of this field can be set only when creating the object. If you try to modify the field of an existing object, the request fails with an BAD_REQUEST error. This together with DAG_ID are a unique key. *New in version 2.2.0* (nullable, format: date-time)
  --note: string # Contains manually entered notes by the user about the DagRun. *New in version 2.5.0* (nullable)
  --state: string@state-completer # DAG State. *Changed in version 2.1.3*&#58; 'queued' is added as a possible value.
]: any -> record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}/dagRuns"))
  let req_body = {"conf": $conf, "dag_run_id": $dag_run_id, "execution_date": $execution_date, "logical_date": $logical_date, "note": $note, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a DAG run
#
# DELETE /dags/{dag_id}/dagRuns/{dag_run_id}
# operationId: delete_dag_run
export def "dags-dag-runs delete" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a DAG run
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}
# operationId: get_dag_run
export def "dags-dag-runs get" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a DAG run
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}
# operationId: update_dag_run_state
export def "dags-dag-runs update-state" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # The state to set this DagRun
]: any -> record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}"))
  let req_body = {"state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Clear a DAG run
#
# POST /dags/{dag_id}/dagRuns/{dag_run_id}/clear
# operationId: clear_dag_run
export def "dags-dag-runs-clear create" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain a list of task instances planned to be cleaned, but not modified in any way. (default: true)
]: any -> record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/clear"))
  let req_body = {"dry_run": $body_dry_run} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the DagRun note.
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/setNote
# operationId: set_dag_run_note
export def "dags-dag-runs-set-note update" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string # Custom notes left by users for this Dag Run.
]: any -> record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/setNote"))
  let req_body = {"note": $note} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List task instances
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances
# operationId: get_task_instances
export def "dags-dag-runs-task-instances list" [
  dag_id: any
  dag_run_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a task instance
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}
# operationId: get_task_instance
export def "dags-dag-runs-task-instances get" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the state of a task instance
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}
# operationId: patch_task_instance
export def "dags-dag-runs-task-instances update" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain the task instance planned to be affected, but won't be modified in any way. (default: false)
  --new-state: string@new-state-completer # Expected new state.
]: any -> record<dag_id: string, dag_run_id: string, execution_date: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}"))
  let req_body = {"dry_run": $body_dry_run, "new_state": $new_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List extra links
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/links
# operationId: get_extra_links
export def "dags-dag-runs-task-instances-links get-extra" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<extra_links: table<class_ref: record, href: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/links"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List mapped task instances
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/listMapped
# operationId: get_mapped_task_instances
export def "dags-dag-runs-task-instances-list-mapped get" [
  dag_id: any
  dag_run_id: any
  task_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --duration-gte: float # Returns objects greater than or equal to the specified values. This can be combined with duration_lte parameter to receive only the selected period.
  --duration-lte: float # Returns objects less than or equal to the specified values. This can be combined with duration_gte parameter to receive only the selected range.
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --pool: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --queue: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "execution_date_gte" $execution_date_gte "scalar") (serialize-qp "execution_date_lte" $execution_date_lte "scalar") (serialize-qp "start_date_gte" $start_date_gte "scalar") (serialize-qp "start_date_lte" $start_date_lte "scalar") (serialize-qp "end_date_gte" $end_date_gte "scalar") (serialize-qp "end_date_lte" $end_date_lte "scalar") (serialize-qp "duration_gte" $duration_gte "scalar") (serialize-qp "duration_lte" $duration_lte "scalar") (serialize-qp "state" $state "multi") (serialize-qp "pool" $pool "multi") (serialize-qp "queue" $queue "multi") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/listMapped") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logs
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/logs/{task_try_number}
# operationId: get_log
export def "dags-dag-runs-task-instances-logs get" [
  dag_id: string
  dag_run_id: string
  task_id: string
  task_try_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --full-content: oneof<nothing, bool> # A full content will be returned. By default, only the first fragment will be returned.
  --map-index: int # Filter on map index for mapped task.
  --qp-token: string # A token that allows you to continue fetching logs. If passed, it will specify the location from which the download should be continued.
]: nothing -> record<content: string, continuation_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "full_content" $full_content "scalar") (serialize-qp "map_index" $map_index "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id), task_try_number: (encode-path-segment $task_try_number)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/logs/{task_try_number}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the TaskInstance note.
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/setNote
# operationId: set_task_instance_note
export def "dags-dag-runs-task-instances-set-note update" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The custom note to set for this Task Instance.
]: any -> record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/setNote"))
  let req_body = {"note": $note} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List XCom entries
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries
# operationId: get_xcom_entries
export def "dags-dag-runs-task-instances-xcom-entries get" [
  dag_id: any
  dag_run_id: any
  task_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an XCom entry
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries/{xcom_key}
# operationId: get_xcom_entry
export def "dags-dag-runs-task-instances-xcom-entries get-entry" [
  dag_id: string
  dag_run_id: string
  task_id: string
  xcom_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deserialize: oneof<nothing, bool> # Whether to deserialize an XCom value when using a custom XCom backend. The XCom API endpoint calls `orm_deserialize_value` by default since an XCom may contain value that is potentially expensive to deserialize in the web server. Setting this to true overrides the consideration, and calls `deserialize_value` instead. This parameter is not meaningful when using the default XCom backend. *New in version 2.4.0* (default: false)
]: nothing -> record<dag_id: string, execution_date: string, key: string, task_id: string, timestamp: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deserialize" $deserialize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id), xcom_key: (encode-path-segment $xcom_key)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries/{xcom_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a mapped task instance
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}
# operationId: get_mapped_task_instance
export def "dags-dag-runs-task-instances get-mapped" [
  dag_id: string
  dag_run_id: string
  task_id: string
  map_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id), map_index: (encode-path-segment $map_index)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the state of a mapped task instance
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}
# operationId: patch_mapped_task_instance
export def "dags-dag-runs-task-instances update-mapped" [
  dag_id: string
  dag_run_id: string
  task_id: string
  map_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain the task instance planned to be affected, but won't be modified in any way. (default: false)
  --new-state: string@new-state-completer # Expected new state.
]: any -> record<dag_id: string, dag_run_id: string, execution_date: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id), map_index: (encode-path-segment $map_index)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}"))
  let req_body = {"dry_run": $body_dry_run, "new_state": $new_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the TaskInstance note.
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}/setNote
# operationId: set_mapped_task_instance_note
export def "dags-dag-runs-task-instances-set-note update-mapped" [
  dag_id: string
  dag_run_id: string
  task_id: string
  map_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The custom note to set for this Task Instance.
]: any -> record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id), task_id: (encode-path-segment $task_id), map_index: (encode-path-segment $map_index)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}/setNote"))
  let req_body = {"note": $note} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get dataset events for a DAG run
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/upstreamDatasetEvents
# operationId: get_upstream_dataset_events
export def "dags-dag-runs-upstream-dataset-events get" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), dag_run_id: (encode-path-segment $dag_run_id)} | format pattern "/dags/{dag_id}/dagRuns/{dag_run_id}/upstreamDatasetEvents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a simplified representation of DAG
#
# GET /dags/{dag_id}/details
# operationId: get_dag_details
export def "dags-details get" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string, catchup: bool, concurrency: float, dag_run_timeout: record<__type: string, days: int, microseconds: int, seconds: int>, doc_md: string, end_date: string, is_paused_upon_creation: bool, last_parsed: string, orientation: string, params: record, render_template_as_native_obj: bool, start_date: string, template_search_path: list<string>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}/details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks for DAG
#
# GET /dags/{dag_id}/tasks
# operationId: get_tasks
export def "dags-tasks list" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record<tasks: table<class_ref: record, depends_on_past: bool, downstream_task_ids: list, end_date: string, execution_timeout: record, extra_links: list, is_mapped: bool, owner: string, pool: string, pool_slots: float, priority_weight: float, queue: string, retries: float, retry_delay: record, retry_exponential_backoff: bool, start_date: string, sub_dag: record, task_id: string, template_fields: list, trigger_rule: string, ui_color: string, ui_fgcolor: string, wait_for_downstream: bool, weight_rule: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}/tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get simplified representation of a task
#
# GET /dags/{dag_id}/tasks/{task_id}
# operationId: get_task
export def "dags-tasks get" [
  dag_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<class_ref: record<class_name: string, module_path: string>, depends_on_past: bool, downstream_task_ids: list<string>, end_date: string, execution_timeout: record<__type: string, days: int, microseconds: int, seconds: int>, extra_links: table<class_ref: record>, is_mapped: bool, owner: string, pool: string, pool_slots: float, priority_weight: float, queue: string, retries: float, retry_delay: record<__type: string, days: int, microseconds: int, seconds: int>, retry_exponential_backoff: bool, start_date: string, sub_dag: record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list<record>, timetable_description: string>, task_id: string, template_fields: list<string>, trigger_rule: string, ui_color: string, ui_fgcolor: string, wait_for_downstream: bool, weight_rule: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id), task_id: (encode-path-segment $task_id)} | format pattern "/dags/{dag_id}/tasks/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a state of task instances
#
# POST /dags/{dag_id}/updateTaskInstancesState
# operationId: post_set_task_instances_state
export def "dags-update-task-instances-state create-update" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-run-id: string # The task instance's DAG run ID. Either set this or execution_date but not both. *New in version 2.3.0*
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain a list of task instances planned to be affected, but won't be modified in any way. (default: true)
  --execution-date: string # The execution date. Either set this or dag_run_id but not both. (format: datetime)
  --include-downstream: oneof<nothing, bool> # If set to true, downstream tasks are also affected.
  --include-future: oneof<nothing, bool> # If set to True, also tasks from future DAG Runs are affected.
  --include-past: oneof<nothing, bool> # If set to True, also tasks from past DAG Runs are affected.
  --include-upstream: oneof<nothing, bool> # If set to true, upstream tasks are also affected.
  --new-state: string@new-state-completer # Expected new state.
  --task-id: string # The task ID.
]: any -> record<task_instances: table<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dag_id: (encode-path-segment $dag_id)} | format pattern "/dags/{dag_id}/updateTaskInstancesState"))
  let req_body = {"dag_run_id": $dag_run_id, "dry_run": $body_dry_run, "execution_date": $execution_date, "include_downstream": $include_downstream, "include_future": $include_future, "include_past": $include_past, "include_upstream": $include_upstream, "new_state": $new_state, "task_id": $task_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List DAG runs (batch)
#
# POST /dags/~/dagRuns/list
# operationId: get_dag_runs_batch
export def "dags-dag-runs-list get-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-ids: list<string> # Return objects with specific DAG IDs. The value can be repeated to retrieve multiple matching values (OR condition).
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with end_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with end_date_gte parameter to receive only the selected period. (format: date-time)
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte key to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte key to receive only the selected period. (format: date-time)
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --page-limit: int # The numbers of items to return. (default: 100)
  --page-offset: int # The number of items to skip before starting to collect the result set.
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte key to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period (format: date-time)
  --states: list<string> # Return objects with specific states. The value can be repeated to retrieve multiple matching values (OR condition).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dags/~/dagRuns/list")
  let req_body = {"dag_ids": $dag_ids, "end_date_gte": $end_date_gte, "end_date_lte": $end_date_lte, "execution_date_gte": $execution_date_gte, "execution_date_lte": $execution_date_lte, "order_by": $order_by, "page_limit": $page_limit, "page_offset": $page_offset, "start_date_gte": $start_date_gte, "start_date_lte": $start_date_lte, "states": $states} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List task instances (batch)
#
# POST /dags/~/dagRuns/~/taskInstances/list
# operationId: get_task_instances_batch
export def "dags-dag-runs-task-instances-list get-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-ids: list<string> # Return objects with specific DAG IDs. The value can be repeated to retrieve multiple matching values (OR condition).
  --duration-gte: float # Returns objects greater than or equal to the specified values. This can be combined with duration_lte parameter to receive only the selected period.
  --duration-lte: float # Returns objects less than or equal to the specified values. This can be combined with duration_gte parameter to receive only the selected range.
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --pool: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --queue: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dags/~/dagRuns/~/taskInstances/list")
  let req_body = {"dag_ids": $dag_ids, "duration_gte": $duration_gte, "duration_lte": $duration_lte, "end_date_gte": $end_date_gte, "end_date_lte": $end_date_lte, "execution_date_gte": $execution_date_gte, "execution_date_lte": $execution_date_lte, "pool": $pool, "queue": $queue, "start_date_gte": $start_date_gte, "start_date_lte": $start_date_lte, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List datasets
#
# GET /datasets
# operationId: get_datasets
export def "datasets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --uri-pattern: string # If set, only return datasets with uris matching this pattern.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "uri_pattern" $uri_pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dataset events
#
# GET /datasets/events
# operationId: get_dataset_events
export def "datasets-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --dataset-id: int # The Dataset ID that updated the dataset.
  --source-dag-id: string # The DAG ID that updated the dataset.
  --source-task-id: string # The task ID that updated the dataset.
  --source-run-id: string # The DAG run ID that updated the dataset.
  --source-map-index: int # The map index that updated the dataset.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "dataset_id" $dataset_id "scalar") (serialize-qp "source_dag_id" $source_dag_id "scalar") (serialize-qp "source_task_id" $source_task_id "scalar") (serialize-qp "source_run_id" $source_run_id "scalar") (serialize-qp "source_map_index" $source_map_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datasets/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a dataset
#
# GET /datasets/{uri}
# operationId: get_dataset
export def "datasets get" [
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<consuming_dags: table<created_at: string, dag_id: string, updated_at: string>, created_at: string, extra: record, id: int, producing_tasks: table<created_at: string, dag_id: string, task_id: string, updated_at: string>, updated_at: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({uri: (encode-path-segment $uri)} | format pattern "/datasets/{uri}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List log entries
#
# GET /eventLogs
# operationId: get_event_logs
export def "event-logs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eventLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a log entry
#
# GET /eventLogs/{event_log_id}
# operationId: get_event_log
export def "event-logs get" [
  event_log_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dag_id: string, event: string, event_log_id: int, execution_date: string, extra: string, owner: string, task_id: string, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_log_id: (encode-path-segment $event_log_id)} | format pattern "/eventLogs/{event_log_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance status
#
# GET /health
# operationId: get_health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadatabase: record<status: string>, scheduler: record<latest_scheduler_heartbeat: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List import errors
#
# GET /importErrors
# operationId: get_import_errors
export def "import-errors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/importErrors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an import error
#
# GET /importErrors/{import_error_id}
# operationId: get_import_error
export def "import-errors get" [
  import_error_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filename: string, import_error_id: int, stack_trace: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({import_error_id: (encode-path-segment $import_error_id)} | format pattern "/importErrors/{import_error_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List permissions
#
# GET /permissions
# operationId: get_permissions
export def "permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of loaded plugins
#
# GET /plugins
# operationId: get_plugins
export def "plugins get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pools
#
# GET /pools
# operationId: get_pools
export def "pools list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a pool
#
# POST /pools
# operationId: post_pool
export def "pools create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the pool. *New in version 2.3.0* (nullable)
  --name: string # The name of pool.
  --slots: int # The maximum number of slots that can be assigned to tasks. One job may occupy one or more slots.
]: any -> record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pools")
  let req_body = {"description": $description, "name": $name, "slots": $slots} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a pool
#
# DELETE /pools/{pool_name}
# operationId: delete_pool
export def "pools delete" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pool_name: (encode-path-segment $pool_name)} | format pattern "/pools/{pool_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a pool
#
# GET /pools/{pool_name}
# operationId: get_pool
export def "pools get" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pool_name: (encode-path-segment $pool_name)} | format pattern "/pools/{pool_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a pool
#
# PATCH /pools/{pool_name}
# operationId: patch_pool
export def "pools update" [
  pool_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --description: string # The description of the pool. *New in version 2.3.0* (nullable)
  --name: string # The name of pool.
  --slots: int # The maximum number of slots that can be assigned to tasks. One job may occupy one or more slots.
]: any -> record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update_mask" $update_mask "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({pool_name: (encode-path-segment $pool_name)} | format pattern "/pools/{pool_name}") $qp)
  let req_body = {"description": $description, "name": $name, "slots": $slots} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List providers
#
# GET /providers
# operationId: get_providers
export def "providers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<providers: table<description: string, package_name: string, version: string>, total_entries: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List roles
#
# GET /roles
# operationId: get_roles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role
#
# POST /roles
# operationId: post_role
# --actions item shape: {action?: record, resource?: record}
export def "roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list # item shape: {action?: record, resource?: record}
  --name: string # The name of the role *Changed in version 2.3.0*&#58; A minimum character length requirement ('minLength') is added.
]: any -> record<actions: table<action: record, resource: record>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let req_body = {"actions": $actions, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a role
#
# DELETE /roles/{role_name}
# operationId: delete_role
export def "roles delete" [
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_name: (encode-path-segment $role_name)} | format pattern "/roles/{role_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a role
#
# GET /roles/{role_name}
# operationId: get_role
export def "roles get" [
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: table<action: record, resource: record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_name: (encode-path-segment $role_name)} | format pattern "/roles/{role_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role
#
# PATCH /roles/{role_name}
# operationId: patch_role
# --actions item shape: {action?: record, resource?: record}
export def "roles update" [
  role_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --actions: list # item shape: {action?: record, resource?: record}
  --name: string # The name of the role *Changed in version 2.3.0*&#58; A minimum character length requirement ('minLength') is added.
]: any -> record<actions: table<action: record, resource: record>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update_mask" $update_mask "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({role_name: (encode-path-segment $role_name)} | format pattern "/roles/{role_name}") $qp)
  let req_body = {"actions": $actions, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List users
#
# GET /users
# operationId: get_users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: post_user
# --roles item shape: {name?: string}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The user's email. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --first-name: string # The user's first name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --last-name: string # The user's last name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --roles: list # User roles. *Changed in version 2.2.0*&#58; Field is no longer read-only. — item shape: {name?: string}
  --username: string # The username. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --password: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "roles": $roles, "username": $username, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a user
#
# DELETE /users/{username}
# operationId: delete_user
export def "users delete" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{username}
# operationId: get_user
export def "users get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: table<name: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{username}
# operationId: patch_user
# --roles item shape: {name?: string}
export def "users update" [
  username: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --email: string # The user's email. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --first-name: string # The user's first name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --last-name: string # The user's last name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --roles: list # User roles. *Changed in version 2.2.0*&#58; Field is no longer read-only. — item shape: {name?: string}
  --body-username: string # The username. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --password: string
]: any -> record<actions: table<action: record, resource: record>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update_mask" $update_mask "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}") $qp)
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "roles": $roles, "username": $body_username, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List variables
#
# GET /variables
# operationId: get_variables
export def "variables list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a variable
#
# POST /variables
# operationId: post_variables
export def "variables create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the variable. *New in version 2.4.0* (nullable)
  --key: string
  --value: string
]: any -> record<description: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/variables")
  let req_body = {"description": $description, "key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a variable
#
# DELETE /variables/{variable_key}
# operationId: delete_variable
export def "variables delete" [
  variable_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_key: (encode-path-segment $variable_key)} | format pattern "/variables/{variable_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a variable
#
# GET /variables/{variable_key}
# operationId: get_variable
export def "variables get" [
  variable_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({variable_key: (encode-path-segment $variable_key)} | format pattern "/variables/{variable_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a variable
#
# PATCH /variables/{variable_key}
# operationId: patch_variable
export def "variables update" [
  variable_key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --description: string # The description of the variable. *New in version 2.4.0* (nullable)
  --key: string
  --value: string
]: any -> record<description: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "update_mask" $update_mask "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({variable_key: (encode-path-segment $variable_key)} | format pattern "/variables/{variable_key}") $qp)
  let req_body = {"description": $description, "key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get version information
#
# GET /version
# operationId: get_version
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<git_version: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
