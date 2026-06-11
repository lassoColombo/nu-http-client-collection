# Auto-generated client for ThreatJammer.com User API v1.2.20
# Source: https://api.apis.guru/v2/specs/threatjammer.com/1.2.20/openapi.json
# Auth: --token flag or $env.THREATJAMMER_COM_USER_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THREATJAMMER_COM_USER_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["ACTIVE" "DELETED" "INACTIVE"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE"] }
def ip-protocol-version-completer [] { ["ALL" "IPV4" "IPV6"] }
def output-format-completer [] { ["AWS-WAF" "CSV" "JSON"] }
def interval-completer [] { ["HOURLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "allowlist-private post" } } | get name | first)
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

# Creates a new private allowlist binded to the user.
#
# POST /v1/allowlist/private
# operationId: create_private_allowlist_of_the_user_v1_allowlist_private_post
export def "allowlist-private post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payload: any # The information needed to create a new allowlist
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/allowlist/private")
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the set of private allowlists of the user.
#
# GET /v1/allowlist/private/all
# operationId: get_all_private_allowlists_v1_allowlist_private_all_get
export def "allowlist-private-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/allowlist/private/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of private allowlists of the user by resource type.
#
# GET /v1/allowlist/private/all/{resource_type}
# operationId: get_all_private_allowlists_by_resource_type_v1_allowlist_private_all__resource_type__get
export def "allowlist-private-all get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/all/($resource_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the different private allowlists where the IP address was found.
#
# GET /v1/allowlist/private/ip/{address}
# operationId: query_resource_denylists_v1_allowlist_private_ip__address__get
export def "allowlist-private-ip get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/ip/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all the bindings between a user and a private allowlist.
#
# DELETE /v1/allowlist/private/{allowlist_id}
# operationId: delete_the_allowlist_v1_allowlist_private__allowlist_id__delete
export def "allowlist-private delete" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of a specific private allowlist of the user.
#
# GET /v1/allowlist/private/{allowlist_id}
# operationId: get_single_allowlist_v1_allowlist_private__allowlist_id__get
export def "allowlist-private get" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: string, created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, tags: list<string>, ttl: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the information of an existing private allowlist of the user.
#
# PUT /v1/allowlist/private/{allowlist_id}
# operationId: update_private_allowlist_of_the_user_v1_allowlist_private__allowlist_id__put
export def "allowlist-private put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The human readable full description of the list
  --name: string # The name of the list
  --tags: list # The list of tags to associate with the list
  --ttl: int # Optional. The Time To Live (TTL) of a resource in the list in seconds.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)")
  let body = {description: $description, name: $name, tags: $tags, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all the content of a private allowlist of the user.
#
# DELETE /v1/allowlist/private/{allowlist_id}/content
# operationId: delete_the_allowlist_content_v1_allowlist_private__allowlist_id__content_delete
export def "allowlist-private-content delete" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the content of a private allowlist of the user.
#
# GET /v1/allowlist/private/{allowlist_id}/content
# operationId: get_allowlist_content_v1_allowlist_private__allowlist_id__content_get
export def "allowlist-private-content get" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asns: list<int>, cidrs: list<any>, continents: list<string>, countries: list<string>, datacenters: list<string>, self: string, user_agents: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove content of a private allowlist of the user.
#
# PUT /v1/allowlist/private/{allowlist_id}/content
# operationId: update_private_content_of_the_allowlist_of_the_user_v1_allowlist_private__allowlist_id__content_put
export def "allowlist-private-content put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --append: list # The name of the resources to append to the allowlist
  --remove: list # The name of the resources to remove from the allowlist
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)/content")
  let body = {append: $append, remove: $remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toogle the status of the origin in an allow list.
#
# PUT /v1/allowlist/private/{allowlist_id}/origin
# operationId: change_status_of_the_origin_allowlist_v1_allowlist_private__allowlist_id__origin_put
export def "allowlist-private-origin put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/private/($allowlist_id)/origin")
  let body = {origin: $origin, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the set of public allowlists.
#
# GET /v1/allowlist/public/all
# operationId: get_all_public_allowlists_v1_allowlist_public_all_get
export def "allowlist-public-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/allowlist/public/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of public allowlists by resource type.
#
# GET /v1/allowlist/public/all/{resource_type}
# operationId: get_all_public_allowlists_by_resource_type_v1_allowlist_public_all__resource_type__get
export def "allowlist-public-all get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/all/($resource_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the different public allowlists where the IP address was found.
#
# GET /v1/allowlist/public/ip/{address}
# operationId: query_resource_allowlists_v1_allowlist_public_ip__address__get
export def "allowlist-public-ip get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/ip/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of owned allowlists.
#
# GET /v1/allowlist/public/owned
# operationId: get_public_allowlists_owned_by_the_user_v1_allowlist_public_owned_get
export def "allowlist-public-owned list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/allowlist/public/owned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of public allowlists of a user by resource type.
#
# GET /v1/allowlist/public/owned/{resource_type}
# operationId: get_all_owned_allowlists_by_resource_type_v1_allowlist_public_owned__resource_type__get
export def "allowlist-public-owned get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/owned/($resource_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all the bindings between a user and an allowlist.
#
# DELETE /v1/allowlist/public/{allowlist_id}
# operationId: delete_the_allowlist_v1_allowlist_public__allowlist_id__delete
export def "allowlist-public delete" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/($allowlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of the allowlist.
#
# GET /v1/allowlist/public/{allowlist_id}
# operationId: get_single_allowlist_v1_allowlist_public__allowlist_id__get
export def "allowlist-public get" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, status: string, tags: list<string>, ttl: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/($allowlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toogle the status of an allow list.
#
# PUT /v1/allowlist/public/{allowlist_id}
# operationId: change_status_of_the_allowlist_v1_allowlist_public__allowlist_id__put
export def "allowlist-public put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer-1 # The status of the list. ACTIVE or INACTIVE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/($allowlist_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toogle the status of the origin in an allow list.
#
# PUT /v1/allowlist/public/{allowlist_id}/origin
# operationId: change_status_of_the_origin_allowlist_v1_allowlist_public__allowlist_id__origin_put
export def "allowlist-public-origin put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/allowlist/public/($allowlist_id)/origin")
  let body = {origin: $origin, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the IPv4 or IPv6 prefix of the IP address given.
#
# GET /v1/asn/ip/{ip_address}
# operationId: query_IP_address_network_information_v1_asn_ip__ip_address__get
export def "asn-ip get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/asn/ip/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the IPv4 or IPv6 prefix of the CIDR given.
#
# POST /v1/asn/prefix
# operationId: query_asn_prefix_information_v1_asn_prefix_post
export def "asn-prefix post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prefix: string # format: ipvanynetwork
]: any -> record<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/asn/prefix")
  let body = {prefix: $prefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of the Regional Internet Registries (RIRs) entities worldwide.
#
# GET /v1/asn/registry/all
# operationId: query_registry_names_v1_asn_registry_all_get
export def "asn-registry-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<code: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/asn/registry/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of a Regional Internet Registries (RIRs) given.
#
# GET /v1/asn/registry/{code}
# operationId: query_registry_by_the_name_v1_asn_registry__code__get
export def "asn-registry get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/asn/registry/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of status of an object in a registry.
#
# GET /v1/asn/status/all
# operationId: query_status_names_v1_asn_status_all_get
export def "asn-status-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<code: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/asn/status/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of a status given.
#
# GET /v1/asn/status/{code}
# operationId: query_status_by_the_name_v1_asn_status__code__get
export def "asn-status get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, name: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/asn/status/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Autonomous System details of the AS number given.
#
# GET /v1/asn/{number}
# operationId: query_asn_v1_asn__number__get
export def "asn get" [
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<country_code: string, description: string, name: string, prefixes: string, registry: string, registry_date: string, risk: string, score: int, self: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/asn/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of IPv4 and IPv6 prefixes of the AS number given.
#
# GET /v1/asn/{number}/prefixes
# operationId: query_asn_prefixes_list_v1_asn__number__prefixes_get
export def "asn-prefixes get" [
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asn: string, prefixes_v4: table<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>, prefixes_v6: table<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/asn/($number)/prefixes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the risk score of all IP address passed in the body and other data signals.
#
# POST /v1/assess/ip
# operationId: assess_ip_set_v1_assess_ip_post
export def "assess-ip post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<results: table<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list, denylisted: string, first_appearance: list, last_appearance: list, reason: string, risk: string, score: int, self: string, sources: list>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/assess/ip")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the risk score of all IP address uploaded and other data signals.
#
# POST /v1/assess/ip/csv
# operationId: assess_ip_set_csv_v1_assess_ip_csv_post
export def "assess-ip-csv post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strict-parse: string@bool-completer # When `true`, if any IP address entry in the file is malformed, the assessment is canceled. If `false`, the malformed IP addresses are ignored. Default is `false`. (default: false)
  csv_file: string # The CSV file with the IP addresses (format: binary)
]: any -> record<results: table<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list, denylisted: string, first_appearance: list, last_appearance: list, reason: string, risk: string, score: int, self: string, sources: list>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "strict_parse" $strict_parse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/assess/ip/csv" $qp)
  let body = {csv_file: $csv_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a risk score of the IP address and different data signals.
#
# GET /v1/assess/ip/{ip_address}
# operationId: assess_ip_v1_assess_ip__ip_address__get
export def "assess-ip get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list<string>, denylisted: string, first_appearance: list<string>, last_appearance: list<string>, reason: string, risk: string, score: int, self: string, sources: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/assess/ip/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the IPv4 or IPv6 prefix of the IP address given.
#
# GET /v1/datacenter/ip/{ip_address}
# operationId: query_IP_address_network_information_v1_datacenter_ip__ip_address__get
export def "datacenter-ip get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/datacenter/ip/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the IPv4 or IPv6 prefix of the CIDR given.
#
# POST /v1/datacenter/prefix
# operationId: query_datacenter_prefix_information_v1_datacenter_prefix_post
export def "datacenter-prefix post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prefix: string # format: ipvanynetwork
]: any -> record<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/datacenter/prefix")
  let body = {prefix: $prefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the Datacenter details of datacente given.
#
# GET /v1/datacenter/{datacenter_id}
# operationId: query_datacenter_v1_datacenter__datacenter_id__get
export def "datacenter get" [
  datacenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asn: string, description: string, name: string, prefixes: string, risk: string, score: int, self: string, source: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/datacenter/($datacenter_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of IPv4 and IPv6 prefixes of the Datacenter given.
#
# GET /v1/datacenter/{datacenter_id}/prefixes
# operationId: query_datacenter_prefixes_list_v1_datacenter__datacenter_id__prefixes_get
export def "datacenter-prefixes get" [
  datacenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<prefixes_v4: table<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>, prefixes_v6: table<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/datacenter/($datacenter_id)/prefixes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of all the datasets available in the platform.
#
# GET /v1/dataset/ip
# operationId: query_datataset_information_of_all_the_resource_types_v1_dataset_ip_get
export def "dataset-ip list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<self: string, types: table<description: string, items: int, name: string, self: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dataset/ip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the detailed information of the dataset queried.
#
# GET /v1/dataset/ip/{name}
# operationId: query_datataset_information_of_the_resource_type_v1_dataset_ip__name__get
export def "dataset-ip get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, items: int, name: string, self: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dataset/ip/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new private denylist binded to the user.
#
# POST /v1/denylist/private
# operationId: create_private_denylist_of_the_user_v1_denylist_private_post
export def "denylist-private post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payload: any # The information needed to create a new denylist
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/denylist/private")
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the set of private denylists of the user.
#
# GET /v1/denylist/private/all
# operationId: get_all_private_denylists_v1_denylist_private_all_get
export def "denylist-private-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/denylist/private/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of private denylists of the user by resource type.
#
# GET /v1/denylist/private/all/{resource_type}
# operationId: get_all_private_denylists_by_resource_type_v1_denylist_private_all__resource_type__get
export def "denylist-private-all get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/all/($resource_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the different denylists where the IP address was found.
#
# GET /v1/denylist/private/ip/{address}
# operationId: query_resource_denylists_v1_denylist_private_ip__address__get
export def "denylist-private-ip get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/ip/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all the bindings between a user and a private denylist.
#
# DELETE /v1/denylist/private/{denylist_id}
# operationId: delete_the_denylist_v1_denylist_private__denylist_id__delete
export def "denylist-private delete" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of a specific private denylist of the user.
#
# GET /v1/denylist/private/{denylist_id}
# operationId: get_single_denylist_v1_denylist_private__denylist_id__get
export def "denylist-private get" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: string, created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, tags: list<string>, ttl: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the information of an existing private denylist of the user.
#
# PUT /v1/denylist/private/{denylist_id}
# operationId: update_private_denylist_of_the_user_v1_denylist_private__denylist_id__put
export def "denylist-private put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The human readable full description of the list
  --name: string # The name of the list
  --tags: list # The list of tags to associate with the list
  --ttl: int # Optional. The Time To Live (TTL) of a resource in the list in seconds.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)")
  let body = {description: $description, name: $name, tags: $tags, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all the content of a private denylist of the user.
#
# DELETE /v1/denylist/private/{denylist_id}/content
# operationId: delete_the_denylist_content_v1_denylist_private__denylist_id__content_delete
export def "denylist-private-content delete" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the content of a private denylist of the user.
#
# GET /v1/denylist/private/{denylist_id}/content
# operationId: get_denylist_content_v1_denylist_private__denylist_id__content_get
export def "denylist-private-content get" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asns: list<int>, cidrs: list<any>, continents: list<string>, countries: list<string>, datacenters: list<string>, self: string, user_agents: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove content of a private denylist of the user.
#
# PUT /v1/denylist/private/{denylist_id}/content
# operationId: update_private_content_of_the_denylist_of_the_user_v1_denylist_private__denylist_id__content_put
export def "denylist-private-content put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --append: list # The name of the resources to append to the denylist
  --remove: list # The name of the resources to remove from the denylist
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)/content")
  let body = {append: $append, remove: $remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toogle the status of the origin in a deny list.
#
# PUT /v1/denylist/private/{denylist_id}/origin
# operationId: change_status_of_the_origin_denylist_v1_denylist_private__denylist_id__origin_put
export def "denylist-private-origin put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/private/($denylist_id)/origin")
  let body = {origin: $origin, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the set of public denylists.
#
# GET /v1/denylist/public/all
# operationId: get_all_public_denylists_v1_denylist_public_all_get
export def "denylist-public-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/denylist/public/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of public denylists by resource type.
#
# GET /v1/denylist/public/all/{resource_type}
# operationId: get_all_public_denylists_by_resource_type_v1_denylist_public_all__resource_type__get
export def "denylist-public-all get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/all/($resource_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the different public denylists where the IP address was found.
#
# GET /v1/denylist/public/ip/{address}
# operationId: query_resource_denylists_v1_denylist_public_ip__address__get
export def "denylist-public-ip get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/ip/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of owned denylists.
#
# GET /v1/denylist/public/owned
# operationId: get_public_denylists_owned_by_the_user_v1_denylist_public_owned_get
export def "denylist-public-owned list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/denylist/public/owned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the set of public denylists of a user by resource type.
#
# GET /v1/denylist/public/owned/{resource_type}
# operationId: get_all_owned_denylists_by_resource_type_v1_denylist_public_owned__resource_type__get
export def "denylist-public-owned get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/owned/($resource_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all the bindings between a user and an denylist.
#
# DELETE /v1/denylist/public/{denylist_id}
# operationId: delete_the_denylist_v1_denylist_public__denylist_id__delete
export def "denylist-public delete" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/($denylist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of the denylist.
#
# GET /v1/denylist/public/{denylist_id}
# operationId: get_single_denylist_v1_denylist_public__denylist_id__get
export def "denylist-public get" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, status: string, tags: list<string>, ttl: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/($denylist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toogle the status of an deny list.
#
# PUT /v1/denylist/public/{denylist_id}
# operationId: change_status_of_the_denylist_v1_denylist_public__denylist_id__put
export def "denylist-public put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer-1 # The status of the list. ACTIVE or INACTIVE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/($denylist_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toogle the status of the origin in a deny list.
#
# PUT /v1/denylist/public/{denylist_id}/origin
# operationId: change_status_of_the_origin_denylist_v1_denylist_public__denylist_id__origin_put
export def "denylist-public-origin put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/public/($denylist_id)/origin")
  let body = {origin: $origin, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of automatically reported IP addresses by the user.
#
# GET /v1/denylist/reported/ip
# operationId: query_all_the_ip_addresses_reported_by_the_user_v1_denylist_reported_ip_get
export def "denylist-reported-ip list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The dataset list type to filter for. Must be uppercase, numbers and underscore
  --reported-before: int # Restricts the result displaying only the IP addresses reported before `reported_before`. It must be a UNIX timestamp in seconds.
  --reported-after: int # Restricts the result displaying only the IP addresses reported after `reported_after`. It must be a UNIX timestamp in seconds.
  --expires-before: int # Restricts the result displaying only the IP addresses that will expire before `expires_before`. It must be a UNIX timestamp in seconds greater than the current UNIX timestamp.
  --expires-after: int # Restricts the result displaying only the IP addresses that will expire after `expires_after`. It must be a UNIX timestamp in seconds greater than the current UNIX timestamp.
  --greater-than: int # Restricts the result displaying only the IP addresses reported more times than `greater_than`. It must be an integer greater than 0.
  --less-than: int # Restricts the result displaying only the IP addresses reported less times than `less_than`. It must be an integer greater than 1.
  --ip-protocol-version: string@ip-protocol-version-completer # Restrict the result displaying the IP protocol version requested (IPV4 or IPV6) or both (ALL). Some output formats MUST filter by IP protocol version first. (default: ALL)
  --output-format: string@output-format-completer # The output format of the datasets. (default: JSON)
]: nothing -> record<addresses: table<dataset: string, expiry: int, last_report: int, protocol: string, self: string, tags: list, total_reports: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "reported_before" $reported_before "scalar") (serialize-qp "reported_after" $reported_after "scalar") (serialize-qp "expires_before" $expires_before "scalar") (serialize-qp "expires_after" $expires_after "scalar") (serialize-qp "greater_than" $greater_than "scalar") (serialize-qp "less_than" $less_than "scalar") (serialize-qp "ip_protocol_version" $ip_protocol_version "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/denylist/reported/ip" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all the automatically reported IP addresses by the user.
#
# DELETE /v1/denylist/reported/ip/all
# operationId: delete_all_ip_addresses_reported_by_the_user_v1_denylist_reported_ip_all_delete
export def "denylist-reported-ip-all delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/denylist/reported/ip/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the automatically reported IP address by the user.
#
# DELETE /v1/denylist/reported/ip/{ip_address}
# operationId: delete_an_ip_address_reported_by_the_user_v1_denylist_reported_ip__ip_address__delete
export def "denylist-reported-ip delete" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/reported/ip/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of an automatically reported IP addresses by the user.
#
# GET /v1/denylist/reported/ip/{ip_address}
# operationId: query_an_ip_addresses_reported_by_the_user_v1_denylist_reported_ip__ip_address__get
export def "denylist-reported-ip get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dataset: string, expiry: int, last_report: int, protocol: string, self: string, tags: list<string>, total_reports: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/denylist/reported/ip/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the geolocation data of the IP addresses set.
#
# POST /v1/geo
# operationId: geolocate_ip_set_v1_geo_post
export def "geo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<results: table<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/geo")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the geolocation data of all the IP addresses uploaded.
#
# POST /v1/geo/csv
# operationId: assess_ip_set_csv_v1_geo_csv_post
export def "geo-csv post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strict-parse: string@bool-completer # When `true`, if any IP address entry in the file is malformed, the assessment is canceled. If `false`, the malformed IP addresses are ignored. Default is `false`. (default: false)
  csv_file: string # The CSV file with the IP addresses (format: binary)
]: any -> record<results: table<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "strict_parse" $strict_parse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/geo/csv" $qp)
  let body = {csv_file: $csv_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get the geo location data of the IP address.
#
# GET /v1/geo/{ip_address}
# operationId: geolocate_ip_v1_geo__ip_address__get
export def "geo get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list<string>, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/geo/($ip_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a log event.
#
# GET /v1/log/ip/id/{logchange_id}
# operationId: log_change_id_v1_log_ip_id__logchange_id__get
export def "log-ip-id get" [
  logchange_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: string, cidr: string, dataset: string, lapse: string, risk: string, score: int, self: string, source: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/log/ip/id/($logchange_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the changes logged in the different datasets of an IP address.
#
# GET /v1/log/ip/{ip_address}
# operationId: logchanges_ip_v1_log_ip__ip_address__get
export def "log-ip get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string # The name of the dataset to restrict the query
  --logged-after: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged after this value.
]: nothing -> record<logs: table<action: string, cidr: string, dataset: string, lapse: string, risk: string, score: int, self: string, source: string, timestamp: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "logged_after" $logged_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/log/ip/($ip_address)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of an origin of the user in the region.
#
# GET /v1/origin
# operationId: query_origin_information_v1_origin_get
export def "origin get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
]: nothing -> record<actions: string, addresses: string, config: record, cookies: string, created_at: int, logs: string, origin: string, scripts: string, self: string, status: string, token: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the configuration of an origin of the user in the region.
#
# PUT /v1/origin
# operationId: update_configuration_origin_v1_origin_put
export def "origin put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # The configuration information to store in the origin.
  origin: string # The origin site to modify the configruation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin")
  let body = {config: $config, origin: $origin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the address status of the origin of the user in the region.
#
# GET /v1/origin/addresses
# operationId: query_origin_address_status_information_v1_origin_addresses_get
export def "origin-addresses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
  --page: int # The page to be returned (default: 1)
  --page-size: int # The number of items per page (default: 20)
]: nothing -> record<addresses: table<address: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, page: int, page_size: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the origins of the user in the region.
#
# GET /v1/origin/all
# operationId: query_all_origin_information_v1_origin_all_get
export def "origin-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<origins: table<actions: string, addresses: string, config: record, cookies: string, created_at: int, logs: string, origin: string, scripts: string, self: string, status: string, token: string, updated_at: int>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the type of clients of the trafffic of the origin.
#
# GET /v1/origin/client/analysis
# operationId: query_origin_traffic_client_v1_origin_client_analysis_get
export def "origin-client-analysis get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
  --interval: string@interval-completer # The data inteval to aggregate the result dataset
  --from-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged after or equal to this value.
  --to-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged before this value.
]: nothing -> record<data: table<client_browser: int, client_crawler: int, client_email: int, client_library: int, client_mobile_browser: int, client_multimedia_player: int, client_offline_browser: int, client_total: int, client_ua_anonymizer: int, client_unrecognized: int, client_validator: int, client_wap_browser: int, crawler_feed_fetcher: int, crawler_link_checker: int, crawler_marketing: int, crawler_screenshot_creator: int, crawler_search_engine_bot: int, crawler_site_monitor: int, crawler_speed_tester: int, crawler_tool: int, crawler_total: int, crawler_uncategorised: int, crawler_unrecognized: int, crawler_virus_scanner: int, crawler_vulnerability_scanner: int, crawler_web_scraper: int, timestamp: int, total: int>, from_timestamp: int, interval: string, self: string, to_timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "from_timestamp" $from_timestamp "scalar") (serialize-qp "to_timestamp" $to_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin/client/analysis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the tracking cookie ID status of the origin of the user in the region.
#
# GET /v1/origin/cookies
# operationId: query_origin_cookie_id_status_information_v1_origin_cookies_get
export def "origin-cookies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
  --page: int # The page to be returned (default: 1)
  --page-size: int # The number of items per page (default: 20)
]: nothing -> record<cookie_ids: table<cookie_id: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, page: int, page_size: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin/cookies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the code snippets of an origin of the user in the region.
#
# GET /v1/origin/scripts
# operationId: query_origin_scripts_v1_origin_scripts_get
export def "origin-scripts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
]: nothing -> record<detection: string, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin/scripts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current cookie ID and IP address status of the origin of user in the region.
#
# POST /v1/origin/status
# operationId: query_origin_status_v1_origin_status_post
export def "origin-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
  --address: any # The IP address to query the status
  --cookie-id: string # The cookie id to query the status (format: uuid)
]: any -> record<address: record<address: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, cookie_id: record<cookie_id: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin/status" $qp)
  let body = {address: $address, cookie_id: $cookie_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get detail of a status available in the platform.
#
# GET /v1/origin/status/detail/{status_id}
# operationId: query_origin_status_detail_v1_origin_status_detail__status_id__get
export def "origin-status-detail get" [
  status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cardinality: int, description: string, self: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/origin/status/detail/($status_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of different status available in the platform.
#
# GET /v1/origin/status/details
# operationId: query_origin_status_details_v1_origin_status_details_get
export def "origin-status-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<list: table<cardinality: int, description: string, self: string, status: string>, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin/status/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the traffic analysis of the origin.
#
# GET /v1/origin/traffic/analysis
# operationId: query_origin_traffic_analysis_v1_origin_traffic_analysis_get
export def "origin-traffic-analysis get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The origin site to query
  --interval: string@interval-completer # The data inteval to aggregate the result dataset
  --from-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged after or equal to this value.
  --to-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged before this value.
]: nothing -> record<data: table<asn_risky: int, bots: int, datacenters: int, denylists: int, network_country_mismatches: int, score_high: int, timestamp: int, total: int, webdrivers: int>, from_timestamp: int, interval: string, self: string, to_timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "from_timestamp" $from_timestamp "scalar") (serialize-qp "to_timestamp" $to_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/origin/traffic/analysis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an origin token of the user in the region.
#
# DELETE /v1/origin_token
# operationId: delete_token_v1_origin_token_delete
export def "origin-token delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin_token_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin_token")
  let body = {origin_token_id: $origin_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the information of an origin token of the user in the region.
#
# POST /v1/origin_token
# operationId: query_origin_token_info_v1_origin_token_post
export def "origin-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin_token_id: string
]: any -> record<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin_token")
  let body = {origin_token_id: $origin_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the information of the origin tokens of the user in the region.
#
# GET /v1/origin_token/all
# operationId: query_all_origin_tokens_in_the_region_v1_origin_token_all_get
export def "origin-token-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<self: string, tokens: table<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin_token/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable a enabled origin token of the user in the region.
#
# PUT /v1/origin_token/disable
# operationId: disable_origin_token_v1_origin_token_disable_put
export def "origin-token-disable put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin_token_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin_token/disable")
  let body = {origin_token_id: $origin_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable a disabled origin token of the user in the region.
#
# PUT /v1/origin_token/enable
# operationId: enable_origin_token_v1_origin_token_enable_put
export def "origin-token-enable put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin_token_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin_token/enable")
  let body = {origin_token_id: $origin_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an origin token of the user in the region.
#
# POST /v1/origin_token/new
# operationId: create_a_new_origin_token_v1_origin_token_new_post
export def "origin-token-new post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin: string
]: any -> record<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/origin_token/new")
  let body = {origin: $origin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the full information of all the source lists for the subscription level given.
#
# GET /v1/source/ip
# operationId: get_all_sources_v1_source_ip_get
export def "source-ip list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<self: string, sources: table<dataset: string, description: string, maximum_risk: string, maximum_score: int, minimum_risk: string, minimum_score: int, name: string, refresh: string, self: string, source: string, time_ranges: list, updated_at: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/source/ip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the full information of the source list given as argument.
#
# GET /v1/source/ip/{source}
# operationId: get_source_info_v1_source_ip__source__get
export def "source-ip get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dataset: string, description: string, maximum_risk: string, maximum_score: int, minimum_risk: string, minimum_score: int, name: string, refresh: string, self: string, source: string, time_ranges: list<string>, updated_at: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/source/ip/($source)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the source list given for a specific time range.
#
# GET /v1/source/ip/{source}/range/{time_range}
# operationId: get_source_and_timerange_info_v1_source_ip__source__range__time_range__get
export def "source-ip-range get" [
  source: string
  time_range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: int, lapse: string, risk: string, score: int, self: string, source: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/source/ip/($source)/range/($time_range)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the user's token in the region.
#
# GET /v1/token
# operationId: query_token_info_v1_token_get
export def "token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: int, last_minute_bucket_init_value: int, last_minute_bucket_refill_ratio: int, last_minute_bucket_refresh: int, last_minute_bucket_value: int, last_month_bucket_init_value: int, last_month_bucket_refresh: int, last_month_bucket_value: int, region_id: string, self: string, status: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the activity information of the token in the region.
#
# GET /v1/token/activity
# operationId: query_token_activity_v1_token_activity_get
export def "token-activity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page to be returned (default: 1)
  --page-size: int # The number of items per page (default: 20)
]: nothing -> record<activities: table<created_at: int, data: record, description: string, event: string, self: string, source: record>, page: int, page_size: int, self: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/token/activity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information found in a set of User Agents.
#
# POST /v1/ua
# operationId: parse_user_agents_v1_ua_post
export def "ua post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<results: table<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ua")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the information found in the set of User Agents uploaded.
#
# POST /v1/ua/csv
# operationId: parse_user_agents_csv_v1_ua_csv_post
export def "ua-csv post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  csv_file: string # The CSV file with the User Agents to parse (format: binary)
]: any -> record<results: table<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>, self: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ua/csv")
  let body = {csv_file: $csv_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get the information of the device of a user agent.
#
# GET /v1/ua/device/{code}
# operationId: query_device_by_code_v1_ua_device__code__get
export def "ua-device get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ua/device/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the family of a user agent.
#
# GET /v1/ua/family/{code}
# operationId: query_family_by_code_v1_ua_family__code__get
export def "ua-family get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ua/family/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the Operating System of a user agent.
#
# GET /v1/ua/os/{code}
# operationId: query_os_by_code_v1_ua_os__code__get
export def "ua-os get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, description: string, family: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ua/os/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the type of a user agent.
#
# GET /v1/ua/type/{code}
# operationId: query_type_by_code_v1_ua_type__code__get
export def "ua-type get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, description: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ua/type/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information of the vendor of a user agent.
#
# GET /v1/ua/vendor/{code}
# operationId: query_vendor_by_code_v1_ua_vendor__code__get
export def "ua-vendor get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ua/vendor/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the information found in an User Agent.
#
# GET /v1/ua/{user_agent_urlencoded}
# operationId: parse_user_agent_v1_ua__user_agent_urlencoded__get
export def "ua get" [
  user_agent_urlencoded: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ua/($user_agent_urlencoded)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
