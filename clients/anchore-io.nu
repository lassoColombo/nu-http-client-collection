# Auto-generated client for Anchore Engine API Server v0.1.20
# Source: https://api.apis.guru/v2/specs/anchore.io/0.1.20/openapi.json
# Auth: --token flag or $env.ANCHORE_ENGINE_API_SERVER_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ANCHORE_ENGINE_API_SERVER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
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

def base-url-completer [] { ["http://localhost" "http://anchore.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["deleting" "disabled" "enabled"] }
def state-completer-1 [] { ["disabled" "enabled"] }
def credential-type-completer [] { ["password"] }
def type-completer [] { ["password"] }
def transition-completer [] { ["archive" "delete"] }
def image-status-completer [] { ["active" "all" "deleting"] }
def analysis-status-completer [] { ["analysis_failed" "analyzed" "analyzing" "not_analyzed"] }
def severity-completer [] { ["Critical" "High" "Low" "Medium" "Negligible" "Unknown"] }
def notification-type-completer [] { ["analysis_update" "policy_eval" "tag_update" "vuln_update"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api ping" } } | get name | first)
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

# Simple status check
#
# GET /
# operationId: ping
export def "api ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
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

# List the account for the authenticated user
#
# GET /account
# operationId: get_users_account
export def "account get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
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

# List user summaries. Only available to the system admin user.
#
# GET /accounts
# operationId: list_accounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Filter accounts by state
]: nothing -> table<created_at: string, email: string, last_updated: string, name: string, state: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new user. Only avaialble to admin user.
#
# POST /accounts
# operationId: create_account
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An optional email to associate with the account for contact purposes
  name: string # The account name to use. This will identify the account and must be globally unique in the system.
]: any -> record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts" $auth.query)
  let req_body = {"email": $email, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete the specified account, only allowed if the account is in the disabled state. All users will be deleted along with the account and all resources will be garbage collected
#
# DELETE /accounts/{accountname}
# operationId: delete_account
export def "accounts delete" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname)} | format pattern "/accounts/{accountname}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get info about an user. Only available to admin user. Uses the main user Id, not a username.
#
# GET /accounts/{accountname}
# operationId: get_account
export def "accounts get" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname)} | format pattern "/accounts/{accountname}") $auth.query)
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

# Update the state of an account to either enabled or disabled. For deletion use the DELETE route
#
# PUT /accounts/{accountname}/state
# operationId: update_account_state
export def "accounts-state update" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # The status of the account
]: any -> record<state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname)} | format pattern "/accounts/{accountname}/state") $auth.query)
  let req_body = {"state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List accounts for the user
#
# GET /accounts/{accountname}/users
# operationId: list_users
export def "accounts-users list" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, last_updated: string, source: string, type: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname)} | format pattern "/accounts/{accountname}/users") $auth.query)
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

# Create a new user
#
# POST /accounts/{accountname}/users
# operationId: create_user
export def "accounts-users create" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The initial password for the user, must be at least 6 characters, up to 128
  username: string # The username to create
]: any -> record<created_at: string, last_updated: string, source: string, type: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname)} | format pattern "/accounts/{accountname}/users") $auth.query)
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a specific user credential by username of the credential. Cannot be the credential used to authenticate the request.
#
# DELETE /accounts/{accountname}/users/{username}
# operationId: delete_user
export def "accounts-users delete" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname), username: (encode-path-segment $username)} | format pattern "/accounts/{accountname}/users/{username}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific user in the specified account
#
# GET /accounts/{accountname}/users/{username}
# operationId: get_account_user
export def "accounts-users get" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, last_updated: string, source: string, type: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname), username: (encode-path-segment $username)} | format pattern "/accounts/{accountname}/users/{username}") $auth.query)
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

# Delete a credential by type
#
# DELETE /accounts/{accountname}/users/{username}/credentials
# operationId: delete_user_credential
export def "accounts-users-credentials delete" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credential-type: string@credential-type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "credential_type" $credential_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname), username: (encode-path-segment $username)} | format pattern "/accounts/{accountname}/users/{username}/credentials") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"credential_type": $credential_type} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get current credential summary
#
# GET /accounts/{accountname}/users/{username}/credentials
# operationId: list_user_credentials
export def "accounts-users-credentials list" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname), username: (encode-path-segment $username)} | format pattern "/accounts/{accountname}/users/{username}/credentials") $auth.query)
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

# add/replace credential
#
# POST /accounts/{accountname}/users/{username}/credentials
# operationId: create_user_credential
export def "accounts-users-credentials create" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The timestamp of creation of the credential
  type: string@type-completer # The type of credential
  value: string # The credential value (e.g. the password)
]: any -> record<created_at: string, last_updated: string, source: string, type: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accountname | is-empty) { error make --unspanned { msg: "path parameter 'accountname' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({accountname: (encode-path-segment $accountname), username: (encode-path-segment $username)} | format pattern "/accounts/{accountname}/users/{username}/credentials") $auth.query)
  let req_body = {"created_at": $created_at, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# GET /archives
#
# operationId: list_archives
export def "archives list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<images: record<last_updated: string, total_data_bytes: int, total_image_count: int, total_tag_count: int>, rules: record<count: int, last_updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives" $auth.query)
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

# GET /archives/images
#
# operationId: list_analysis_archive
export def "archives-images list-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<analyzed_at: string, annotations: record, archive_size_bytes: int, created_at: string, imageDigest: string, image_detail: list<record>, last_updated: string, parentDigest: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/images" $auth.query)
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

# POST /archives/images
#
# operationId: archive_image_analysis
export def "archives-images archive-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<detail: string, digest: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/images" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Performs a synchronous archive deletion
#
# DELETE /archives/images/{imageDigest}
# operationId: delete_archived_analysis
export def "archives-images delete-archived-analysis" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/archives/images/{image_digest}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"force": $force} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns the archive metadata record identifying the image and tags for the analysis in the archive.
#
# GET /archives/images/{imageDigest}
# operationId: get_archived_analysis
export def "archives-images get-archived-analysis" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<analyzed_at: string, annotations: record, archive_size_bytes: int, created_at: string, imageDigest: string, image_detail: table<detected_at: string, pullstring: string, registry: string, repository: string, tag: string>, last_updated: string, parentDigest: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/archives/images/{image_digest}") $auth.query)
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

