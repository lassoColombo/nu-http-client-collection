# Auto-generated client for Budgea API Documentation v2.0
# Source: https://api.apis.guru/v2/specs/biapi.pro/2.0/openapi.json
# Auth: --token flag or $env.BUDGEA_API_DOCUMENTATION_TOKEN

const BASE_URL = "http://localhost//budgea.biapi.pro/2.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUDGEA_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost//budgea.biapi.pro/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "jwt_token" "payload"] }
def accept-completer-1 [] { ["application/json" "auth_token" "expires_in" "type"] }
def accept-completer-2 [] { ["access_token" "application/json" "token_type"] }
def accept-completer-3 [] { ["application/json" "profile" "scope" "token" "user"] }
def accept-completer-4 [] { ["access" "application/json" "code" "expires_in" "type"] }
def accept-completer-5 [] { ["application/json" "failed" "total" "transactions"] }
def accept-completer-6 [] { ["application/json" "auth_mechanism" "beta" "capabilities" "categories" "charged" "code" "color" "hidden" "id" "name" "slug" "sync_frequency"] }
def accept-completer-7 [] { ["application/json" "biapi.last_push"] }
def accept-completer-8 [] { ["application/json" "compagny" "owner"] }
def accept-completer-9 [] { ["application/json" "token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-types list" } } | get name | first)
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

# Get account types
#
# GET /account_types
export def "account-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<accounttypes: table<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an account type
#
# GET /account_types/{id_account_type}
export def "account-types get" [
  id_account_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_account_type: (encode-path-segment $id_account_type)} | format pattern "/account_types/{id_account_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a jwt manage token
#
# POST /admin/jwt
export def "admin-jwt create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --duration: int # number of minute before the token expiration (0 for token that won't expire unless the client application is deleted) (default: 1)
  --scope: string # scope requested for the token (default: config)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/jwt")
  let req_body = {"duration": $duration, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Create a new anonymous user
#
# POST /auth/init
export def "auth-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --client-id: string # ID of the client
  --client-secret: string # secret of the client
]: any -> record<auth_token: string, expires_in: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/init")
  let req_body = {"client_id": $client_id, "client_secret": $client_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Generate a user jwt token
#
# POST /auth/jwt
export def "auth-jwt create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # id of the client
  --client-secret: string # secret for the client
  --expire: oneof<nothing, bool> # if set to True, the token will expire n minutes after its creation, n being the value of configuration key auth.default_token_expire (default: True)
  --id-user: int # user for whom the token has to be generated. If not supplied, a user will be created
  --scope: string # scope requested for the token
]: any -> record<jwt_token: string, payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt")
  let req_body = {"client_id": $client_id, "client_secret": $client_secret, "expire": $expire, "id_user": $id_user, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get a new access token given an user id and client credentials
#
# POST /auth/renew
export def "auth-renew create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  client_id: string # ID of the client
  client_secret: string # secret of the client
  --grant-type: string # default is "client_credentials"
  id_user: int # id of the user to generate a token for
  --revoke-previous: oneof<nothing, bool> # if true, all other permanent tokens for the user will be deleted
]: any -> record<access_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/renew")
  let req_body = {"client_id": $client_id, "client_secret": $client_secret, "grant_type": $grant_type, "id_user": $id_user, "revoke_previous": $revoke_previous} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "access_token")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Remove user access
#
# DELETE /auth/token
export def "auth-token delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login to API with credentials
#
# POST /auth/token
export def "auth-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  application: string # application name
  --grant-type: string # password when requesting a user token and client_credentials for a payment manage token (default: password)
  password: string # password
  --scope: string # scope requested for the token
  username: string # username
]: any -> record<expires_in: int, scope: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let req_body = {"application": $application, "grant_type": $grant_type, "password": $password, "scope": $scope, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Transform a temporary code to a access_token
#
# POST /auth/token/access
export def "auth-token-access create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  client_id: string # ID of the client
  client_secret: string # secret of the client
  code: string # user's temporary code
  --grant-type: string # default is "authorization_code"
  --redirect-uri: string # redirect uri used by user
]: any -> record<access_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token/access")
  let req_body = {"client_id": $client_id, "client_secret": $client_secret, "code": $code, "grant_type": $grant_type, "redirect_uri": $redirect_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "access_token")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Generate a user temporary token
#
# GET /auth/token/code
export def "auth-token-code get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-4 # Response content type
]: nothing -> record<access: string, code: string, expires_in: int, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token/code")
  let accept_val = ($accept | default "access")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of connectors
#
# GET /banks
export def "banks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<banks: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/banks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create bank categories
#
# POST /banks/categories
export def "banks-categories create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  name: string # name of the category to be created
]: any -> record<id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/banks/categories" $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete the supplied category
#
# DELETE /banks/categories/{id_category}
export def "banks-categories delete" [
  id_category: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_category: (encode-path-segment $id_category)} | format pattern "/banks/categories/{id_category}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a bank categories
#
# POST /banks/categories/{id_category}
export def "banks-categories create-by-id_category" [
  id_category: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  name: string # new name for the supplied category
]: any -> record<id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_category: (encode-path-segment $id_category)} | format pattern "/banks/categories/{id_category}") $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get a connector
#
# GET /banks/{id_bank}
export def "banks get" [
  id_bank: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_bank: (encode-path-segment $id_bank)} | format pattern "/banks/{id_bank}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a subset of id_connection for a given bank. Different selection methode are possible
