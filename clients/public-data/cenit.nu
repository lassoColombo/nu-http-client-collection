# Auto-generated client for Cenit IO - REST API Specification vv1
# Source: https://api.apis.guru/v2/specs/cenit.io/v1/swagger.json
# Auth: --token flag or $env.CENIT_IO_REST_API_SPECIFICATION_TOKEN

const BASE_URL = "https://cenit.io/api/v1"
const DEFAULT_AUTH = "x-user-access-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CENIT_IO_REST_API_SPECIFICATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-user-access-key" => { {headers: {X-User-Access-Key: $token_val}, query: ""} }
    "x-user-access-token" => { {headers: {X-User-Access-Token: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://cenit.io/api/v1"] }
def auth-scheme-completer [] { ["x-user-access-key" "x-user-access-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "setup-connection list" } } | get name | first)
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

# Returns a list of connections
#
# GET /setup/connection
export def "setup-connection list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<headers: list<record>, id: string, key: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, token: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a connection
#
# POST /setup/connection
export def "setup-connection post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, key: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, token: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a connection
#
# DELETE /setup/connection/{id}
export def "setup-connection delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/connection/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing connection
#
# GET /setup/connection/{id}
export def "setup-connection get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, key: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, token: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/connection/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of connection roles
#
# GET /setup/connection_role
export def "setup-connection-role list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<connection: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection_role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a connection role
#
# POST /setup/connection_role
export def "setup-connection-role post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connection: table<headers: list, id: string, key: string, name: string, namespace: record, parameters: list, token: string, url: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: table<headers: list, id: string, name: string, namespace: record, parameters: list, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection_role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a connection role.
#
# DELETE /setup/connection_role/{id}
export def "setup-connection-role delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/connection_role/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a connection role
#
# GET /setup/connection_role/{id}
export def "setup-connection-role get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connection: table<headers: list, id: string, key: string, name: string, namespace: record, parameters: list, token: string, url: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: table<headers: list, id: string, name: string, namespace: record, parameters: list, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/connection_role/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of data types
#
# GET /setup/data_type/
export def "setup-data-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/data_type/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a data type
#
# POST /setup/data_type/
export def "setup-data-type post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/data_type/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a data type
#
# DELETE /setup/data_type/{id}
export def "setup-data-type delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/data_type/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a data type
#
# GET /setup/data_type/{id}
export def "setup-data-type get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/data_type/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of flows
#
# GET /setup/flow/
export def "setup-flow list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, connection_role: record<connection: list, id: string, name: string, namespace: record, webhook: list>, custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, event: record, id: string, name: string, namespace: record<id: string, name: string, slug: string>, notify_request: bool, notify_response: bool, response_translator: record<custom_data_type: record, id: string, name: string, namespace: record, source_data_type: record, style: string, target_data_type: record, transformation: string, type: string>, translator: record<custom_data_type: record, id: string, name: string, namespace: record, source_data_type: record, style: string, target_data_type: record, transformation: string, type: string>, webhook: record<headers: list, id: string, name: string, namespace: record, parameters: list, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/flow/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a flow
#
# POST /setup/flow/
export def "setup-flow post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, connection_role: record<connection: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: list<record>>, custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, event: record, id: string, name: string, namespace: record<id: string, name: string, slug: string>, notify_request: bool, notify_response: bool, response_translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, webhook: record<headers: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/flow/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a flow.
#
# DELETE /setup/flow/{id}
export def "setup-flow delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/flow/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing flow
#
# GET /setup/flow/{id}
export def "setup-flow get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, connection_role: record<connection: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: list<record>>, custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, event: record, id: string, name: string, namespace: record<id: string, name: string, slug: string>, notify_request: bool, notify_response: bool, response_translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, webhook: record<headers: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/flow/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of namespaces
#
# GET /setup/namespace/
export def "setup-namespace list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/namespace/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a namespace
#
# POST /setup/namespace/
export def "setup-namespace post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/namespace/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a namespace
#
# DELETE /setup/namespace/{id}
export def "setup-namespace delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/namespace/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing namespace
#
# GET /setup/namespace/{id}
export def "setup-namespace get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/namespace/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of events
#
# GET /setup/observer/
export def "setup-observer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, triggers: string, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/observer/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an event
#
# POST /setup/observer/
export def "setup-observer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, triggers: string, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/observer/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an event
#
# DELETE /setup/observer/{id}
export def "setup-observer delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/observer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing event
#
# GET /setup/observer/{id}
export def "setup-observer get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, triggers: string, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/observer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of schedulers
#
# GET /setup/scheduler/
export def "setup-scheduler list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<activated: bool, expression: string, id: string, name: string, namespace: record<id: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/scheduler/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an scheduler
#
# POST /setup/scheduler/
export def "setup-scheduler post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activated: bool, expression: string, id: string, name: string, namespace: record<id: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/scheduler/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an schedule
#
# DELETE /setup/scheduler/{id}
export def "setup-scheduler delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/scheduler/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing schedule
#
# GET /setup/scheduler/{id}
export def "setup-scheduler get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activated: bool, expression: string, id: string, name: string, namespace: record<id: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/scheduler/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of schemas
#
# GET /setup/schema/
export def "setup-schema list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, namespace: record<id: string, name: string, slug: string>, schema: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/schema/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an schema
#
# POST /setup/schema/
export def "setup-schema post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, namespace: record<id: string, name: string, slug: string>, schema: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/schema/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an schema.
#
# DELETE /setup/schema/{id}
export def "setup-schema delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/schema/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing schema
#
# GET /setup/schema/{id}
export def "setup-schema get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, namespace: record<id: string, name: string, slug: string>, schema: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/schema/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of translators
#
# GET /setup/translator/
export def "setup-translator list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/translator/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a translator
#
# POST /setup/translator/
export def "setup-translator post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/translator/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a translator
#
# DELETE /setup/translator/{id}
export def "setup-translator delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/translator/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing translator
#
# GET /setup/translator/{id}
export def "setup-translator get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/translator/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of webhooks
#
# GET /setup/webhook/
export def "setup-webhook list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<headers: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/webhook/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a webhook
#
# POST /setup/webhook/
export def "setup-webhook post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/webhook/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a webhook
#
# DELETE /setup/webhook/{id}
export def "setup-webhook delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/webhook/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing webhook
#
# GET /setup/webhook/{id}
export def "setup-webhook get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-user-access-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/webhook/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