# GET /archives/rules
#
# operationId: list_analysis_archive_rules
export def "archives-rules list-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --system-global: oneof<nothing, bool> # If true include system global rules (owned by admin) even for non-admin users. Defaults to true if not set. Can be set to false to exclude globals
]: nothing -> table<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "system_global" $system_global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/archives/rules" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"system_global": $system_global} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /archives/rules
#
# operationId: create_analysis_archive_rule
# --exclude shape: {expiration_days?: int, selector?: record}
# --selector shape: {registry?: string, repository?: string, tag?: string}
export def "archives-rules create-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --analysis-age-days: int # Matches if the analysis is strictly older than this number of days
  --created-at: string # format: date-time
  --exclude: record # Which Images to exclude from auto-archiving logic — shape: {expiration_days?: int, selector?: record}
  --last-updated: string # format: date-time
  --max-images-per-account: int # This is the maximum number of image analyses an account can have. Can only be set on system_global rules
  --rule-id: string # Unique identifier for archive rule
  --selector: record # A set of selection criteria to match an image by a tagged pullstring based on its components, with regex support in each field — shape: {registry?: string, repository?: string, tag?: string}
  --system-global: oneof<nothing, bool> # True if the rule applies to all accounts in the system. This is only available to admin users to update/modify, but all users with permission to list rules can see them
  --tag-versions-newer: int # Number of images mapped to the tag that are newer
  transition: string@transition-completer # The type of transition to make. If "archive", then archive an image from the working set and remove it from the working set. If "delete", then match against archived images and delete from the archive if match.
]: any -> record<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record<registry: string, repository: string, tag: string>>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/archives/rules" $auth.query)
  let req_body = {"analysis_age_days": $analysis_age_days, "created_at": $created_at, "exclude": $exclude, "last_updated": $last_updated, "max_images_per_account": $max_images_per_account, "rule_id": $rule_id, "selector": $selector, "system_global": $system_global, "tag_versions_newer": $tag_versions_newer, "transition": $transition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DELETE /archives/rules/{ruleId}
#
# operationId: delete_analysis_archive_rule
export def "archives-rules delete-analysis" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/archives/rules/{rule_id}") $auth.query)
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

# GET /archives/rules/{ruleId}
#
# operationId: get_analysis_archive_rule
export def "archives-rules get-analysis" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record<registry: string, repository: string, tag: string>>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/archives/rules/{rule_id}") $auth.query)
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

# List Event Types
#
# GET /event_types
# operationId: list_event_types
export def "event-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, description: string, subcategories: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event_types" $auth.query)
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

# Delete Events
#
# DELETE /events
# operationId: delete_events
export def "events delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Delete events that occurred before the timestamp
  --since: string # Delete events that occurred after the timestamp
  --level: string # Delete events that match the level - INFO or ERROR
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "level" $level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"before": $before, "since": $since, "level": $level} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# List Events
#
# GET /events
# operationId: list_events
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-servicename: string # Filter events by the originating service
  --source-hostid: string # Filter events by the originating host ID
  --event-type: string # Filter events by a prefix match on the event type (e.g. "user.image.")
  --resource-type: string # Filter events by the type of resource - tag, imageDigest, repository etc
  --resource-id: string # Filter events by the id of the resource
  --level: string # Filter events by the level - INFO or ERROR
  --since: string # Return events that occurred after the timestamp
  --before: string # Return events that occurred before the timestamp
  --page: int # Pagination controls - return the nth page of results. Defaults to first page if left empty (default: 1)
  --limit: int # Number of events in the result set. Defaults to 100 if left empty (default: 100)
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<item_count: int, next_page: bool, page: int, results: table<created_at: string, event: record, generated_uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_servicename" $source_servicename "scalar") (serialize-qp "source_hostid" $source_hostid "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "level" $level "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"source_servicename": $source_servicename, "source_hostid": $source_hostid, "event_type": $event_type, "resource_type": $resource_type, "resource_id": $resource_id, "level": $level, "since": $since, "before": $before, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Event
#
# DELETE /events/{eventId}
# operationId: delete_event
export def "events delete-by-event-id" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get Event
#
# GET /events/{eventId}
# operationId: get_event
export def "events get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<created_at: string, event: record<category: string, details: record, level: string, message: string, resource: record<id: string, type: string, user_id: string>, source: record<base_url: string, hostid: string, request_id: string, servicename: string>, timestamp: string, type: string>, generated_uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Health check, returns 200 and no body if service is running
#
# GET /health
# operationId: health_check
export def "health check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health" $auth.query)
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