#
# GET /banks/{id_connector}/connections
export def "banks-connections get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string # methode of selection use between 'diversity' (default), 'cover' and 'type_select'
  --n: int # the number of requested connections, if applicable by the method
  --type: int # for 'type_select' method. Specific account type id (weboob_type_id) to select
  --occurences: int # for 'type_select' method. Each connection requires at least N
  --qp-source: string # specify a source name that should have a null state
  --minutes-without-sync: int # Ensure the connection will not have a sync happening for at
  --expand: string
]: nothing -> record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar") (serialize-qp "n" $n "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "occurences" $occurences "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "minutes_without_sync" $minutes_without_sync "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/banks/{id_connector}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /banks/{id_connector}/logos
export def "banks-logos get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/banks/{id_connector}/logos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /banks/{id_connector}/logos/main
export def "banks-logos-main get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/banks/{id_connector}/logos/main") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /banks/{id_connector}/logos/thumbnail
export def "banks-logos-thumbnail get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/banks/{id_connector}/logos/thumbnail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of connector sources
#
# GET /banks/{id_connector}/sources
export def "banks-sources list" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/banks/{id_connector}/sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get fields specific to a domain and a source
#
# GET /banks/{id_connector}/sources/{id_connector_source}/fields
export def "banks-sources-fields get" [
  id_connector: int
  id_connector_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_connector_source: (encode-path-segment $id_connector_source)} | format pattern "/banks/{id_connector}/sources/{id_connector_source}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the connector source
#
# GET /banks/{id_connector}/sources/{id_source}
export def "banks-sources get" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_source: (encode-path-segment $id_source)} | format pattern "/banks/{id_connector}/sources/{id_source}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all categories
#
# GET /categories
export def "categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<categories: table<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new keyword associated with a category in the database.
#
# POST /categories/keywords
export def "categories-keywords create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_category: int, income: bool, keyword: string, priority: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories/keywords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a particular key-value pair on a transaction.
#
# DELETE /categories/keywords/{id_keyword}
export def "categories-keywords delete" [
  id_keyword: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_category: int, income: bool, keyword: string, priority: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_keyword: (encode-path-segment $id_keyword)} | format pattern "/categories/keywords/{id_keyword}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# categorize transactions without storing them
#
# POST /categorize
export def "categorize create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-5 # Response content type
  type: string # type of the transaction (default: unknown)
  value: int # value of the transaction
  wording: string # label of the transaction
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categorize")
  let req_body = {"type": $type, "value": $value, "wording": $wording} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get the latest certificate of a type
