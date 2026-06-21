# Auto-generated client for IllumiDesk v1.0
# Source: https://api.apis.guru/v2/specs/illumidesk.com/1.0/swagger.json
# Auth: --token flag or $env.ILLUMIDESK_TOKEN

const BASE_URL = "https://api.illumidesk.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ILLUMIDESK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "jwt" => { {scheme: $scheme, headers: {Authorization: $"JWT ($token_val)"}, query: "", location: "header"} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.illumidesk.com"] }
def auth-scheme-completer [] { ["jwt" "none"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html"] }
def authorization-grant-type-completer [] { ["authorization-code" "client-credentials" "implicit" "password"] }
def client-type-completer [] { ["confidential" "public"] }
def permissions-completer [] { ["read_project" "write_project"] }
def framework-completer [] { ["tensorflow"] }
def runtime-completer [] { ["python2.7"] }
def operation-completer [] { ["start" "stop" "terminate"] }
def type-completer [] { ["projects" "servers" "users"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-jwt-token-auth create" } } | get name | first)
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

# Create JSON Web Token (JWT)
#
# POST /auth/jwt-token-auth/
# operationId: auth_jwt-token-auth
export def "auth-jwt-token-auth create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  password: string # User password.
  username: string # User name.
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt-token-auth/")
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Refresh a JSON Web Token (JWT)
#
# POST /auth/jwt-token-refresh/
# operationId: auth_jwt-token-refresh
export def "auth-jwt-token-refresh refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-token: string # Refreshed token.
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt-token-refresh/")
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Validate JSON Web Token (JWT)
#
# POST /auth/jwt-token-verify/
# operationId: auth_jwt-token-verify
export def "auth-jwt-token-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-token: string # JSON Web Token (JWT).
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt-token-verify/")
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /auth/login/{provider}/
#
# operationId: oauth_login
export def "auth-login get-oauth" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({provider: (encode-path-segment $provider)} | format pattern "/auth/login/{provider}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Register a user
#
# POST /auth/register/
# operationId: auth_register
# --profile shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
export def "auth-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # User email.
  --first-name: string # User first name.
  --last-name: string # User last name.
  password: string # User password.
  profile: record # shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
  username: string # Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.
]: any -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/register/")
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "password": $password, "profile": $profile, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# A convenience endpoint that is equivalent to GET /v1/users/profiles//
#
# GET /v1/me
# operationId: me
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve available server sizes
#
# GET /v1/servers/options/server-size/
# operationId: servers_options_sizes_list
export def "servers-options-server-size list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Set limit when retrieving items.
  --offset: string # Offset when retrieving items.
  --ordering: string # Set order when retrieving items.
]: nothing -> table<active: bool, cpu: int, id: string, memory: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/servers/options/server-size/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create a new server size item
#
# POST /v1/servers/options/server-size/
# operationId: servers_options_server_size_create
export def "servers-options-server-size create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # Active or not active.
  cpu: int # CPU set for server size.
  memory: int # Memory set for server size.
  name: string # Server size name.
]: any -> record<active: bool, cpu: int, id: string, memory: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/servers/options/server-size/")
  let req_body = {"active": $active, "cpu": $cpu, "memory": $memory, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a server size by id
#
# DELETE /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_delete
export def "servers-options-server-size delete" [
  size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a server size by id
#
# GET /v1/servers/options/server-size/{size}/
# operationId: servers_options_resources_read
export def "servers-options-server-size get-resources" [
  size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<active: bool, cpu: int, id: string, memory: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a server size by id
#
# PATCH /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_update
export def "servers-options-server-size update-by-size" [
  size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # Active or not active.
  cpu: int # CPU set for server size.
  memory: int # Memory set for server size.
  name: string # Server size name.
]: any -> record<active: bool, cpu: int, id: string, memory: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/"))
  let req_body = {"active": $active, "cpu": $cpu, "memory": $memory, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a server size by id
#
# PUT /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_replace
export def "servers-options-server-size update-by-size-1" [
  size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active: oneof<nothing, bool> # Active or not active.
  cpu: int # CPU set for server size.
  memory: int # Memory set for server size.
  name: string # Server size name.
]: any -> record<active: bool, cpu: int, id: string, memory: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/"))
  let req_body = {"active": $active, "cpu": $cpu, "memory": $memory, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get teams
#
# GET /v1/teams/
# operationId: teams_list
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting data.
  --offset: string # Offset when getting data.
]: nothing -> table<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/teams/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Create a new team
#
# POST /v1/teams/
# operationId: teams_create
export def "teams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --avatar: string # Team avatar image. (format: byte)
  --avatar-url: string # Team avatar url.
  --description: string # Team description
  --location: string # Team location.
  name: string # Team name
  --website: string # Teams website.
]: any -> record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams/")
  let req_body = {"avatar": $avatar, "avatar_url": $avatar_url, "description": $description, "location": $location, "name": $name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a team
#
# DELETE /v1/teams/{team}/
# operationId: teams_delete
export def "teams delete" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a team
#
# GET /v1/teams/{team}/
# operationId: teams_read
export def "teams get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a team
#
# PATCH /v1/teams/{team}/
# operationId: teams_update
export def "teams update-by-team" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --avatar: string # Team avatar image. (format: byte)
  --avatar-url: string # Team avatar url.
  --description: string # Team description
  --location: string # Team location.
  name: string # Team name
  --website: string # Teams website.
]: any -> record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/"))
  let req_body = {"avatar": $avatar, "avatar_url": $avatar_url, "description": $description, "location": $location, "name": $name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a team
#
# PUT /v1/teams/{team}/
# operationId: teams_replace
export def "teams update-by-team-1" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --avatar: string # Team avatar image. (format: byte)
  --avatar-url: string # Team avatar url.
  --description: string # Team description
  --location: string # Team location.
  name: string # Team name
  --website: string # Teams website.
]: any -> record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/"))
  let req_body = {"avatar": $avatar, "avatar_url": $avatar_url, "description": $description, "location": $location, "name": $name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get team invoices
#
# GET /v1/teams/{team}/billing/invoices/
# operationId: teams_billing_invoices_list
export def "teams-billing-invoices list" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
]: nothing -> table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/billing/invoices/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Get an invoice
#
# GET /v1/teams/{team}/billing/invoices/{id}/
# operationId: teams_billing_invoices_read
export def "teams-billing-invoices get" [
  team: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/invoices/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get team invoice items for a given invoice.
#
# GET /v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/
# operationId: teams_billing_invoice_items_list
export def "teams-billing-invoices-invoice-items list" [
  team: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Get a specific team InvoiceItem.
#
# GET /v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/{id}
# operationId: teams_billing_invoice_items_read
export def "teams-billing-invoices-invoice-items get" [
  team: string
  invoice_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), invoice_id: (encode-path-segment $invoice_id), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get active team subscriptons
#
# GET /v1/teams/{team}/billing/subscriptions/
# operationId: teams_billing_subscriptions_list
export def "teams-billing-subscriptions list" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/billing/subscriptions/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create a new team subscription
#
# POST /v1/teams/{team}/billing/subscriptions/
# operationId: teams_billing_subscriptions_create
export def "teams-billing-subscriptions create" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  plan: string # Plan unique identifier.
]: any -> record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/billing/subscriptions/"))
  let req_body = {"plan": $plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a subscription
#
# DELETE /v1/teams/{team}/billing/subscriptions/{id}/
# operationId: teams_billing_subscriptions_delete
export def "teams-billing-subscriptions delete" [
  team: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/subscriptions/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get team subscriptions
#
# GET /v1/teams/{team}/billing/subscriptions/{id}/
# operationId: teams_billing_subscriptions_read
export def "teams-billing-subscriptions get" [
  team: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/subscriptions/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get team groups
#
# GET /v1/teams/{team}/groups/
# operationId: teams_groups_list
export def "teams-groups list" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting data.
  --offset: string # Offset when getting data.
]: nothing -> table<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/groups/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Delete team group
#
# DELETE /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_delete
export def "teams-groups delete" [
  team: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get team group
#
# GET /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_read
export def "teams-groups get" [
  team: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Patch team group
#
# PATCH /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_update
export def "teams-groups update-by-team-group" [
  team: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Group description
  name: string # Group name
  --parent: string # Parent group
  --private: oneof<nothing, bool> # States whether group is visible to all users.
]: any -> record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Patch team group
#
# PUT /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_replace
export def "teams-groups update-by-team-group-1" [
  team: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Group description
  name: string # Group name
  --parent: string # Parent group
  --private: oneof<nothing, bool> # States whether group is visible to all users.
]: any -> record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add user to group
#
# POST /v1/teams/{team}/groups/{group}/add/
# operationId: teams_groups_add_to_group
export def "teams-groups-add create" [
  team: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/add/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# User removed from group
#
# POST /v1/teams/{team}/groups/{group}/remove/
# operationId: teams_groups_remove_from_group
export def "teams-groups-remove delete" [
  team: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/remove/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get user list
#
# GET /v1/users/profiles/
# operationId: users_list
export def "users-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit user list.
  --offset: string # Offset when getting users.
  --username: string # User username.
  --email: string # User email.
  --ordering: string # Ordering when getting users.
]: nothing -> table<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/profiles/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "username": $username, "email": $email, "ordering": $ordering} | compact), body: null}
}

# Create new user
#
# POST /v1/users/profiles/
# operationId: users_create
# --profile shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
export def "users-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # User email.
  --first-name: string # User first name.
  --last-name: string # User last name.
  password: string # User password.
  profile: record # shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
  username: string # Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.
]: any -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/profiles/")
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "password": $password, "profile": $profile, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a user
#
# DELETE /v1/users/profiles/{user}/
# operationId: users_delete
export def "users-profiles delete" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/profiles/{user}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a user
#
# GET /v1/users/profiles/{user}/
# operationId: users_read
export def "users-profiles get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/profiles/{user}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a user
#
# PATCH /v1/users/profiles/{user}/
# operationId: users_update
# --profile shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
export def "users-profiles update" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # User email.
  --first-name: string # User first name.
  --last-name: string # User last name.
  password: string # User password.
  profile: record # shape: {avatar?: string, bio?: string, company?: string, location?: string, timezone?: string, url?: string}
  username: string # Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.
]: any -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/profiles/{user}/"))
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "password": $password, "profile": $profile, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve account's API key
#
# GET /v1/users/{user}/api-key/
# operationId: users_api-key_list
export def "users-api-key list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/api-key/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete avatar
#
# DELETE /v1/users/{user}/avatar/
# operationId: user_avatar_delete
export def "users-avatar delete" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve user's avatar
#
# GET /v1/users/{user}/avatar/
# operationId: user_avatar_get
export def "users-avatar get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a project file
#
# PATCH /v1/users/{user}/avatar/
# operationId: user_avatar_update
export def "users-avatar update-by-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add user avatar
#
# POST /v1/users/{user}/avatar/
# operationId: user_avatar_set
export def "users-avatar update-by-user-1" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve account email addresses
#
# GET /v1/users/{user}/emails/
# operationId: users_emails_list
export def "users-emails list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limite when getting email list.
  --offset: string # Offset when getting email list.
  --ordering: string # Ordering when getting email list.
]: nothing -> table<address: string, id: string, public: bool, unsubscribed: bool, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/emails/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create an email address
#
# POST /v1/users/{user}/emails/
# operationId: users_emails_create
export def "users-emails create" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: string # Email address.
  --public: oneof<nothing, bool> # Public or private email address.
  --unsubscribed: oneof<nothing, bool> # Unsubscribed or suscribed.
]: any -> record<address: string, id: string, public: bool, unsubscribed: bool, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/emails/"))
  let req_body = {"address": $address, "public": $public, "unsubscribed": $unsubscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an email address
#
# DELETE /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_delete
export def "users-emails delete" [
  user: string
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a user's email addresses
#
# GET /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_read
export def "users-emails get" [
  user: string
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<address: string, id: string, public: bool, unsubscribed: bool, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an email address
#
# PATCH /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_update
export def "users-emails update-by-user-email-id" [
  user: string
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: string # Email address.
  --public: oneof<nothing, bool> # Public or private email address.
  --unsubscribed: oneof<nothing, bool> # Unsubscribed or suscribed.
]: any -> record<address: string, id: string, public: bool, unsubscribed: bool, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/"))
  let req_body = {"address": $address, "public": $public, "unsubscribed": $unsubscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace an email address
#
# PUT /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_replace
export def "users-emails update-by-user-email-id-1" [
  user: string
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  address: string # Email address.
  --public: oneof<nothing, bool> # Public or private email address.
  --unsubscribed: oneof<nothing, bool> # Unsubscribed or suscribed.
]: any -> record<address: string, id: string, public: bool, unsubscribed: bool, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/"))
  let req_body = {"address": $address, "public": $public, "unsubscribed": $unsubscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve an SSH key
#
# GET /v1/users/{user}/ssh-key/
# operationId: users_ssh-key_list
export def "users-ssh-key list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/ssh-key/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Recreate an SSH key
#
# POST /v1/users/{user}/ssh-key/reset/
# operationId: users_ssh-key_reset
export def "users-ssh-key-reset reset" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/ssh-key/reset/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get credit cards
#
# GET /v1/{namespace}/billing/cards/
# operationId: billing_cards_list
export def "billing-cards list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Set limit when retrieving credit or debit cards.
  --offset: string # Set offset when retriving cards.
  --ordering: string # Order when retrieving cards.
]: nothing -> table<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/cards/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create new credit card
#
# POST /v1/{namespace}/billing/cards/
# operationId: billing_cards_create
export def "billing-cards create" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address-city: string # Address city.
  --address-country: string # Address country.
  --address-line1: string # Address line 1.
  --address-line2: string # Address line 2.
  --address-state: string # Address state.
  --address-zip: string # Address zip code.
  --exp-month: int # Card expiration month.
  --exp-year: int # Card expiration year.
  --name: string # Card name.
  --body-token: string # Card unique token.
]: any -> record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/cards/"))
  let req_body = {"address_city": $address_city, "address_country": $address_country, "address_line1": $address_line1, "address_line2": $address_line2, "address_state": $address_state, "address_zip": $address_zip, "exp_month": $exp_month, "exp_year": $exp_year, "name": $name, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a credit card
#
# DELETE /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_delete
export def "billing-cards delete" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get credit card by id
#
# GET /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_read
export def "billing-cards get" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a credit card
#
# PATCH /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_update
export def "billing-cards update-by-namespace-id" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address-city: string # Address city.
  --address-country: string # Address country.
  --address-line1: string # Address line 1.
  --address-line2: string # Address line 2.
  --address-state: string # Address state.
  --address-zip: string # Address zip code.
  --exp-month: int # Card expiration month.
  --exp-year: int # Card expiration year.
  --name: string # Card name.
]: any -> record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/"))
  let req_body = {"address_city": $address_city, "address_country": $address_country, "address_line1": $address_line1, "address_line2": $address_line2, "address_state": $address_state, "address_zip": $address_zip, "exp_month": $exp_month, "exp_year": $exp_year, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a credit card
#
# PUT /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_replace
export def "billing-cards update-by-namespace-id-1" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address-city: string # Address city.
  --address-country: string # Address country.
  --address-line1: string # Address line 1.
  --address-line2: string # Address line 2.
  --address-state: string # Address state.
  --address-zip: string # Address zip code.
  --exp-month: int # Card expiration month.
  --exp-year: int # Card expiration year.
  --name: string # Card name.
]: any -> record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/"))
  let req_body = {"address_city": $address_city, "address_country": $address_country, "address_line1": $address_line1, "address_line2": $address_line2, "address_state": $address_state, "address_zip": $address_zip, "exp_month": $exp_month, "exp_year": $exp_year, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get invoices
#
# GET /v1/{namespace}/billing/invoices/
# operationId: billing_invoices_list
export def "billing-invoices list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/invoices/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Get an invoice
#
# GET /v1/{namespace}/billing/invoices/{id}/
# operationId: billing_invoices_read
export def "billing-invoices get" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/invoices/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get invoice items for a given invoice.
#
# GET /v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/
# operationId: billing_invoice_items_list
export def "billing-invoices-invoice-items list" [
  namespace: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Get a specific InvoiceItem.
#
# GET /v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/{id}
# operationId: billing_invoice_items_read
export def "billing-invoices-invoice-items get" [
  namespace: string
  invoice_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), invoice_id: (encode-path-segment $invoice_id), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get billing plans
#
# GET /v1/{namespace}/billing/plans/
# operationId: billing_plans_list
export def "billing-plans list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> table<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/plans/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Get a billing plan
#
# GET /v1/{namespace}/billing/plans/{id}/
# operationId: billing_plans_read
export def "billing-plans get" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/plans/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get active subscriptons
#
# GET /v1/{namespace}/billing/subscriptions/
# operationId: billing_subscriptions_list
export def "billing-subscriptions list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
]: nothing -> table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/subscriptions/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create a new subscription
#
# POST /v1/{namespace}/billing/subscriptions/
# operationId: billing_subscriptions_create
export def "billing-subscriptions create" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  plan: string # Plan unique identifier.
]: any -> record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/subscriptions/"))
  let req_body = {"plan": $plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a subscription
#
# DELETE /v1/{namespace}/billing/subscriptions/{id}/
# operationId: billing_subscriptions_delete
export def "billing-subscriptions delete" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/subscriptions/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a subscriptions
#
# GET /v1/{namespace}/billing/subscriptions/{id}/
# operationId: billing_subscriptions_read
export def "billing-subscriptions get" [
  namespace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/subscriptions/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get notifications of all types and entities for the authenticated user.
#
# GET /v1/{namespace}/notifications/
# operationId: notifications_list
export def "notifications list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
  --read: oneof<nothing, bool> # When true, get only read notifications. When false, get only unread notifications. Default behavior is to return both read and unread.
]: nothing -> table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "read" $read "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering, "read": $read} | compact), body: null}
}

# Mark a list of notifications as either read or unread.
#
# PATCH /v1/{namespace}/notifications/
# operationId: notifications_update_list
export def "notifications update-list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  notifications: list<string> # An array of notification IDs to update.
  --read: oneof<nothing, bool> # Mark the notification as either read or unread
]: any -> record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/"))
  let req_body = {"notifications": $notifications, "read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get notifications of all types and entities for the authenticated user.
#
# GET /v1/{namespace}/notifications/entity/{entity}
# operationId: notifications_list_entity
export def "notifications-entity list" [
  namespace: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting items.
  --offset: string # Offset when getting items.
  --ordering: string # Ordering when getting items.
  --read: oneof<nothing, bool> # When true, get only read notifications. When false, get only unread notifications. Default behavior is to return both read and unread.
]: nothing -> table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "read" $read "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/entity/{entity}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering, "read": $read} | compact), body: null}
}

# Mark a list of notifications as either read or unread.
#
# PATCH /v1/{namespace}/notifications/entity/{entity}
# operationId: notifications_update_entity_list
export def "notifications-entity update-list" [
  namespace: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  notifications: list<string> # An array of notification IDs to update.
  --read: oneof<nothing, bool> # Mark the notification as either read or unread
]: any -> record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/entity/{entity}"))
  let req_body = {"notifications": $notifications, "read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve global notification settings for the authenticated user
#
# GET /v1/{namespace}/notifications/settings/
# operationId: notification_settings_read
export def "notifications-settings get" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/settings/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify global notification settings.
#
# PATCH /v1/{namespace}/notifications/settings/
# operationId: notification_settings_update
export def "notifications-settings update" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/settings/"))
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create global notification settings
#
# POST /v1/{namespace}/notifications/settings/
# operationId: notification_settings_create
export def "notifications-settings create" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/settings/"))
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve global notification settings for the authenticated user
#
# GET /v1/{namespace}/notifications/settings/entity/{entity}
# operationId: notification_settings_entity_read
export def "notifications-settings-entity get" [
  namespace: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/settings/entity/{entity}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify global notification settings.
#
# PATCH /v1/{namespace}/notifications/settings/entity/{entity}
# operationId: notification_settings_entity_update
export def "notifications-settings-entity update" [
  namespace: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/settings/entity/{entity}"))
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create global notification settings
#
# POST /v1/{namespace}/notifications/settings/entity/{entity}
# operationId: notification_settings_entity_create
export def "notifications-settings-entity create" [
  namespace: string
  entity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --emails-enabled: oneof<nothing, bool> # Turn emails on or off.
  --enabled: oneof<nothing, bool> # Turn notifications on or off entirely.
]: any -> record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/settings/entity/{entity}"))
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a specific notification.
#
# GET /v1/{namespace}/notifications/{notification_id}
# operationId: notification_read
export def "notifications get" [
  namespace: string
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notification_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), notification_id: (encode-path-segment $notification_id)} | format pattern "/v1/{namespace}/notifications/{notification_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Mark a specific notification as either read or unread.
#
# PATCH /v1/{namespace}/notifications/{notification_id}
# operationId: notification_update
export def "notifications update" [
  namespace: string
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --read: oneof<nothing, bool> # Mark the notification as either read or unread
]: any -> record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notification_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), notification_id: (encode-path-segment $notification_id)} | format pattern "/v1/{namespace}/notifications/{notification_id}"))
  let req_body = {"read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve oauth applications
#
# GET /v1/{namespace}/oauth/applications/
# operationId: oauth_applications_list
export def "oauth-applications list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Set limit when retrieving items.
  --offset: string # Offset when retrieving items.
  --ordering: string # Set order when retrieving items.
]: nothing -> table<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/oauth/applications/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create a new OAuth2 application
#
# POST /v1/{namespace}/oauth/applications/
# operationId: oauth_application_create
export def "oauth-applications create" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  authorization_grant_type: string@authorization-grant-type-completer # OAuth2 authorization grant type
  client_type: string@client-type-completer # OAuth2 client type
  name: string # Application name
  --redirect-uris: string # Uris to redirect auth request
]: any -> record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/oauth/applications/"))
  let req_body = {"authorization_grant_type": $authorization_grant_type, "client_type": $client_type, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an application by id
#
# DELETE /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_delete
export def "oauth-applications delete" [
  namespace: string
  application: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an application by id
#
# GET /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_read
export def "oauth-applications get" [
  namespace: string
  application: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an application by id
#
# PATCH /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_update
export def "oauth-applications update-by-namespace-application" [
  namespace: string
  application: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  authorization_grant_type: string@authorization-grant-type-completer # OAuth2 authorization grant type
  client_type: string@client-type-completer # OAuth2 client type
  name: string # Application name
  --redirect-uris: string # Uris to redirect auth request
]: any -> record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/"))
  let req_body = {"authorization_grant_type": $authorization_grant_type, "client_type": $client_type, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace an application by id
#
# PUT /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_replace
export def "oauth-applications update-by-namespace-application-1" [
  namespace: string
  application: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  authorization_grant_type: string@authorization-grant-type-completer # OAuth2 authorization grant type
  client_type: string@client-type-completer # OAuth2 client type
  name: string # Application name
  --redirect-uris: string # Uris to redirect auth request
]: any -> record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/"))
  let req_body = {"authorization_grant_type": $authorization_grant_type, "client_type": $client_type, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get available projects
#
# GET /v1/{namespace}/projects/
# operationId: projects_list
export def "projects list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting data.
  --offset: string # Offset when getting data.
  --private: string # Private project or public project.
  --name: string # Project name.
  --ordering: string # Ordering when getting projects.
]: nothing -> table<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "private": $private, "name": $name, "ordering": $ordering} | compact), body: null}
}

# Create a new project
#
# POST /v1/{namespace}/projects/
# operationId: projects_create
export def "projects create" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Project description.
  name: string # Project name.
  --private: oneof<nothing, bool> # Private project true, otherwise public.
]: any -> record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/"))
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check if you are able to copy a project to your account.
#
# HEAD /v1/{namespace}/projects/project-copy-check/
# operationId: project_copy_check
export def "projects-project-copy-check copy" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  project: string # UUID of the project the user wishes to copy.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/project-copy-check/"))
  let req_body = {"project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Copy a project to your own account.
#
# POST /v1/{namespace}/projects/project-copy/
# operationId: project_copy
export def "projects-project-copy copy" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name for the newly copied project
  project: string # UUID of the project the user wishes to copy.
]: any -> record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/project-copy/"))
  let req_body = {"name": $name, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a project
#
# DELETE /v1/{namespace}/projects/{project}/
# operationId: projects_delete
export def "projects delete" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a project
#
# GET /v1/{namespace}/projects/{project}/
# operationId: projects_read
export def "projects get" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a project
#
# PATCH /v1/{namespace}/projects/{project}/
# operationId: projects_update
export def "projects update-by-namespace-project" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Project description.
  name: string # Project name.
  --private: oneof<nothing, bool> # Private project true, otherwise public.
]: any -> record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/"))
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a project
#
# PUT /v1/{namespace}/projects/{project}/
# operationId: projects_replace
export def "projects update-by-namespace-project-1" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Project description.
  name: string # Project name.
  --private: oneof<nothing, bool> # Private project true, otherwise public.
]: any -> record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/"))
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get project collaborators
#
# GET /v1/{namespace}/projects/{project}/collaborators/
# operationId: projects_collaborators_list
export def "projects-collaborators list" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when retrieving items.
  --offset: string # Offset when retrieving items.
  --ordering: string # Ordering when retrieving items.
]: nothing -> table<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create project collaborators
#
# POST /v1/{namespace}/projects/{project}/collaborators/
# operationId: projects_collaborators_create
export def "projects-collaborators create" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  member: string # Project member username.
  --owner: oneof<nothing, bool> # Project owner. Defaults to false.
  permissions: string@permissions-completer # Permissions assigned to collaborator.
]: any -> record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/"))
  let req_body = {"member": $member, "owner": $owner, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a project collaborator
#
# DELETE /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_delete
export def "projects-collaborators delete" [
  namespace: string
  project: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), collaborator: (encode-path-segment $collaborator)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a project collaborator
#
# GET /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_read
export def "projects-collaborators get" [
  namespace: string
  project: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), collaborator: (encode-path-segment $collaborator)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update project collaborator
#
# PATCH /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_update
export def "projects-collaborators update" [
  namespace: string
  project: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  member: string # Project member username.
  --owner: oneof<nothing, bool> # Project owner. Defaults to false.
  permissions: string@permissions-completer # Permissions assigned to collaborator.
]: any -> record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), collaborator: (encode-path-segment $collaborator)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/"))
  let req_body = {"member": $member, "owner": $owner, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve deployments
#
# GET /v1/{namespace}/projects/{project}/deployments/
# operationId: projects_deployments_list
export def "projects-deployments list" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit results when getting deployment list.
  --offset: string # Offset results when getting deployment list.
  --name: string # Server name.
  --ordering: string # Ordering option when getting deployment list.
]: nothing -> table<config: record<files: list, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/deployments/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "name": $name, "ordering": $ordering} | compact), body: null}
}