# Bulk mark images for deletion
#
# DELETE /images
# operationId: delete_images_async
export def "images delete-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-digests: list<string>
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<detail: string, digest: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageDigests" $image_digests "csv") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"imageDigests": $image_digests, "force": $force} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# List all visible images
#
# GET /images
# operationId: list_images
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --history: oneof<nothing, bool> # Include image history in the response
  --fulltag: string # Full docker-pull string to filter results by (e.g. docker.io/library/nginx:latest, or myhost.com:5000/testimages:v1.1.1)
  --image-status: string@image-status-completer # Filter by image_status value on the record. Default if omitted is 'active'. (default: active)
  --analysis-status: string@analysis-status-completer # Filter by analysis_status value on the record.
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "history" $history "scalar") (serialize-qp "fulltag" $fulltag "scalar") (serialize-qp "image_status" $image_status "scalar") (serialize-qp "analysis_status" $analysis_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"history": $history, "fulltag": $fulltag, "image_status": $image_status, "analysis_status": $analysis_status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Submit a new image for analysis by the engine
#
# POST /images
# operationId: add_image
# --source shape: {archive?: record, digest?: record, import?: record, tag?: record}
export def "images create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Override any existing entry in the system
  --autosubscribe: oneof<nothing, bool> # Instruct engine to automatically begin watching the added tag for updates from registry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --annotations: record # Annotations to be associated with the added image in key/value form
  --created-at: string # Optional override of the image creation time, only honored when both tag and digest are also supplied e.g. 2018-10-17T18:14:00Z. Deprecated in favor of the 'source' field (format: date-time)
  --digest: string # A digest string for an image, maybe a pull string or just a digest. e.g. nginx@sha256:123 or sha256:abc123. If a pull string, it must have same regisry/repo as the tag field. Deprecated in favor of the 'source' field
  --dockerfile: string # Base64 encoded content of the dockerfile for the image, if available. Deprecated in favor of the 'source' field.
  --image-type: string # Optional. The type of image this is adding, defaults to "docker". This can be ommitted until multiple image types are supported.
  --body-source: record # A set of analysis source types. Only one may be set in any given request. — shape: {archive?: record, digest?: record, import?: record, tag?: record}
  --tag: string # Full pullable tag reference for image. e.g. docker.io/nginx:latest. Deprecated in favor of the 'source' field
]: any -> table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "autosubscribe" $autosubscribe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp $auth.query)
  let req_body = {"annotations": $annotations, "created_at": $created_at, "digest": $digest, "dockerfile": $dockerfile, "image_type": $image_type, "source": $body_source, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"force": $force, "autosubscribe": $autosubscribe} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete image by docker imageId