#
# GET /certificate/{type}
export def "certificate get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created: string, id: int, id_private_key_file: int, id_public_key_file: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/certificate/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List clients
#
# GET /clients
export def "clients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<clients: table<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a client
#
# POST /clients
export def "clients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # custom config about the client
  --generate-keys: oneof<nothing, bool> # if True, generate a rsa pair of keys so the client can be used to generate jwt user tokens (default: False)
  --name: string # name of client
  --redirect-uris: string # list of allowed redirect uris
]: any -> record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clients" $qp)
  let req_body = {"config": $config, "generate_keys": $generate_keys, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete a client
#
# DELETE /clients/{id_client}
export def "clients delete" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_client: (encode-path-segment $id_client)} | format pattern "/clients/{id_client}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a client
#
# GET /clients/{id_client}
export def "clients get" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_client: (encode-path-segment $id_client)} | format pattern "/clients/{id_client}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a client
#
# PUT /clients/{id_client}
export def "clients update" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # custom config about the client
  --description: string # text to display as a default description
  --description-banks: string # text to display as a description for banks
  --description-providers: string # text to display as a description for providers
  --generate-keys: oneof<nothing, bool> # set a rsa key pair for the client, which make it possible to generate a jwt user token using this client. No effect if the client already has a set of keys(default: False)
  --name: string # name of client
  --primary-color: string # hexadecimal code of the client primary color (e.g F45B9A)
  --pro: oneof<nothing, bool> # Wether the client should display the company manager page
  --redirect-uris: string # list of allowed redirect uris
  --secondary-color: string # hexadecimal code of the client secondary color (e.g F45B9A)
  --secret: oneof<nothing, bool> # reset the secret
  --update-config: oneof<nothing, bool> # update the custom information about the client instead of replacing the existing one (default: True)
]: any -> record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_client: (encode-path-segment $id_client)} | format pattern "/clients/{id_client}") $qp)
  let req_body = {"config": $config, "description": $description, "description_banks": $description_banks, "description_providers": $description_providers, "generate_keys": $generate_keys, "name": $name, "primary_color": $primary_color, "pro": $pro, "redirect_uris": $redirect_uris, "secondary_color": $secondary_color, "secret": $secret, "update_config": $update_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete the client logo
#
# DELETE /clients/{id_client}/logo
export def "clients-logo delete" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<content_type: string, file_size: int, filename: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_client: (encode-path-segment $id_client)} | format pattern "/clients/{id_client}/logo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the client logo
#
# POST /clients/{id_client}/logo
export def "clients-logo create" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<content_type: string, file_size: int, filename: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_client: (encode-path-segment $id_client)} | format pattern "/clients/{id_client}/logo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configuration of the API.
#
# GET /config
export def "config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # limit the results to keys matching the given value
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert/update configuration key(s)/value(s) on the API.
#
# POST /config
export def "config create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configuration change history of the API.
#
# GET /config/logs
export def "config-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # limit the results to keys matching the given value
  --type: string # type of change done on the configuration
  --min-date: string # minimal date of the change (format: date)
  --max-date: string # maximum date of the change (format: date)
  --expand: string
]: nothing -> record<configlogs: table<id: int, key: string, new_value: string, origin: string, previous_value: string, timestamp: string, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/config/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connections without a user
#
# GET /connections
export def "connections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection logs
#
# GET /connections/{id_connection}/logs
export def "connections-logs get" [
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --id-user: int # ID of a user
  --id-connection: int # ID of a connection
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --qp-error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "id_user" $id_user "scalar") (serialize-qp "id_connection" $id_connection "scalar") (serialize-qp "id_connector" $id_connector "scalar") (serialize-qp "connector_uuid" $connector_uuid "scalar") (serialize-qp "error" $qp_error "scalar") (serialize-qp "id_source" $id_source "scalar") (serialize-qp "id_max" $id_max "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connection: (encode-path-segment $id_connection)} | format pattern "/connections/{id_connection}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection sources
#
# GET /connections/{id_connection}/sources
export def "connections-sources get" [
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connection: (encode-path-segment $id_connection)} | format pattern "/connections/{id_connection}/sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a connection source
#
# DELETE /connections/{id_connection}/sources/{id_source}
export def "connections-sources delete" [
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connection: (encode-path-segment $id_connection), id_source: (encode-path-segment $id_source)} | format pattern "/connections/{id_connection}/sources/{id_source}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# "
#
# POST /connections/{id_connection}/sources/{id_source}
export def "connections-sources create" [
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the sysynchronizenc parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "background" $background "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connection: (encode-path-segment $id_connection), id_source: (encode-path-segment $id_source)} | format pattern "/connections/{id_connection}/sources/{id_source}") $qp)
  let req_body = {"disabled": $disabled, "synchronize": $synchronize} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Update connection source
#
# PUT /connections/{id_connection}/sources/{id_source}
export def "connections-sources update" [
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the synchronize parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --force: oneof<nothing, bool> # whether to force the synchronization on the source if it's in error
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "background" $background "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connection: (encode-path-segment $id_connection), id_source: (encode-path-segment $id_source)} | format pattern "/connections/{id_connection}/sources/{id_source}") $qp)
  let req_body = {"disabled": $disabled, "force": $force, "synchronize": $synchronize} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get list of connectors
#
# GET /connectors
export def "connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectors: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a new connector
#
# POST /connectors
export def "connectors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --comment: string # Optionnal comment
  --email: string # Email of the user
  login: string # Users login
  name: string # Name of the bank or provider
  password: string # Users password
  --sendmail: oneof<nothing, bool> # if set, send an email to user
  --types: string # Type of connector, eg. banks or providers
  --url: string # Url of the bank
]: any -> record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connectors" $qp)
  let req_body = {"comment": $comment, "email": $email, "login": $login, "name": $name, "password": $password, "sendmail": $sendmail, "types": $types, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Enable/disable several connectors
#
# PUT /connectors
export def "connectors update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --hidden: oneof<nothing, bool> # to enable or disable connector (bank or provider)
]: any -> record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connectors" $qp)
  let req_body = {"hidden": $hidden} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get a connector
#
# GET /connectors/{id_connector}
export def "connectors get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit the provided connector
#
# PUT /connectors/{id_connector}
export def "connectors update-by-id_connector" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-6 # Response content type
  --expand: string
  --auth-mechanism: string # the authentication mechanism to use for this connector
  --hidden: oneof<nothing, bool> # to enable or disable connector (bank or provider)
  --id-categories: string # one or several comma separated categories to map to the given connector (or null to map no category)
  --sync-frequency: int # Allows you to overload global sync_frequency param
]: any -> record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}") $qp)
  let req_body = {"auth_mechanism": $auth_mechanism, "hidden": $hidden, "id_categories": $id_categories, "sync_frequency": $sync_frequency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get all links to the files associated with this connector.
#
# GET /connectors/{id_connector}/logos
export def "connectors-logos get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/logos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a connector Logo
#
# POST /connectors/{id_connector}/logos
export def "connectors-logos create" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_connector: int, id_file: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/logos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update a connector Logo
#
# PUT /connectors/{id_connector}/logos
export def "connectors-logos update-by-id_connector" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_connector: int, id_file: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/logos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /connectors/{id_connector}/logos/main
export def "connectors-logos-main get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/logos/main") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /connectors/{id_connector}/logos/thumbnail
export def "connectors-logos-thumbnail get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/logos/thumbnail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a single Logo object.
#
# DELETE /connectors/{id_connector}/logos/{id_logo}
export def "connectors-logos delete" [
  id_connector: int
  id_logo: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_connector: int, id_file: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_logo: (encode-path-segment $id_logo)} | format pattern "/connectors/{id_connector}/logos/{id_logo}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update a connector Logo.
#
# PUT /connectors/{id_connector}/logos/{id_logo}
export def "connectors-logos update-by-id_connector-id_logo" [
  id_connector: int
  id_logo: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_connector: int, id_file: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_logo: (encode-path-segment $id_logo)} | format pattern "/connectors/{id_connector}/logos/{id_logo}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of connector sources