# Create a new deployment
#
# POST /v1/{namespace}/projects/{project}/deployments/
# operationId: projects_deployments_create
# --config shape: {files?: list<string>, handler?: string}
export def "projects-deployments create" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  config: record # shape: {files?: list<string>, handler?: string}
  framework: string@framework-completer # Framework that the deployment will have access to.
  name: string # Deployment name.
  runtime: string@runtime-completer # Language runtime the deployment will use.
]: any -> record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/deployments/"))
  let req_body = {"config": $config, "framework": $framework, "name": $name, "runtime": $runtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a deployment
#
# DELETE /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployment_delete
export def "projects-deployments delete" [
  namespace: string
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a deployment
#
# GET /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployments_read
export def "projects-deployments get" [
  namespace: string
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a deployment
#
# PATCH /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployments_update
# --config shape: {files?: list<string>, handler?: string}
export def "projects-deployments update-by-namespace-project-deployment" [
  namespace: string
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  config: record # shape: {files?: list<string>, handler?: string}
  framework: string@framework-completer # Framework that the deployment will have access to.
  name: string # Deployment name.
  runtime: string@runtime-completer # Language runtime the deployment will use.
]: any -> record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/"))
  let req_body = {"config": $config, "framework": $framework, "name": $name, "runtime": $runtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a deployment
#
# PUT /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployments_replace
# --config shape: {files?: list<string>, handler?: string}
export def "projects-deployments update-by-namespace-project-deployment-1" [
  namespace: string
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  config: record # shape: {files?: list<string>, handler?: string}
  framework: string@framework-completer # Framework that the deployment will have access to.
  name: string # Deployment name.
  runtime: string@runtime-completer # Language runtime the deployment will use.
]: any -> record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/"))
  let req_body = {"config": $config, "framework": $framework, "name": $name, "runtime": $runtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deploy an existing model
#
# POST /v1/{namespace}/projects/{project}/deployments/{deployment}/deploy/
# operationId: projects_deployments_deploy
export def "projects-deployments-deploy create" [
  namespace: string
  project: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/deploy/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get project files
#
# GET /v1/{namespace}/projects/{project}/project_files/
# operationId: projects_project_files_list
export def "projects-project-files list" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit when getting project file list.
  --offset: string # Offset when getting project file list.
  --ordering: string # Ordering of list values when getting project file list.
  --filename: string # Exact file name, relative to the project root. If no such file is found, an empty list will be returned.
  --content: string # Determines whether or not content is returned as base64. Defaults to false.
]: nothing -> table<content: string, id: string, name: string, path: string, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "content" $content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/project_files/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering, "filename": $filename, "content": $content} | compact), body: null}
}

# Create project files
#
# POST /v1/{namespace}/projects/{project}/project_files/
# operationId: projects_project_files_create
export def "projects-project-files create" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --file: path # File to send, to create new file. This parameter is only used with form data and may include multiple files.
  --base64-data: string # Fila data, represented as base64.
  --name: string # File name. May include path when creating file with base64 field.
  --path: string # File path. Defaults to (/).
]: any -> record<content: string, id: string, name: string, path: string, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/project_files/"))
  let req_body = {"file": $file, "base64_data": $base64_data, "name": $name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete a project file
#
# DELETE /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_delete
export def "projects-project-files delete" [
  namespace: string
  project: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a project file
#
# GET /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_read
export def "projects-project-files get" [
  namespace: string
  project: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content: string # Determines whether or not content is returned as base64. Defaults to false.
]: nothing -> record<content: string, id: string, name: string, path: string, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "content" $content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"content": $content} | compact), body: null}
}

