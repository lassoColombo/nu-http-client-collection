# Auto-generated client for Cenit IO - REST API Specification vv1
# Source: https://api.apis.guru/v2/specs/cenit.io/v1/swagger.json
# Auth: --token flag or $env.CENIT_IO_REST_API_SPECIFICATION_TOKEN

const BASE_URL = "https://cenit.io/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CENIT_IO_REST_API_SPECIFICATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-user-access-key" => { {scheme: $scheme, headers: {X-User-Access-Key: $token_val}, query: "", location: "header"} }
    "x-user-access-token" => { {scheme: $scheme, headers: {X-User-Access-Token: $token_val}, query: "", location: "header"} }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://cenit.io/api/v1"] }
def auth-scheme-completer [] { ["x-user-access-key" "x-user-access-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<headers: list<record>, id: string, key: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, token: string, url: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a connection
#
# POST /setup/connection
export def "setup-connection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, key: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, token: string, url: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a connection
#
# DELETE /setup/connection/{id}
export def "setup-connection delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/connection/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing connection
#
# GET /setup/connection/{id}
export def "setup-connection get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, key: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, token: string, url: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/connection/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of connection roles
#
# GET /setup/connection_role
export def "setup-connection-role list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<connection: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: list<record>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection_role" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a connection role
#
# POST /setup/connection_role
export def "setup-connection-role create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connection: table<headers: list, id: string, key: string, name: string, namespace: record, parameters: list, token: string, url: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: table<headers: list, id: string, name: string, namespace: record, parameters: list, path: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/connection_role" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a connection role.
#
# DELETE /setup/connection_role/{id}
export def "setup-connection-role delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/connection_role/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Return a connection role
#
# GET /setup/connection_role/{id}
export def "setup-connection-role get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connection: table<headers: list, id: string, key: string, name: string, namespace: record, parameters: list, token: string, url: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: table<headers: list, id: string, name: string, namespace: record, parameters: list, path: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/connection_role/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of data types
#
# GET /setup/data_type/
export def "setup-data-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/data_type/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a data type
#
# POST /setup/data_type/
export def "setup-data-type create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/data_type/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a data type
#
# DELETE /setup/data_type/{id}
export def "setup-data-type delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/data_type/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a data type
#
# GET /setup/data_type/{id}
export def "setup-data-type get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/data_type/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of flows
#
# GET /setup/flow/
export def "setup-flow list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, connection_role: record<connection: list, id: string, name: string, namespace: record, webhook: list>, custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, event: record, id: string, name: string, namespace: record<id: string, name: string, slug: string>, notify_request: bool, notify_response: bool, response_translator: record<custom_data_type: record, id: string, name: string, namespace: record, source_data_type: record, style: string, target_data_type: record, transformation: string, type: string>, translator: record<custom_data_type: record, id: string, name: string, namespace: record, source_data_type: record, style: string, target_data_type: record, transformation: string, type: string>, webhook: record<headers: list, id: string, name: string, namespace: record, parameters: list, path: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/flow/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a flow
#
# POST /setup/flow/
export def "setup-flow create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, connection_role: record<connection: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: list<record>>, custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, event: record, id: string, name: string, namespace: record<id: string, name: string, slug: string>, notify_request: bool, notify_response: bool, response_translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, webhook: record<headers: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, path: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/flow/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a flow.
#
# DELETE /setup/flow/{id}
export def "setup-flow delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/flow/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing flow
#
# GET /setup/flow/{id}
export def "setup-flow get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, connection_role: record<connection: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, webhook: list<record>>, custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, event: record, id: string, name: string, namespace: record<id: string, name: string, slug: string>, notify_request: bool, notify_response: bool, response_translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, translator: record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string>, webhook: record<headers: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, path: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/flow/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of namespaces
#
# GET /setup/namespace/
export def "setup-namespace list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, slug: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/namespace/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a namespace
#
# POST /setup/namespace/
export def "setup-namespace create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/namespace/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a namespace
#
# DELETE /setup/namespace/{id}
export def "setup-namespace delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/namespace/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing namespace
#
# GET /setup/namespace/{id}
export def "setup-namespace get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/namespace/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of events
#
# GET /setup/observer/
export def "setup-observer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, triggers: string, type: record> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/observer/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update an event
#
# POST /setup/observer/
export def "setup-observer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, triggers: string, type: record> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/observer/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete an event
#
# DELETE /setup/observer/{id}
export def "setup-observer delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/observer/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing event
#
# GET /setup/observer/{id}
export def "setup-observer get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, triggers: string, type: record> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/observer/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of schedulers
#
# GET /setup/scheduler/
export def "setup-scheduler list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<activated: bool, expression: string, id: string, name: string, namespace: record<id: string, name: string, slug: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/scheduler/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update an scheduler
#
# POST /setup/scheduler/
export def "setup-scheduler create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activated: bool, expression: string, id: string, name: string, namespace: record<id: string, name: string, slug: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/scheduler/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete an schedule
#
# DELETE /setup/scheduler/{id}
export def "setup-scheduler delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/scheduler/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing schedule
#
# GET /setup/scheduler/{id}
export def "setup-scheduler get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activated: bool, expression: string, id: string, name: string, namespace: record<id: string, name: string, slug: string>> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/scheduler/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of schemas
#
# GET /setup/schema/
export def "setup-schema list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, namespace: record<id: string, name: string, slug: string>, schema: string, uri: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/schema/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update an schema
#
# POST /setup/schema/
export def "setup-schema create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, namespace: record<id: string, name: string, slug: string>, schema: string, uri: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/schema/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete an schema.
#
# DELETE /setup/schema/{id}
export def "setup-schema delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/schema/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing schema
#
# GET /setup/schema/{id}
export def "setup-schema get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, namespace: record<id: string, name: string, slug: string>, schema: string, uri: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/schema/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of translators
#
# GET /setup/translator/
export def "setup-translator list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/translator/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a translator
#
# POST /setup/translator/
export def "setup-translator create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/translator/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a translator
#
# DELETE /setup/translator/{id}
export def "setup-translator delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/translator/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing translator
#
# GET /setup/translator/{id}
export def "setup-translator get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<custom_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, source_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, style: string, target_data_type: record<id: string, model_schema: string, name: string, namespace: record<id: string, name: string, slug: string>, show_navigation_link: string, slug: string, title: string, type: record>, transformation: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/translator/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of webhooks
#
# GET /setup/webhook/
export def "setup-webhook list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<headers: list<record>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: list<record>, path: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/webhook/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a webhook
#
# POST /setup/webhook/
export def "setup-webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, path: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/webhook/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete a webhook
#
# DELETE /setup/webhook/{id}
export def "setup-webhook delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/webhook/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an existing webhook
#
# GET /setup/webhook/{id}
export def "setup-webhook get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-xuseraccesskey: string # Auth token for X-User-Access-Key (X-User-Access-Key)
  --token-xuseraccesstoken: string # Auth token for X-User-Access-Token (X-User-Access-Token)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<headers: table<key: string, value: string>, id: string, name: string, namespace: record<id: string, name: string, slug: string>, parameters: table<key: string, value: string>, path: string> {
  let auth = (merge-auth [(build-auth ($token_xuseraccesskey | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSKEY_TOKEN | default "")) "x-user-access-key") (build-auth ($token_xuseraccesstoken | default ($env | get -o CENIT_IO_REST_API_SPECIFICATION_XUSERACCESSTOKEN_TOKEN | default "")) "x-user-access-token")])
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/webhook/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