#
# GET /connectors/{id_connector}/sources
export def "connectors-sources list" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit several connector sources
#
# PUT /connectors/{id_connector}/sources
export def "connectors-sources update-by-id_connector" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --disabled-capabilities: string # list (json format) of capabilities the sources will be disabled for
  --unavailable-capabilities: string # list (json format) of capabilities the sources will be unavailable for
]: any -> record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/connectors/{id_connector}/sources") $qp)
  let req_body = {"disabled_capabilities": $disabled_capabilities, "unavailable_capabilities": $unavailable_capabilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get fields specific to a domain and a source
#
# GET /connectors/{id_connector}/sources/{id_connector_source}/fields
export def "connectors-sources-fields get" [
  id_connector: int
  id_connector_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_connector_source: (encode-path-segment $id_connector_source)} | format pattern "/connectors/{id_connector}/sources/{id_connector_source}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the connector source
#
# GET /connectors/{id_connector}/sources/{id_source}
export def "connectors-sources get" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_source: (encode-path-segment $id_source)} | format pattern "/connectors/{id_connector}/sources/{id_source}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit the provided connector source
#
# PUT /connectors/{id_connector}/sources/{id_source}
export def "connectors-sources update-by-id_connector-id_source" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --auth-mechanism: string # the authentication mechanism to use for this connector source
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --disabled-capabilities: string # list (json format) of capabilities this source will be disabled for
  --unavailable: oneof<nothing, bool> # to enable or disable the source (can only be edited by BI employees)
  --unavailable-capabilities: string # list (json format) of capabilities this source will be unavailable for
]: any -> record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_source: (encode-path-segment $id_source)} | format pattern "/connectors/{id_connector}/sources/{id_source}") $qp)
  let req_body = {"auth_mechanism": $auth_mechanism, "disabled": $disabled, "disabled_capabilities": $disabled_capabilities, "unavailable": $unavailable, "unavailable_capabilities": $unavailable_capabilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get incidents logs.
#
# GET /incidents
export def "incidents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # comma separated list, filter incidents in the given states.
  --id: int # give only the current state of the particular incidents.
  --weboob-id: string # comma_separated list, filter the incidents of the given weboob_id
  --start-date: string # filter last_update date >= start_date. YYYY-MM-DD format.
  --end-date: string # filter last_update date <= start_date. YYYY-MM-DD format.
  --page: int # pagination option. Default to 1.
  --size: int # pagination option. Default to 30.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "weboob_id" $weboob_id "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoicing data for a given period (default is the current month).
#
# GET /invoicing
export def "invoicing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --users-synced: string # the number of user synchronized during the period
  --users-bank: string # the number of user of the Bank API synchronized during the period
  --users-bill: string # the number of user of the Bill API synchronized during the period
  --accounts-synced: string # the number of accounts synchronized during the period
  --subscriptions-synced: string # the number of subscriptions synchronized during the period
  --connections-synced: string # the number of connections synchronized during the period
  --connections-account: string # the number of Bank API connections synchronized during the period
  --transfers-synced: string # the number of transfers done during the period
  --payments-synced: string # the number of payments done during the period
  --all: string # get all the invoicing data at once
  --detail: string # get full ids list instead of numbers
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "users_synced" $users_synced "scalar") (serialize-qp "users_bank" $users_bank "scalar") (serialize-qp "users_bill" $users_bill "scalar") (serialize-qp "accounts_synced" $accounts_synced "scalar") (serialize-qp "subscriptions_synced" $subscriptions_synced "scalar") (serialize-qp "connections_synced" $connections_synced "scalar") (serialize-qp "connections_account" $connections_account "scalar") (serialize-qp "transfers_synced" $transfers_synced "scalar") (serialize-qp "payments_synced" $payments_synced "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "detail" $detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoicing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection logs
#
# GET /logs
export def "logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --id-user: int # ID of a user
  --id-connection: int # ID of a connection
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --qp-error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "id_user" $id_user "scalar") (serialize-qp "id_connection" $id_connection "scalar") (serialize-qp "id_connector" $id_connector "scalar") (serialize-qp "connector_uuid" $connector_uuid "scalar") (serialize-qp "error" $qp_error "scalar") (serialize-qp "id_source" $id_source "scalar") (serialize-qp "id_max" $id_max "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get performances stats on this instance
#
# GET /monitoring
export def "monitoring get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: int # number on days on which stats on synchronization have to be done per worker (Default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/monitoring" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of connectors
#
# GET /providers
export def "providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<providers: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a random subset of provider's id_connection
#
# GET /providers/{id_connector}/connections
export def "providers-connections get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --range: int # the length of the connection subset
  --expand: string
]: nothing -> record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "range" $range "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/providers/{id_connector}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /providers/{id_connector}/logos
export def "providers-logos get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/providers/{id_connector}/logos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /providers/{id_connector}/logos/main
export def "providers-logos-main get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/providers/{id_connector}/logos/main") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all links to the files associated with this connector.
#
# GET /providers/{id_connector}/logos/thumbnail
export def "providers-logos-thumbnail get" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/providers/{id_connector}/logos/thumbnail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of connector sources
#
# GET /providers/{id_connector}/sources
export def "providers-sources list" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector)} | format pattern "/providers/{id_connector}/sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get fields specific to a domain and a source
#
# GET /providers/{id_connector}/sources/{id_connector_source}/fields
export def "providers-sources-fields get" [
  id_connector: int
  id_connector_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_connector_source: (encode-path-segment $id_connector_source)} | format pattern "/providers/{id_connector}/sources/{id_connector_source}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the connector source
#
# GET /providers/{id_connector}/sources/{id_source}
export def "providers-sources get" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_connector: (encode-path-segment $id_connector), id_source: (encode-path-segment $id_source)} | format pattern "/providers/{id_connector}/sources/{id_source}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a connector
#
# GET /providers/{id_provider}
export def "providers get" [
  id_provider: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_provider: (encode-path-segment $id_provider)} | format pattern "/providers/{id_provider}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details on all psd2 registrations
#
# GET /psd2-registrations
export def "psd2-registrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<psd2registrations: table<id: int, id_connector_source: int, status: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/psd2-registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details for a given psd2 registration
#
# GET /psd2-registrations/{id_psd2-registration}
export def "psd2-registrations get" [
  id_psd2_registration: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_connector_source: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_psd2_registration: (encode-path-segment $id_psd2_registration)} | format pattern "/psd2-registrations/{id_psd2_registration}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get psd2 registration logs.