# Update a project file
#
# PATCH /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_update
export def "projects-project-files update-by-namespace-project-id" [
  namespace: string
  project: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --file: path # File to send, to create new file. This parameter is only used with form data and may include multiple files.
  --base64-data: string # Fila data, represented as base64.
  --name: string # File name. May include path when creating file with base64 field.
  --path: string # File path. Defaults to (/).
]: any -> record<content: string, id: string, name: string, path: string, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/"))
  let req_body = {"file": $file, "base64_data": $base64_data, "name": $name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Replace a project file
#
# PUT /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_replace
export def "projects-project-files update-by-namespace-project-id-1" [
  namespace: string
  project: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --file: path # File to send, to create new file. This parameter is only used with form data and may include multiple files.
  --base64-data: string # Fila data, represented as base64.
  --name: string # File name. May include path when creating file with base64 field.
  --path: string # File path. Defaults to (/).
]: any -> record<content: string, id: string, name: string, path: string, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/"))
  let req_body = {"file": $file, "base64_data": $base64_data, "name": $name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Retrieve servers
#
# GET /v1/{namespace}/projects/{project}/servers/
# operationId: projects_servers_list
export def "projects-servers list" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit results when getting server list.
  --offset: string # Offset results when getting server list.
  --name: string # Server name.
  --ordering: string # Ordering option when getting server list.
]: nothing -> table<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/servers/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "name": $name, "ordering": $ordering} | compact), body: null}
}