#
# DELETE /images/by_id/{imageId}
# operationId: delete_image_by_imageId
export def "images-by-id delete" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<detail: string, digest: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"force": $force} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Lookup image by docker imageId
#
# GET /images/by_id/{imageId}
# operationId: get_image_by_imageId
export def "images-by-id get" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Check policy evaluation status for image
#
# GET /images/by_id/{imageId}/check
# operationId: get_image_policy_check_by_imageId
export def "images-by-id-check get-policy" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string
  --tag: string
  --detail: oneof<nothing, bool>
  --history: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let qp = [(serialize-qp "policyId" $policy_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "detail" $detail "scalar") (serialize-qp "history" $history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}/check") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"policyId": $policy_id, "tag": $tag, "detail": $detail, "history": $history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List image content types
#
# GET /images/by_id/{imageId}/content
# operationId: list_image_content_by_imageid
export def "images-by-id-content list" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}/content") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type files
#
# GET /images/by_id/{imageId}/content/files
# operationId: get_image_content_by_type_imageId_files
export def "images-by-id-content-files get-type" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}/content/files") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type java
#
# GET /images/by_id/{imageId}/content/java
# operationId: get_image_content_by_type_imageId_javapackage
export def "images-by-id-content-java get-type-javapackage" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<cpes: list, implementation_version: string, location: string, maven_version: string, origin: string, package: string, specification_version: string, type: string>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}/content/java") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type
#
# GET /images/by_id/{imageId}/content/{ctype}
# operationId: get_image_content_by_type_imageId
export def "images-by-id-content get-type" [
  image_id: string
  ctype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<cpes: list, license: string, licenses: list, location: string, origin: string, package: string, size: string, type: string, version: string>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  if ($ctype | is-empty) { error make --unspanned { msg: "path parameter 'ctype' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id), ctype: (encode-path-segment $ctype)} | format pattern "/images/by_id/{image_id}/content/{ctype}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get vulnerability types
#
# GET /images/by_id/{imageId}/vuln
# operationId: get_image_vulnerability_types_by_imageId
export def "images-by-id-vuln get-vulnerability-types" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/images/by_id/{image_id}/vuln") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get vulnerabilities by type
#
# GET /images/by_id/{imageId}/vuln/{vtype}
# operationId: get_image_vulnerabilities_by_type_imageId
export def "images-by-id-vuln get-vulnerabilities-type" [
  image_id: string
  vtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, vulnerabilities: table<feed: string, feed_group: string, fix: string, nvd_data: list, package: string, package_cpe: string, package_name: string, package_path: string, package_type: string, package_version: string, severity: string, url: string, vendor_data: list, vuln: string, will_not_fix: bool>, vulnerability_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'imageId' must be non-empty" } }
  if ($vtype | is-empty) { error make --unspanned { msg: "path parameter 'vtype' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id), vtype: (encode-path-segment $vtype)} | format pattern "/images/by_id/{image_id}/vuln/{vtype}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete an image analysis
#
# DELETE /images/{imageDigest}
# operationId: delete_image
export def "images delete" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<detail: string, digest: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"force": $force} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get image metadata
#
# GET /images/{imageDigest}
# operationId: get_image
export def "images get" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/file_content_search
# operationId: list_file_content_search_results
export def "images-artifacts-file-content-search list-results" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<matches: list<record>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/artifacts/file_content_search") $auth.query)
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

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/retrieved_files
# operationId: list_retrieved_files
export def "images-artifacts-retrieved-files list" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<b64_content: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/artifacts/retrieved_files") $auth.query)
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

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/secret_search
# operationId: list_secret_search_results
export def "images-artifacts-secret-search list-results" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<matches: list<record>, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/artifacts/secret_search") $auth.query)
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

# Check policy evaluation status for image
#
# GET /images/{imageDigest}/check
# operationId: get_image_policy_check
export def "images-check get-policy" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string
  --tag: string
  --detail: oneof<nothing, bool>
  --history: oneof<nothing, bool>
  --interactive: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let qp = [(serialize-qp "policyId" $policy_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "detail" $detail "scalar") (serialize-qp "history" $history "scalar") (serialize-qp "interactive" $interactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/check") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"policyId": $policy_id, "tag": $tag, "detail": $detail, "history": $history, "interactive": $interactive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List image content types
#
# GET /images/{imageDigest}/content
# operationId: list_image_content
export def "images-content list" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/content") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type files
#
# GET /images/{imageDigest}/content/files
# operationId: get_image_content_by_type_files
export def "images-content-files get-by-type" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/content/files") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type java
#
# GET /images/{imageDigest}/content/java
# operationId: get_image_content_by_type_javapackage
export def "images-content-java get-by-type-javapackage" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<cpes: list, implementation_version: string, location: string, maven_version: string, origin: string, package: string, specification_version: string, type: string>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/content/java") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type malware
#
# GET /images/{imageDigest}/content/malware
# operationId: get_image_content_by_type_malware
export def "images-content-malware get-by-type" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<enabled: bool, findings: list, metadata: record, scanner: string>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/content/malware") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the content of an image by type
#
# GET /images/{imageDigest}/content/{ctype}
# operationId: get_image_content_by_type
export def "images-content get-by-type" [
  image_digest: string
  ctype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<content: table<cpes: list, license: string, licenses: list, location: string, origin: string, package: string, size: string, type: string, version: string>, content_type: string, imageDigest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  if ($ctype | is-empty) { error make --unspanned { msg: "path parameter 'ctype' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest), ctype: (encode-path-segment $ctype)} | format pattern "/images/{image_digest}/content/{ctype}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List image metadata types
#
# GET /images/{imageDigest}/metadata
# operationId: list_image_metadata
export def "images-metadata list" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/metadata") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get the metadata of an image by type
#
# GET /images/{imageDigest}/metadata/{mtype}
# operationId: get_image_metadata_by_type
export def "images-metadata get-by-type" [
  image_digest: string
  mtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, metadata: any, metadata_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  if ($mtype | is-empty) { error make --unspanned { msg: "path parameter 'mtype' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest), mtype: (encode-path-segment $mtype)} | format pattern "/images/{image_digest}/metadata/{mtype}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get image sbom in the native Anchore format
#
# GET /images/{imageDigest}/sboms/native
# operationId: get_image_sbom_native
export def "images-sboms-native get" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/sboms/native") $auth.query)
  let accept_val = "application/gzip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get vulnerability types
#
# GET /images/{imageDigest}/vuln
# operationId: get_image_vulnerability_types
export def "images-vuln get-vulnerability-types" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest)} | format pattern "/images/{image_digest}/vuln") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get vulnerabilities by type
#
# GET /images/{imageDigest}/vuln/{vtype}
# operationId: get_image_vulnerabilities_by_type
export def "images-vuln get-vulnerabilities-by-type" [
  image_digest: string
  vtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-refresh: oneof<nothing, bool>
  --vendor-only: oneof<nothing, bool> # Filter results to include only vulnerabilities that are not marked as invalid by upstream OS vendor data. When set to true, it will filter out all vulnerabilities where `will_not_fix` is False. If false all vulnerabilities are returned regardless of `will_not_fix`
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<imageDigest: string, vulnerabilities: table<feed: string, feed_group: string, fix: string, nvd_data: list, package: string, package_cpe: string, package_name: string, package_path: string, package_type: string, package_version: string, severity: string, url: string, vendor_data: list, vuln: string, will_not_fix: bool>, vulnerability_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_digest | is-empty) { error make --unspanned { msg: "path parameter 'imageDigest' must be non-empty" } }
  if ($vtype | is-empty) { error make --unspanned { msg: "path parameter 'vtype' must be non-empty" } }
  let qp = [(serialize-qp "force_refresh" $force_refresh "scalar") (serialize-qp "vendor_only" $vendor_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({image_digest: (encode-path-segment $image_digest), vtype: (encode-path-segment $vtype)} | format pattern "/images/{image_digest}/vuln/{vtype}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"force_refresh": $force_refresh, "vendor_only": $vendor_only} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Import an anchore image tar.gz archive file. This is a deprecated API replaced by the "/imports/images" route
#
# POST /import/images
# operationId: import_image_archive
export def "import-images archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  archive_file: string # anchore image tar archive. (format: binary)
]: any -> table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/import/images" $auth.query)
  let req_body = {"archive_file": $archive_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["archive_file"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Lists in-progress imports
#
# GET /imports/images
# operationId: list_operations
export def "imports-images list-operations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, expires_at: string, status: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/images" $auth.query)
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

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images
# operationId: create_operation
export def "imports-images create-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, expires_at: string, status: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/images" $auth.query)
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

# Invalidate operation ID so it can be garbage collected
#
# DELETE /imports/images/{operation_id}
# operationId: invalidate_operation
export def "imports-images delete-invalidate" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, expires_at: string, status: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}") $auth.query)
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

# Get detail on a single import
#
# GET /imports/images/{operation_id}
# operationId: get_operation
export def "imports-images get" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, expires_at: string, status: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}") $auth.query)
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

# List uploaded dockerfiles
#
# GET /imports/images/{operation_id}/dockerfile
# operationId: list_import_dockerfiles
export def "imports-images-dockerfile list" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/dockerfile") $auth.query)
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

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images/{operation_id}/dockerfile
# operationId: import_image_dockerfile
export def "imports-images-dockerfile import" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<created_at: string, digest: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/dockerfile") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain; utf-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List uploaded image configs
#
# GET /imports/images/{operation_id}/image_config
# operationId: list_import_image_configs
export def "imports-images-image-config list" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/image_config") $auth.query)
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

# Import a docker or OCI image config to associate with the image
#
# POST /imports/images/{operation_id}/image_config
# operationId: import_image_config
export def "imports-images-image-config import" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<created_at: string, digest: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/image_config") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List uploaded image manifests
#
# GET /imports/images/{operation_id}/manifest
# operationId: list_import_image_manifests
export def "imports-images-manifest list" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/manifest") $auth.query)
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

# Import a docker or OCI distribution manifest to associate with the image
#
# POST /imports/images/{operation_id}/manifest
# operationId: import_image_manifest
export def "imports-images-manifest import" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<created_at: string, digest: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/manifest") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/vnd.docker.distribution.manifest.v1+json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List uploaded package manifests
#
# GET /imports/images/{operation_id}/packages
# operationId: list_import_packages
export def "imports-images-packages list" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/packages") $auth.query)
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

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images/{operation_id}/packages
# operationId: import_image_packages
# --artifactRelationships item shape: {child: string, metadata?: record, parent: string, type: string}
# --artifacts item shape: {cpes: list<string>, foundBy?: string, id?: string, language: string, licenses: list<string>, locations: list, metadata?: record, metadataType: string, name: string, purl?: string, type: string, version: string}
# --descriptor shape: {name: string, version: string}
# --distro shape: {idLike: string, name: string, version: string}
# --schema shape: {url: string, version: string}
# --source shape: {target: any, type: string}
export def "imports-images-packages import" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-relationships: list # item shape: {child: string, metadata?: record, parent: string, type: string}
  artifacts: list # item shape: {cpes: list<string>, foundBy?: string, id?: string, language: string, licenses: list<string>, locations: list, metadata?: record, metadataType: string, name: string, purl?: string, type: string, version: string}
  --descriptor: record # shape: {name: string, version: string}
  distro: record # shape: {idLike: string, name: string, version: string}
  --schema: record # shape: {url: string, version: string}
  --body-source: record # shape: {target: any, type: string}
]: any -> record<created_at: string, digest: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/packages") $auth.query)
  let req_body = {"artifactRelationships": $artifact_relationships, "artifacts": $artifacts, "descriptor": $descriptor, "distro": $distro, "schema": $schema, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List uploaded parent manifests (manifest lists for a tag)
#
# GET /imports/images/{operation_id}/parent_manifest
# operationId: list_import_parent_manifests
export def "imports-images-parent-manifest list" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/parent_manifest") $auth.query)
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

# Import a docker or OCI distribution manifest list to associate with the image
#
# POST /imports/images/{operation_id}/parent_manifest
# operationId: import_image_parent_manifest
export def "imports-images-parent-manifest import" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<created_at: string, digest: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operation_id' must be non-empty" } }
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/imports/images/{operation_id}/parent_manifest") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/vnd.docker.distribution.manifest.list.v2+json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Request a jwt token for subsequent operations, this request is authenticated with normal HTTP auth
#
# POST /oauth/token
# operationId: get_oauth_token
export def "oauth-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The type of client used for the OAuth token (default: anonymous)
  --grant-type: string # OAuth Grant type for token (default: password)
  --password: string # Password for corresponding user
  --username: string # User to assign OAuth token to
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token" $auth.query)
  let req_body = {"client_id": $client_id, "grant_type": $grant_type, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List policies
#
# GET /policies
# operationId: list_policies
export def "policies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # Include policy bundle detail in the form of the full bundle content for each entry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/policies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"detail": $detail} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new policy
#
# POST /policies
# operationId: add_policy
# --blacklisted_images item shape: {id?: string, image: record, name: string, registry: string, repository: string}
# --mappings item shape: {id?: string, image: record, name: string, policy_id?: string, policy_ids?: list<string>, registry: string, repository: string, whitelist_ids?: list<string>}
# --policies item shape: {comment?: string, id: string, name?: string, rules?: list, version: string}
# --whitelisted_images item shape: {id?: string, image: record, name: string, registry: string, repository: string}
# --whitelists item shape: {comment?: string, id: string, items?: list, name?: string, version: string}
export def "policies create-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --blacklisted-images: list # List of mapping rules that define which images should always result in a STOP/FAIL policy result regardless of policy content or presence in whitelisted_images — item shape: {id?: string, image: record, name: string, registry: string, repository: string}
  --comment: string # Description of the bundle, human readable
  id: string # Id of the bundle
  mappings: list # Mapping rules for defining which policy and whitelist(s) to apply to an image based on a match of the image tag or id. Evaluated in order. — item shape: {id?: string, image: record, name: string, policy_id?: string, policy_ids?: list<string>, registry: string, repository: string, whitelist_ids?: list<string>}
  --name: string # Human readable name for the bundle
  policies: list # Policies which define the go/stop/warn status of an image using rule matches on image properties — item shape: {comment?: string, id: string, name?: string, rules?: list, version: string}
  version: string # Version id for this bundle format
  --whitelisted-images: list # List of mapping rules that define which images should always be passed (unless also on the blacklist), regardless of policy result. — item shape: {id?: string, image: record, name: string, registry: string, repository: string}
  --whitelists: list # Whitelists which define which policy matches to disregard explicitly in the final policy decision — item shape: {comment?: string, id: string, items?: list, name?: string, version: string}
]: any -> record<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list<record>, comment: string, id: string, mappings: list<record>, name: string, policies: list<record>, version: string, whitelisted_images: list<record>, whitelists: list<record>>, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/policies" $auth.query)
  let req_body = {"blacklisted_images": $blacklisted_images, "comment": $comment, "id": $id, "mappings": $mappings, "name": $name, "policies": $policies, "version": $version, "whitelisted_images": $whitelisted_images, "whitelists": $whitelists} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete policy
#
# DELETE /policies/{policyId}
# operationId: delete_policy
export def "policies delete-policy" [
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let full_url = (build-url $base ({policy_id: (encode-path-segment $policy_id)} | format pattern "/policies/{policy_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get specific policy
#
# GET /policies/{policyId}
# operationId: get_policy
export def "policies get-policy" [
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # Include policy bundle detail in the form of the full bundle content for each entry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let qp = [(serialize-qp "detail" $detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({policy_id: (encode-path-segment $policy_id)} | format pattern "/policies/{policy_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"detail": $detail} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update policy
#
# PUT /policies/{policyId}
# operationId: update_policy
# --policybundle shape: {blacklisted_images?: list, comment?: string, id: string, mappings: list, name?: string, policies: list, version: string, whitelisted_images?: list, whitelists?: list}
export def "policies update-policy" [
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Mark policy as active
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --active-body: oneof<nothing, bool> # True if the bundle is currently defined to be used automatically (body field)
  --created-at: string # format: date-time
  --last-updated: string # format: date-time
  --body-policy-id: string # The bundle's identifier
  --policy-source: string # Source location of where the policy bundle originated
  --policybundle: record # A bundle containing a set of policies, whitelists, and rules for mapping them to specific images — shape: {blacklisted_images?: list, comment?: string, id: string, mappings: list, name?: string, policies: list, version: string, whitelisted_images?: list, whitelists?: list}
  --user-id: string # UserId of the user that owns the bundle
]: any -> table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($policy_id | is-empty) { error make --unspanned { msg: "path parameter 'policyId' must be non-empty" } }
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({policy_id: (encode-path-segment $policy_id)} | format pattern "/policies/{policy_id}") $qp $auth.query)
  let req_body = {"active": $active_body, "created_at": $created_at, "last_updated": $last_updated, "policyId": $body_policy_id, "policy_source": $policy_source, "policybundle": $policybundle, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"active": $active} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List of images containing given package
#
# GET /query/images/by_package
# operationId: query_images_by_package
export def "query-images-by-package list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of package to search for (e.g. sed)
  --package-type: string # Type of package to filter on (e.g. dpkg)
  --version: string # Version of named package to filter on (e.g. 4.4-1)
  --page: string # The page of results to fetch. Pages start at 1
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<next_page: string, page: string, returned_count: int, images: table<image: record, packages: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "package_type" $package_type "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query/images/by_package" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "package_type": $package_type, "version": $version, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List images vulnerable to the specific vulnerability ID.
#
# GET /query/images/by_vulnerability
# operationId: query_images_by_vulnerability
export def "query-images-by-vulnerability list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vulnerability-id: string # The ID of the vulnerability to search for within all images stored in anchore-engine (e.g. CVE-1999-0001)
  --namespace: string # Filter results to images within the given vulnerability namespace (e.g. debian:8, ubuntu:14.04)
  --affected-package: string # Filter results to images with vulnable packages with the given package name (e.g. libssl)
  --severity: string@severity-completer # Filter results to vulnerable package/vulnerability with the given severity
  --vendor-only: oneof<nothing, bool> # Filter results to include only vulnerabilities that are not marked as invalid by upstream OS vendor data (default: true)
  --page: int # The page of results to fetch. Pages start at 1
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> record<next_page: string, page: string, returned_count: int, images: table<affected_packages: list, image: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vulnerability_id" $vulnerability_id "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "affected_package" $affected_package "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "vendor_only" $vendor_only "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query/images/by_vulnerability" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vulnerability_id": $vulnerability_id, "namespace": $namespace, "affected_package": $affected_package, "severity": $severity, "vendor_only": $vendor_only, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Listing information about given vulnerability
#
# GET /query/vulnerabilities
# operationId: query_vulnerabilities
export def "query-vulnerabilities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # The ID of the vulnerability (e.g. CVE-1999-0001)
  --affected-package: string # Filter results by specified package name (e.g. sed)
  --affected-package-version: string # Filter results by specified package version (e.g. 4.4-1)
  --page: string # The page of results to fetch. Pages start at 1 (default: 1)
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --namespace: list<string> # Namespace(s) to filter vulnerability records by
]: nothing -> record<next_page: string, page: string, returned_count: int, vulnerabilities: table<affected_packages: list, description: string, id: string, link: string, namespace: string, nvd_data: list, references: list, severity: string, vendor_data: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "affected_package" $affected_package "scalar") (serialize-qp "affected_package_version" $affected_package_version "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "namespace" $namespace "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/query/vulnerabilities" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "affected_package": $affected_package, "affected_package_version": $affected_package_version, "page": $page, "limit": $limit, "namespace": $namespace} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List configured registries
#
# GET /registries
# operationId: list_registries
export def "registries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registries" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Add a new registry
#
# POST /registries
# operationId: create_registry
export def "registries create-registry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool> # flag to determine whether or not to validate registry/credential at registry add time
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --registry: string # hostname:port string for accessing the registry, as would be used in a docker pull operation. May include some or all of a repository and wildcards (e.g. docker.io/library/* or gcr.io/myproject/myrepository)
  --registry-name: string # human readable name associated with registry record
  --registry-pass: string # Password portion of credential to use for this registry
  --registry-type: string # Type of registry
  --registry-user: string # Username portion of credential to use for this registry
  --registry-verify: oneof<nothing, bool> # Use TLS/SSL verification for the registry URL
]: any -> table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validate" $validate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registries" $qp $auth.query)
  let req_body = {"registry": $registry, "registry_name": $registry_name, "registry_pass": $registry_pass, "registry_type": $registry_type, "registry_user": $registry_user, "registry_verify": $registry_verify} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"validate": $validate} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a registry configuration
#
# DELETE /registries/{registry}
# operationId: delete_registry
export def "registries delete" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry | is-empty) { error make --unspanned { msg: "path parameter 'registry' must be non-empty" } }
  let full_url = (build-url $base ({registry: (encode-path-segment $registry)} | format pattern "/registries/{registry}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a specific registry configuration
#
# GET /registries/{registry}
# operationId: get_registry
export def "registries get" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry | is-empty) { error make --unspanned { msg: "path parameter 'registry' must be non-empty" } }
  let full_url = (build-url $base ({registry: (encode-path-segment $registry)} | format pattern "/registries/{registry}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update/replace a registry configuration
#
# PUT /registries/{registry}
# operationId: update_registry
export def "registries update" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool> # flag to determine whether or not to validate registry/credential at registry update time
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --body-registry: string # hostname:port string for accessing the registry, as would be used in a docker pull operation. May include some or all of a repository and wildcards (e.g. docker.io/library/* or gcr.io/myproject/myrepository)
  --registry-name: string # human readable name associated with registry record
  --registry-pass: string # Password portion of credential to use for this registry
  --registry-type: string # Type of registry
  --registry-user: string # Username portion of credential to use for this registry
  --registry-verify: oneof<nothing, bool> # Use TLS/SSL verification for the registry URL
]: any -> table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry | is-empty) { error make --unspanned { msg: "path parameter 'registry' must be non-empty" } }
  let qp = [(serialize-qp "validate" $validate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry: (encode-path-segment $registry)} | format pattern "/registries/{registry}") $qp $auth.query)
  let req_body = {"registry": $body_registry, "registry_name": $registry_name, "registry_pass": $registry_pass, "registry_type": $registry_type, "registry_user": $registry_user, "registry_verify": $registry_verify} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"validate": $validate} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add repository to watch
#
# POST /repositories
# operationId: add_repository
export def "repositories create-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository: string # full repository to add e.g. docker.io/library/alpine
  --autosubscribe: oneof<nothing, bool> # flag to enable/disable auto tag_update activation when new images from a repo are added
  --dryrun: oneof<nothing, bool> # flag to return tags in the repository without actually watching the repository, default is false
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repository" $repository "scalar") (serialize-qp "autosubscribe" $autosubscribe "scalar") (serialize-qp "dryrun" $dryrun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"repository": $repository, "autosubscribe": $autosubscribe, "dryrun": $dryrun} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Service status
#
# GET /status
# operationId: get_status
export def "status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status" $auth.query)
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

# List all subscriptions
#
# GET /subscriptions
# operationId: list_subscriptions
export def "subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-key: string # filter only subscriptions matching key
  --subscription-type: string # filter only subscriptions matching type
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_key" $subscription_key "scalar") (serialize-qp "subscription_type" $subscription_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subscription_key": $subscription_key, "subscription_type": $subscription_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a subscription of a specific type
#
# POST /subscriptions
# operationId: add_subscription
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --subscription-key: string
  --subscription-type: string
  --subscription-value: string # nullable
]: any -> table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions" $auth.query)
  let req_body = {"subscription_key": $subscription_key, "subscription_type": $subscription_type, "subscription_value": $subscription_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete subscriptions of a specific type
#
# DELETE /subscriptions/{subscriptionId}
# operationId: delete_subscription
export def "subscriptions delete" [
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
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a specific subscription set
#
# GET /subscriptions/{subscriptionId}
# operationId: get_subscription
export def "subscriptions get" [
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
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update an existing and specific subscription
#
# PUT /subscriptions/{subscriptionId}
# operationId: update_subscription
export def "subscriptions update" [
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
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --active: oneof<nothing, bool> # Toggle the subscription processing on or off
  --subscription-value: string # The new subscription value, e.g. the new tag to be subscribed to (nullable)
]: any -> table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}") $auth.query)
  let req_body = {"active": $active, "subscription_value": $subscription_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all visible image digests and tags
#
# GET /summaries/imagetags
# operationId: list_imagetags
export def "summaries-imagetags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-status: list<string> # Filter images in one or more states such as active, deleting. Defaults to active images only if unspecified (default: [active])
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> table<analysis_status: string, analyzed_at: int, created_at: int, fulltag: string, imageDigest: string, imageId: string, image_status: string, parentDigest: string, tag_detected_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_status" $image_status "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/summaries/imagetags" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-anchore-account": $x_anchore_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"image_status": $image_status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# System status
#
# GET /system
# operationId: get_service_detail
export def "system get-service-detail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<service_states: table<base_url: string, hostid: string, service_detail: record, servicename: string, status: bool, status_message: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system" $auth.query)
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

# Describe anchore engine error codes.
#
# GET /system/error_codes
# operationId: describe_error_codes
export def "system-error-codes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/error_codes" $auth.query)
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

# list feeds operations and information
#
# GET /system/feeds
# operationId: get_system_feeds
export def "system-feeds get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, groups: list<record>, last_full_sync: string, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/feeds" $auth.query)
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

# trigger feeds operations
#
# POST /system/feeds
# operationId: post_system_feeds
export def "system-feeds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flush: oneof<nothing, bool> # instruct system to flush existing data feeds records from anchore-engine
  --sync: oneof<nothing, bool> # instruct system to re-sync data feeds
]: nothing -> table<feed: string, groups: list<record>, status: string, total_time_seconds: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flush" $flush "scalar") (serialize-qp "sync" $sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/feeds" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"flush": $flush, "sync": $sync} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete the groups and data for the feed and disable the feed itself
#
# DELETE /system/feeds/{feed}
# operationId: delete_feed
export def "system-feeds delete-by-feed" [
  feed: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feed | is-empty) { error make --unspanned { msg: "path parameter 'feed' must be non-empty" } }
  let full_url = (build-url $base ({feed: (encode-path-segment $feed)} | format pattern "/system/feeds/{feed}") $auth.query)
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

# Disable the feed so that it does not sync on subsequent sync operations
#
# PUT /system/feeds/{feed}
# operationId: toggle_feed_enabled
export def "system-feeds update-toggle-enabled-by-feed" [
  feed: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
]: nothing -> record<created_at: string, groups: table<created_at: string, last_sync: string, name: string, record_count: int>, last_full_sync: string, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feed | is-empty) { error make --unspanned { msg: "path parameter 'feed' must be non-empty" } }
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feed: (encode-path-segment $feed)} | format pattern "/system/feeds/{feed}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"enabled": $enabled} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Delete the group data and disable the group itself
#
# DELETE /system/feeds/{feed}/{group}
# operationId: delete_feed_group
export def "system-feeds delete-by-feed-group" [
  feed: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feed | is-empty) { error make --unspanned { msg: "path parameter 'feed' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({feed: (encode-path-segment $feed), group: (encode-path-segment $group)} | format pattern "/system/feeds/{feed}/{group}") $auth.query)
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

# Disable a specific group within a feed to not sync
#
# PUT /system/feeds/{feed}/{group}
# operationId: toggle_group_enabled
export def "system-feeds update-toggle-enabled-by-feed-group" [
  feed: string
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
  --enabled: oneof<nothing, bool>
]: nothing -> table<created_at: string, groups: list<record>, last_full_sync: string, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feed | is-empty) { error make --unspanned { msg: "path parameter 'feed' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feed: (encode-path-segment $feed), group: (encode-path-segment $group)} | format pattern "/system/feeds/{feed}/{group}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"enabled": $enabled} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Describe the policy language spec implemented by this service.
#
# GET /system/policy_spec
# operationId: describe_policy
export def "system-policy-spec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, name: string, state: string, superceded_by: string, triggers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/policy_spec" $auth.query)
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

# List system services
#
# GET /system/services
# operationId: list_services
export def "system-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/services" $auth.query)
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

# Get a service configuration and state
#
# GET /system/services/{servicename}
# operationId: get_services_by_name
export def "system-services get-by-name" [
  servicename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($servicename | is-empty) { error make --unspanned { msg: "path parameter 'servicename' must be non-empty" } }
  let full_url = (build-url $base ({servicename: (encode-path-segment $servicename)} | format pattern "/system/services/{servicename}") $auth.query)
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

# Delete the service config
#
# DELETE /system/services/{servicename}/{hostid}
# operationId: delete_service
export def "system-services delete" [
  servicename: string
  hostid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($servicename | is-empty) { error make --unspanned { msg: "path parameter 'servicename' must be non-empty" } }
  if ($hostid | is-empty) { error make --unspanned { msg: "path parameter 'hostid' must be non-empty" } }
  let full_url = (build-url $base ({servicename: (encode-path-segment $servicename), hostid: (encode-path-segment $hostid)} | format pattern "/system/services/{servicename}/{hostid}") $auth.query)
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

# Get service config for a specific host
#
# GET /system/services/{servicename}/{hostid}
# operationId: get_services_by_name_and_host
export def "system-services get-by-name-and-host" [
  servicename: string
  hostid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($servicename | is-empty) { error make --unspanned { msg: "path parameter 'servicename' must be non-empty" } }
  if ($hostid | is-empty) { error make --unspanned { msg: "path parameter 'hostid' must be non-empty" } }
  let full_url = (build-url $base ({servicename: (encode-path-segment $servicename), hostid: (encode-path-segment $hostid)} | format pattern "/system/services/{servicename}/{hostid}") $auth.query)
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

# Adds the capabilities to test a webhook delivery for the given notification type
#
# POST /system/webhooks/{webhook_type}/test
# operationId: test_webhook
export def "system-webhooks-test test" [
  webhook_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-type: string@notification-type-completer # What kind of Notification to send (default: tag_update)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_type | is-empty) { error make --unspanned { msg: "path parameter 'webhook_type' must be non-empty" } }
  let qp = [(serialize-qp "notification_type" $notification_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({webhook_type: (encode-path-segment $webhook_type)} | format pattern "/system/webhooks/{webhook_type}/test") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"notification_type": $notification_type} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List authenticated user info
#
# GET /user
# operationId: get_user
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, last_updated: string, source: string, type: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user" $auth.query)
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

# Get current credential summary
#
# GET /user/credentials
# operationId: get_credentials
export def "user-credentials get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/credentials" $auth.query)
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

# add/replace credential
#
# POST /user/credentials
# operationId: add_credential
export def "user-credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The timestamp of creation of the credential
  type: string@type-completer # The type of credential
  value: string # The credential value (e.g. the password)
]: any -> record<created_at: string, last_updated: string, source: string, type: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/credentials" $auth.query)
  let req_body = {"created_at": $created_at, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the version object for the service, including db schema version info
#
# GET /version
# operationId: version_check
export def "version check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api: record<version: string>, db: record<schema_version: string>, service: record<version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version" $auth.query)
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