#
# GET /psd2-registrations/{id_psd2registration}/logs
export def "psd2-registrations-logs get" [
  id_psd2registration: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --expand: string
]: nothing -> record<psd2registrationlogs: table<created_at: string, error_message: string, id: int, id_psd2registration: int, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_psd2registration: (encode-path-segment $id_psd2registration)} | format pattern "/psd2-registrations/{id_psd2registration}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public encryption key of the API.
#
# GET /publickey
export def "publickey get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/publickey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test synchronization on a random connection.
#
# POST /test/sync
export def "test-sync create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test synchronization on a random connection.
#
# POST /test/webhooks
export def "test-webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # searches a user by mail (if it contains no '@', '@biapi.pro' will be added at the end)
  --expand: string
]: nothing -> record<total: float, users: table<id: int, platform: string, signin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the user
#
# DELETE /users/{id_user}
export def "users delete" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, platform: string, signin: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{id_user}
export def "users get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, platform: string, signin: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account types
#
# GET /users/{id_user}/account_types
export def "users-account-types list" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<accounttypes: table<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/account_types") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an account type
#
# GET /users/{id_user}/account_types/{id_account_type}
export def "users-account-types get" [
  id_user: string
  id_account_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_account_type: (encode-path-segment $id_account_type)} | format pattern "/users/{id_user}/account_types/{id_account_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the category
#
# GET /users/{id_user}/accounts/{id_account}/categories
export def "users-accounts-categories get" [
  id_user: string
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/accounts/{id_account}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get clustered transactions
#
# GET /users/{id_user}/accounts/{id_account}/transactionsclusters
export def "users-accounts-transactionsclusters get" [
  id_user: string
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/accounts/{id_account}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create clustered transaction
#
# POST /users/{id_user}/accounts/{id_account}/transactionsclusters
export def "users-accounts-transactionsclusters create" [
  id_user: string
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/accounts/{id_account}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
export def "users-accounts-transactionsclusters delete" [
  id_user: string
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_account: (encode-path-segment $id_account), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
export def "users-accounts-transactionsclusters update" [
  id_user: string
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_account: (encode-path-segment $id_account), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get alerts
#
# GET /users/{id_user}/alerts
export def "users-alerts get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<alerts: table<id: int, id_account: int, id_investment: int, id_transaction: int, id_user: int, timestamp: string, type: string, value: float>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the category
#
# GET /users/{id_user}/categories
export def "users-categories get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the category
#
# GET /users/{id_user}/categories/full
export def "users-categories-full get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<categorys: table<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/categories/full") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new transaction category
#
# POST /users/{id_user}/categories/full
export def "users-categories-full create" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --accountant-account: string # Accountant account number.
  --color: string # Color of the category.
  --id-parent-category: int # ID of the parent category.
  --id-parent-category-in-menu: int # ID of the parent category to be displayed.
  --income: oneof<nothing, bool> # Is an income category. If null, this is both an income and an expense category.
  --name: string # Name of the category.
  --refundable: oneof<nothing, bool> # This category accepts opposite sign of transactions.
]: any -> record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/categories/full") $qp)
  let req_body = {"accountant_account": $accountant_account, "color": $color, "id_parent_category": $id_parent_category, "id_parent_category_in_menu": $id_parent_category_in_menu, "income": $income, "name": $name, "refundable": $refundable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete a user-created transaction category
#
# DELETE /users/{id_user}/categories/full/{id_full}
export def "users-categories-full delete" [
  id_user: string
  id_full: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_full: (encode-path-segment $id_full)} | format pattern "/users/{id_user}/categories/full/{id_full}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a user-created category
#
# PUT /users/{id_user}/categories/full/{id_full}
export def "users-categories-full update" [
  id_user: string
  id_full: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --accountant-account: string # Accountant account number.
  --hide: string # Hide (but not delete) a category. Must be 0, 1 or toggle.
]: any -> record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_full: (encode-path-segment $id_full)} | format pattern "/users/{id_user}/categories/full/{id_full}") $qp)
  let req_body = {"accountant_account": $accountant_account, "hide": $hide} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete the given user configurations. deletions on keys prefixed by 'biapi.' (except callback_url) are ignored
#
# DELETE /users/{id_user}/config
export def "users-config delete" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configuration of a user.
#
# GET /users/{id_user}/config
export def "users-config get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-7 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/config"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change configuration of a user. modifications on keys prefixed by 'biapi.' (except callback_url) are ignored
#
# POST /users/{id_user}/config
export def "users-config create" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all connections
#
# DELETE /users/{id_user}/connections
export def "users-connections delete-by-id_user" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connections
#
# GET /users/{id_user}/connections
export def "users-connections get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new connection.
#
# POST /users/{id_user}/connections
export def "users-connections create-by-id_user" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string # optional comma-separated list of sources to use for the connection synchronization
  --expand: string
  --connector-uuid: string # optional uuid of the connector (replaces id_connector)
  --id-connector: int # ID of the connector
]: any -> record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/connections") $qp)
  let req_body = {"connector_uuid": $connector_uuid, "id_connector": $id_connector} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete a connection.