# Create a new server
#
# POST /v1/{namespace}/projects/{project}/servers/
# operationId: projects_servers_create
# --config shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
export def "projects-servers create" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config: record # shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
  --connected: list<string> # Array of other servers the server is connected to.
  --host: string # External host IPv4 address or hostname.
  --image-name: string # Image name.
  name: string # Server name.
  --server-size: string # Server size unique identifier.
  --startup-script: string # Startup script to run when launching server.
]: any -> record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/servers/"))
  let req_body = {"config": $config, "connected": $connected, "host": $host, "image_name": $image_name, "name": $name, "server_size": $server_size, "startup_script": $startup_script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve server statuses
#
# GET /v1/{namespace}/projects/{project}/servers/statuses/
# operationId: projects_servers_statuses
export def "projects-servers-statuses get" [
  namespace: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/servers/statuses/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a server
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_delete
export def "projects-servers delete" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_read
export def "projects-servers get" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a server
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_update
# --config shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
export def "projects-servers update-by-namespace-project-server" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config: record # shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
  --connected: list<string> # Array of other servers the server is connected to.
  --host: string # External host IPv4 address or hostname.
  --image-name: string # Image name.
  name: string # Server name.
  --server-size: string # Server size unique identifier.
  --startup-script: string # Startup script to run when launching server.
]: any -> record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/"))
  let req_body = {"config": $config, "connected": $connected, "host": $host, "image_name": $image_name, "name": $name, "server_size": $server_size, "startup_script": $startup_script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a server
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_replace
# --config shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
export def "projects-servers update-by-namespace-project-server-1" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config: record # shape: {command?: string, function?: string, script?: string, type?: "jupyter"|"restful"|"cron"}
  --connected: list<string> # Array of other servers the server is connected to.
  --host: string # External host IPv4 address or hostname.
  --image-name: string # Image name.
  name: string # Server name.
  --server-size: string # Server size unique identifier.
  --startup-script: string # Startup script to run when launching server.
]: any -> record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/"))
  let req_body = {"config": $config, "connected": $connected, "host": $host, "image_name": $image_name, "name": $name, "server_size": $server_size, "startup_script": $startup_script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get server API key
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/api-key/
# operationId: projects_servers_api-key
export def "projects-servers-api-key get" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/api-key/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Server api key validation
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/auth/
# operationId: projects_servers_auth
export def "projects-servers-auth create" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/auth/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new server's run statistics
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/run-stats/
# operationId: projects_servers_run-stats_create
export def "projects-servers-run-stats create" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --exit-code: int # Server exit code.
  --size: int # Server size.
  --stacktrace: string # Server stacktrace.
  --start: string # Server start.
  --stop: string # Server stop.
]: any -> record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/"))
  let req_body = {"exit_code": $exit_code, "size": $size, "stacktrace": $stacktrace, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a server's statistics
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_delete
export def "projects-servers-run-stats delete" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve statistics for a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_read
export def "projects-servers-run-stats get" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a server's statistics
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_update
export def "projects-servers-run-stats update-by-namespace-project-server-id" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --exit-code: int # Server exit code.
  --size: int # Server size.
  --stacktrace: string # Server stacktrace.
  --start: string # Server start.
  --stop: string # Server stop.
]: any -> record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"))
  let req_body = {"exit_code": $exit_code, "size": $size, "stacktrace": $stacktrace, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a server's statistics
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_replace
export def "projects-servers-run-stats update-by-namespace-project-server-id-1" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --exit-code: int # Server exit code.
  --size: int # Server size.
  --stacktrace: string # Server stacktrace.
  --start: string # Server start.
  --stop: string # Server stop.
]: any -> record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/"))
  let req_body = {"exit_code": $exit_code, "size": $size, "stacktrace": $stacktrace, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get SSH Tunnels associated to a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/
# operationId: projects_servers_ssh-tunnels_list
export def "projects-servers-ssh-tunnels list" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --limit: string # Limit retrieved items.
  --offset: string # Offset retrieved items.
  --ordering: string # Order retrieved items.
]: nothing -> table<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create SSH Tunnel associated to a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/
# operationId: projects_servers_ssh-tunnels_create
export def "projects-servers-ssh-tunnels create" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  endpoint: string # SSH tunnel endpoint.
  host: string # SSH tunnel host.
  local_port: int # SSH tunnel local port.
  name: string # SSH tunnel name.
  remote_port: int # SSH tunnel remote port.
  username: string # User name to establish SSH tunnel.
]: any -> record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/"))
  let req_body = {"endpoint": $endpoint, "host": $host, "local_port": $local_port, "name": $name, "remote_port": $remote_port, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an SSH Tunnel associated to a server
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_delete
export def "projects-servers-ssh-tunnels delete" [
  namespace: string
  project: string
  server: string
  tunnel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an SSH Tunnel associated to a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_read
export def "projects-servers-ssh-tunnels get" [
  namespace: string
  project: string
  server: string
  tunnel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an SSH Tunnel associated to a server
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_update
export def "projects-servers-ssh-tunnels update-by-namespace-project-server-tunnel" [
  namespace: string
  project: string
  server: string
  tunnel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  endpoint: string # SSH tunnel endpoint.
  host: string # SSH tunnel host.
  local_port: int # SSH tunnel local port.
  name: string # SSH tunnel name.
  remote_port: int # SSH tunnel remote port.
  username: string # User name to establish SSH tunnel.
]: any -> record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"))
  let req_body = {"endpoint": $endpoint, "host": $host, "local_port": $local_port, "name": $name, "remote_port": $remote_port, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace SSH Tunnel associated to a server
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_replace
export def "projects-servers-ssh-tunnels update-by-namespace-project-server-tunnel-1" [
  namespace: string
  project: string
  server: string
  tunnel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  endpoint: string # SSH tunnel endpoint.
  host: string # SSH tunnel host.
  local_port: int # SSH tunnel local port.
  name: string # SSH tunnel name.
  remote_port: int # SSH tunnel remote port.
  username: string # User name to establish SSH tunnel.
]: any -> record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/"))
  let req_body = {"endpoint": $endpoint, "host": $host, "local_port": $local_port, "name": $name, "remote_port": $remote_port, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Start a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/start/
# operationId: projects_servers_start
export def "projects-servers-start start" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/start/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a server's statistics
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_delete
export def "projects-servers-stats delete" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a server's statistics
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_read
export def "projects-servers-stats get" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, server: string, size: int, start: string, stop: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a server's statistics
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_update
export def "projects-servers-stats update-by-namespace-project-server-id" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-id: list<string> # id field errors.
  --non-field-errors: list<string> # Errors not connected to any field.
  --size: list<string> # size field errors.
  --start: list<string> # start field errors.
  --stop: list<string> # stop field errors.
]: any -> record<id: string, server: string, size: int, start: string, stop: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"))
  let req_body = {"id": $body_id, "non_field_errors": $non_field_errors, "size": $size, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a server's statistics
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_replace
export def "projects-servers-stats update-by-namespace-project-server-id-1" [
  namespace: string
  project: string
  server: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-id: list<string> # id field errors.
  --non-field-errors: list<string> # Errors not connected to any field.
  --size: list<string> # size field errors.
  --start: list<string> # start field errors.
  --stop: list<string> # stop field errors.
]: any -> record<id: string, server: string, size: int, start: string, stop: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/"))
  let req_body = {"id": $body_id, "non_field_errors": $non_field_errors, "size": $size, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stop a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/stop/
# operationId: projects_servers_stop
export def "projects-servers-stop stop" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stop/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve server triggers
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/triggers/
# operationId: service_trigger_list
export def "projects-servers-triggers list-service" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Trigger name.
  --limit: string # Limit when getting triggers.
  --offset: string # Offset when getting triggers.
  --ordering: string # Ordering when getting triggers.
]: nothing -> table<id: string, name: string, operation: string, webhook: record<payload: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "limit": $limit, "offset": $offset, "ordering": $ordering} | compact), body: null}
}

# Create a new server trigger
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/triggers/
# operationId: service_trigger_create
# --webhook shape: {payload?: record, url: string}
export def "projects-servers-triggers create-service" [
  namespace: string
  project: string
  server: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of server action.
  --operation: string@operation-completer # Manage server state. Starting a server changes state from Pending to Running. Terminating a server changes state from Running to Terminated. Stopping a server changes state from Running to Stopped. If the action results in Error, status will change to Error.
  --webhook: record # shape: {payload?: record, url: string}
]: any -> record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/"))
  let req_body = {"name": $name, "operation": $operation, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a server trigger
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_delete
export def "projects-servers-triggers delete-service" [
  namespace: string
  project: string
  server: string
  trigger: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a server trigger
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_read
export def "projects-servers-triggers get-service" [
  namespace: string
  project: string
  server: string
  trigger: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a server trigger
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_update
# --webhook shape: {payload?: record, url: string}
export def "projects-servers-triggers update-service-by-namespace-project-server-trigger" [
  namespace: string
  project: string
  server: string
  trigger: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of server action.
  --operation: string@operation-completer # Manage server state. Starting a server changes state from Pending to Running. Terminating a server changes state from Running to Terminated. Stopping a server changes state from Running to Stopped. If the action results in Error, status will change to Error.
  --webhook: record # shape: {payload?: record, url: string}
]: any -> record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"))
  let req_body = {"name": $name, "operation": $operation, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replace a server trigger
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_replace
# --webhook shape: {payload?: record, url: string}
export def "projects-servers-triggers update-service-by-namespace-project-server-trigger-1" [
  namespace: string
  project: string
  server: string
  trigger: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of server action.
  --operation: string@operation-completer # Manage server state. Starting a server changes state from Pending to Running. Terminating a server changes state from Running to Terminated. Stopping a server changes state from Running to Stopped. If the action results in Error, status will change to Error.
  --webhook: record # shape: {payload?: record, url: string}
]: any -> record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/"))
  let req_body = {"name": $name, "operation": $operation, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a search results
#
# GET /v1/{namespace}/search/
# operationId: search
export def "search list" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --q: string # Search string.
  --type: string@type-completer # Limit results to specific types.
  --limit: string # Limit data when getting items.
  --offset: string # Offset data when getting items.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/search/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "type": $type, "limit": $limit, "offset": $offset} | compact), body: null}
}