#
# DELETE /users/{id_user}/connections/{id_connection}
export def "users-connections delete-by-id_user-id_connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a connection.
#
# POST /users/{id_user}/connections/{id_connection}
export def "users-connections create-by-id_user-id_connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # Do the connection update/synchronization in background
  --psu-requested: oneof<nothing, bool> # Whether the connection synchronization is asked by the PSU or not (default is true)
  --refresh-psd2-auth: oneof<nothing, bool> # Refresh the PSU's SCA for openapi source
  --expand: string
  --active: oneof<nothing, bool> # Set if the connection synchronization is active
  --decoupled: oneof<nothing, bool> # Try to update a connection with the decoupled error
  --expire: string # Set expiration of the connection to this date (format: date-time)
  --login: string # Set login to this new login
  --password: string # Set password to this new password
]: any -> record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "background" $background "scalar") (serialize-qp "psu_requested" $psu_requested "scalar") (serialize-qp "refresh_psd2_auth" $refresh_psd2_auth "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}") $qp)
  let req_body = {"active": $active, "decoupled": $decoupled, "expire": $expire, "login": $login, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Force synchronisation of a connection.
#
# PUT /users/{id_user}/connections/{id_connection}
export def "users-connections update" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-update: string # if supplied, get transactions inserted since this date (format: date-time)
  --background: oneof<nothing, bool> # do the connection synchronization in background
  --psu-requested: oneof<nothing, bool> # Whether the connection synchronization is asked by the PSU or not (default is true)
  --expand: string
]: nothing -> record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_update" $last_update "scalar") (serialize-qp "background" $background "scalar") (serialize-qp "psu_requested" $psu_requested "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all accounts
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts
export def "users-connections-accounts delete-by-id_user-id_connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get accounts list.
#
# GET /users/{id_user}/connections/{id_connection}/accounts
export def "users-connections-accounts get" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<accounts: table<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an account
#
# POST /users/{id_user}/connections/{id_connection}/accounts
export def "users-connections-accounts create" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --balance: float # balance of account (format: float)
  --iban: string # IBAN of account
  --body-id-connection: int # the connection to attach to the account
  --id-currency: string # the currency of the account (default: 'EUR')
  name: string # name of account
  --number: string # number of account
]: any -> record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts") $qp)
  let req_body = {"balance": $balance, "iban": $iban, "id_connection": $body_id_connection, "id_currency": $id_currency, "name": $name, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Update many accounts at once
#
# PUT /users/{id_user}/connections/{id_connection}/accounts
export def "users-connections-accounts update-by-id_user-id_connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an account.
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}
export def "users-connections-accounts delete-by-id_user-id_connection-id_account" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an account
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}
export def "users-connections-accounts update-by-id_user-id_connection-id_account" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --balance: float # Balance of the account (format: float)
  --bookmarked: oneof<nothing, bool> # If the account is bookmarked
  --disabled: oneof<nothing, bool> # If the account is disabled (not synchronized)
  --display: oneof<nothing, bool> # If the account is displayed
  --iban: string # IBAN of the account
  --name: string # Label of the account
  --usage: string # Usage of the account : PRIV, ORGA or ASSO
]: any -> record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}") $qp)
  let req_body = {"balance": $balance, "bookmarked": $bookmarked, "disabled": $disabled, "display": $display, "iban": $iban, "name": $name, "usage": $usage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get the category
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/categories
export def "users-connections-accounts-categories get" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get deltas of accounts
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/delta
export def "users-connections-accounts-delta get" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/delta") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get accounts logs.
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/logs
export def "users-connections-accounts-logs get" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --expand: string
]: nothing -> record<accountlogs: table<balance: float, coming: float, error: string, error_message: string, id: int, id_account: int, id_connection_log: int, id_connector: int, timestamp: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account sources
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/sources
export def "users-connections-accounts-sources get" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete transactions
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions
export def "users-connections-accounts-transactions delete" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get transactions
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions
export def "users-connections-accounts-transactions get" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --income: oneof<nothing, bool> # filter on income or expenditures
  --deleted: oneof<nothing, bool> # display only deleted transactions
  --all: oneof<nothing, bool> # display all transactions, including deleted ones
  --last-update: string # get only transactions updated after the specified datetime (format: date-time)
  --wording: string # filter transactions containing the given string
  --min-value: float # minimal (inclusive) value (format: float)
  --max-value: float # maximum (inclusive) value (format: float)
  --search: string # search in labels, dates, values and categories
  --value: string # "XX|-XX" or "±XX"
  --id-category: int # filter on given category id(s) (comma separated) or "null"
  --expand: string
]: nothing -> record<total: float, transactions: table<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "income" $income "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "last_update" $last_update "scalar") (serialize-qp "wording" $wording "scalar") (serialize-qp "min_value" $min_value "scalar") (serialize-qp "max_value" $max_value "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "id_category" $id_category "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create transactions
#
# POST /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions
export def "users-connections-accounts-transactions create" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --active: oneof<nothing, bool> # 1 if the transaction should be taken into account by pfm services (default: 1)
  --coming: oneof<nothing, bool> # 1 if the transaction has already been debited (default: 0)
  date: string # date of the transaction (format: date)
  --date-scraped: string # date on which the transaction has been found for the first time. YYYY-MM-DD HH:MM:SS(default: now) (format: date-time)
  --body-id-account: int # account of the transaction. If not supplied, it has to be given in the route
  original_wording: string # label of the transaction
  --rdate: string # realisation date of the transaction (default: value of date) (format: date)
  --state: string # nature of the transaction (default: new)
  --type: string # type of the transaction (default: unknown)
  value: int # vallue of the transaction
]: any -> record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions") $qp)
  let req_body = {"active": $active, "coming": $coming, "date": $date, "date_scraped": $date_scraped, "id_account": $body_id_account, "original_wording": $original_wording, "rdate": $rdate, "state": $state, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Edit a transaction meta-data
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}
export def "users-connections-accounts-transactions update" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --active: oneof<nothing, bool> # if false, transaction isn't considered in analyzisis endpoints (like /balances)
  --application-date: string # change application date of the transaction (format: date)
  --comment: string # change comment
  --id-category: int # ID of the associated category
  --wording: string # user rewording of the transaction
]: any -> record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transaction: (encode-path-segment $id_transaction)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}") $qp)
  let req_body = {"active": $active, "application_date": $application_date, "comment": $comment, "id_category": $id_category, "wording": $wording} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete all arbitrary key-value pairs of a transaction
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations
export def "users-connections-accounts-transactions-informations delete-by-id_user-id_connection-id_account-id_transaction" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_transaction: int, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transaction: (encode-path-segment $id_transaction)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all arbitrary key-value pairs on a transaction
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations
export def "users-connections-accounts-transactions-informations list" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, transactioninformations: table<id: int, id_transaction: int, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transaction: (encode-path-segment $id_transaction)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or edit transaction arbitrary key-value pairs
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations
export def "users-connections-accounts-transactions-informations update" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_transaction: int, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transaction: (encode-path-segment $id_transaction)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a particular key-value pair on a transaction.
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}
export def "users-connections-accounts-transactions-informations delete-by-id_user-id_connection-id_account-id_transaction-id_information" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  id_information: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_transaction: int, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transaction: (encode-path-segment $id_transaction), id_information: (encode-path-segment $id_information)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a particular arbitrary key-value pair on a transaction
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}
export def "users-connections-accounts-transactions-informations get" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  id_information: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, id_transaction: int, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transaction: (encode-path-segment $id_transaction), id_information: (encode-path-segment $id_information)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get clustered transactions
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters
export def "users-connections-accounts-transactionsclusters get" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create clustered transaction
#
# POST /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters
export def "users-connections-accounts-transactionsclusters create" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
export def "users-connections-accounts-transactionsclusters delete" [
  id_user: string
  id_connection: int
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
export def "users-connections-accounts-transactionsclusters update" [
  id_user: string
  id_connection: int
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_account: (encode-path-segment $id_account), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection additionnal informations
#
# GET /users/{id_user}/connections/{id_connection}/informations
export def "users-connections-informations get" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-8 # Response content type
  --expand: string
]: nothing -> record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/informations") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection logs
#
# GET /users/{id_user}/connections/{id_connection}/logs
export def "users-connections-logs get" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --id-user: int # ID of a user
  --id-connection: int # ID of a connection
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --qp-error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "id_user" $id_user "scalar") (serialize-qp "id_connection" $id_connection "scalar") (serialize-qp "id_connector" $id_connector "scalar") (serialize-qp "connector_uuid" $connector_uuid "scalar") (serialize-qp "error" $qp_error "scalar") (serialize-qp "id_source" $id_source "scalar") (serialize-qp "id_max" $id_max "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection sources
#
# GET /users/{id_user}/connections/{id_connection}/sources
export def "users-connections-sources get" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a connection source
#
# DELETE /users/{id_user}/connections/{id_connection}/sources/{id_source}
export def "users-connections-sources delete" [
  id_user: string
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_source: (encode-path-segment $id_source)} | format pattern "/users/{id_user}/connections/{id_connection}/sources/{id_source}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# "
#
# POST /users/{id_user}/connections/{id_connection}/sources/{id_source}
export def "users-connections-sources create" [
  id_user: string
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the sysynchronizenc parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "background" $background "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_source: (encode-path-segment $id_source)} | format pattern "/users/{id_user}/connections/{id_connection}/sources/{id_source}") $qp)
  let req_body = {"disabled": $disabled, "synchronize": $synchronize} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Update connection source
#
# PUT /users/{id_user}/connections/{id_connection}/sources/{id_source}
export def "users-connections-sources update" [
  id_user: string
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the synchronize parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --force: oneof<nothing, bool> # whether to force the synchronization on the source if it's in error
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "background" $background "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_source: (encode-path-segment $id_source)} | format pattern "/users/{id_user}/connections/{id_connection}/sources/{id_source}") $qp)
  let req_body = {"disabled": $disabled, "force": $force, "synchronize": $synchronize} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get clustered transactions
#
# GET /users/{id_user}/connections/{id_connection}/transactionsclusters
export def "users-connections-transactionsclusters get" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create clustered transaction
#
# POST /users/{id_user}/connections/{id_connection}/transactionsclusters
export def "users-connections-transactionsclusters create" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection)} | format pattern "/users/{id_user}/connections/{id_connection}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}
export def "users-connections-transactionsclusters delete" [
  id_user: string
  id_connection: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}
export def "users-connections-transactionsclusters update" [
  id_user: string
  id_connection: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_connection: (encode-path-segment $id_connection), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get forecast
#
# GET /users/{id_user}/forecast
export def "users-forecast get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/forecast"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get connection logs
#
# GET /users/{id_user}/logs
export def "users-logs get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --id-user: int # ID of a user
  --id-connection: int # ID of a connection
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --qp-error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "id_user" $id_user "scalar") (serialize-qp "id_connection" $id_connection "scalar") (serialize-qp "id_connector" $id_connector "scalar") (serialize-qp "connector_uuid" $connector_uuid "scalar") (serialize-qp "error" $qp_error "scalar") (serialize-qp "id_source" $id_source "scalar") (serialize-qp "id_max" $id_max "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profiles
#
# GET /users/{id_user}/profiles
export def "users-profiles list" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<profiles: table<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/profiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the main profile
#
# GET /users/{id_user}/profiles/main
export def "users-profiles-main get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/profiles/main") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a profile
#
# GET /users/{id_user}/profiles/{id_profile}
export def "users-profiles get" [
  id_user: string
  id_profile: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_profile: (encode-path-segment $id_profile)} | format pattern "/users/{id_user}/profiles/{id_profile}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a token
#
# POST /users/{id_user}/token
export def "users-token create" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-9 # Response content type
  application: string # application name
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/token"))
  let req_body = {"application": $application} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get clustered transactions
#
# GET /users/{id_user}/transactionsclusters
export def "users-transactionsclusters get" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create clustered transaction
#
# POST /users/{id_user}/transactionsclusters
export def "users-transactionsclusters create" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user)} | format pattern "/users/{id_user}/transactionsclusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/transactionsclusters/{id_transactionscluster}
export def "users-transactionsclusters delete" [
  id_user: string
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/transactionsclusters/{id_transactionscluster}
export def "users-transactionsclusters update" [
  id_user: string
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_user: (encode-path-segment $id_user), id_transactionscluster: (encode-path-segment $id_transactionscluster)} | format pattern "/users/{id_user}/transactionsclusters/{id_transactionscluster}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# First step to establish an oAuth2 connection.
#
# GET /webauth
export def "webauth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: int # Client Application ID
  --id-transfer: int # ID of the transfer
  --redirect-uri: string # Redirect URI
  --state: string # Optional state
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webauth")
  let req_body = {"client_id": $client_id, "id_transfer": $id_transfer, "redirect_uri": $redirect_uri, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Deletes all webhooks
#
# DELETE /webhooks
export def "webhooks delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhooks
#
# GET /webhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, webhooks: table<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new webhook
#
# POST /webhooks
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --event: string # The webhook event
  --id-auth: string # The webhook authentication process to use (its ID or its name)
  --id-service: int # The service ID to associate with the webhook
  --id-user: int # The user ID to associate with the webhook
  --params: string # The webhook parameters as an object with three keys: type, key and value
  --url: string # The webhook callback url
]: any -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let req_body = {"event": $event, "id_auth": $id_auth, "id_service": $id_service, "id_user": $id_user, "params": $params, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Deletes all webhook authentication types
#
# DELETE /webhooks/auth
export def "webhooks-auth delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/auth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhooks authentication types
#
# GET /webhooks/auth
export def "webhooks-auth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<authproviders: table<id: int, name: string, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/auth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new webhook authentication type
#
# POST /webhooks/auth
export def "webhooks-auth create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # The authentication process configuration. A dict contains either the certificate
  name: string # The name of the authentication process to differentiate
  type: int # The type of the authentication process (oauth, certificate, token, etc...)
]: any -> record<id: int, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/auth" $qp)
  let req_body = {"config": $config, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Deletes the webhook authentication type
#
# DELETE /webhooks/auth/{id_auth}
export def "webhooks-auth delete-by-id_auth" [
  id_auth: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_auth: (encode-path-segment $id_auth)} | format pattern "/webhooks/auth/{id_auth}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the webhook authentication type
#
# POST /webhooks/auth/{id_auth}
export def "webhooks-auth create-by-id_auth" [
  id_auth: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # The authentication process configuration. A dict containing either the certificate
  name: string # The name of the authentication process to differentiate
  type: int # The type of the authentication process (oauth, certificate, token, etc...)
]: any -> record<id: int, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_auth: (encode-path-segment $id_auth)} | format pattern "/webhooks/auth/{id_auth}") $qp)
  let req_body = {"config": $config, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Updates the webhook authentication type
#
# PUT /webhooks/auth/{id_auth}
export def "webhooks-auth update" [
  id_auth: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # The authentication process configuration. A dict containt either the certificate
  name: string # The name of the authentication process to differentiate
  type: int # The type of the authentication process (oauth, certificate, token, etc...)
]: any -> record<id: int, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_auth: (encode-path-segment $id_auth)} | format pattern "/webhooks/auth/{id_auth}") $qp)
  let req_body = {"config": $config, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Deletes a webhook
#
# DELETE /webhooks/{id_webhook}
export def "webhooks delete-by-id_webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a webhook
#
# POST /webhooks/{id_webhook}
export def "webhooks create-by-id_webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --deleted: string # a date to delete the webhook or 'null' to enable it
  --event: string # The webhook event
  --id-auth: int # The webhook authentication process to use
  --id-service: int # The service ID to associate with the webhook
  --id-user: int # The user ID to associate with the webhook
  --url: string # The webhook callback url
]: any -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}") $qp)
  let req_body = {"deleted": $deleted, "event": $event, "id_auth": $id_auth, "id_service": $id_service, "id_user": $id_user, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Updates a webhook
#
# PUT /webhooks/{id_webhook}
export def "webhooks update" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --deleted: string # a date to delete the webhook or 'null' to enable it
  --event: string # The webhook event
  --id-auth: int # The webhook authentication process to use
  --id-service: int # The service ID to associate with the webhook
  --id-user: int # The user ID to associate with the webhook
  --url: string # The webhook callback url
]: any -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}") $qp)
  let req_body = {"deleted": $deleted, "event": $event, "id_auth": $id_auth, "id_service": $id_service, "id_user": $id_user, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# delete all entries
#
# DELETE /webhooks/{id_webhook}/add_to_data
export def "webhooks-add-to-data delete-by-id_webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/add_to_data") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# retrieve the list of the value to add in webhooks when sending the requested webhook
#
# GET /webhooks/{id_webhook}/add_to_data
export def "webhooks-add-to-data list" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<total: float, webhooks: table<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/add_to_data") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Setup a field to store in user config when calling the endpoint
#
# POST /webhooks/{id_webhook}/add_to_data
export def "webhooks-add-to-data create-by-id_webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/add_to_data") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete the requested entry
#
# DELETE /webhooks/{id_webhook}/add_to_data/{key}
export def "webhooks-add-to-data delete-by-id_webhook-key" [
  id_webhook: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook), key: (encode-path-segment $key)} | format pattern "/webhooks/{id_webhook}/add_to_data/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# retrieve the value to add in the requested webhook for the requested name
#
# GET /webhooks/{id_webhook}/add_to_data/{key}
export def "webhooks-add-to-data get" [
  id_webhook: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook), key: (encode-path-segment $key)} | format pattern "/webhooks/{id_webhook}/add_to_data/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# upate the requested field to store in user config when calling the endpoint
#
# POST /webhooks/{id_webhook}/add_to_data/{key}
export def "webhooks-add-to-data create-by-id_webhook-key" [
  id_webhook: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook), key: (encode-path-segment $key)} | format pattern "/webhooks/{id_webhook}/add_to_data/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhooks logs.
#
# GET /webhooks/{id_webhook}/logs
export def "webhooks-logs get" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-user: int # limit number of results to this user
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --expand: string
]: nothing -> record<total: float, webhooklogs: table<id: int, id_service: int, id_user: int, id_webhook_data: int, next_try: string, response_code: int, response_date: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id_user" $id_user "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id_webhook: (encode-path-segment $id_webhook)} | format pattern "/webhooks/{id_webhook}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
