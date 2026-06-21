# Auto-generated client for Contract.fit API v1.0
# Source: https://api.apis.guru/v2/specs/contract-p.fit/1.0/openapi.json
# Auth: --token flag or $env.CONTRACT_FIT_API_TOKEN

const BASE_URL = "http://localhost//cfportal.contract-p.fit/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTRACT_FIT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://localhost//cfportal.contract-p.fit/api"] }
def auth-scheme-completer [] { ["basic" "bearer" "basic-credentials"] }

# Completers for enum parameters
def event-completer [] { ["document_delete" "document_evaluate" "document_predict" "document_split" "document_text"] }
def what-completer [] { ["original" "ready" "reply_to" "submit"] }
def type-completer [] { ["avg-time" "get-finished-me" "get-finished-team" "get-next-uuid" "get-oldest-escalated-todo" "get-oldest-todo" "get-todo-count" "get-todo-escalated-count" "inbox" "next-document" "prev-document"] }
def how-completer [] { ["FULL" "SOURCE_FILES"] }
def reviewer-completer [] { ["Human" "Machine"] }
def what-completer-1 [] { ["ALL" "DONE"] }
def type-completer-1 [] { ["dropbox" "email" "imap" "office365" "service_bus" "sftp" "smtp" "webhook"] }
def delivery-method-completer [] { ["download" "email"] }
def type-completer-2 [] { ["saml"] }
def type-completer-3 [] { ["oauth" "saml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "about-release-notes get" } } | get name | first)
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

# GET /about/release_notes
#
# operationId: get_release_notes
export def "about-release-notes get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/about/release_notes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /about/version
#
# operationId: get_version
export def "about-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/about/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Login and retrieve a JWT Token
#
# POST /auth
# operationId: post_auth
export def "auth create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  password: string # the user password
  username: string # the user username
]: any -> record<authentication_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all API-Key
#
# GET /auth/api-key
# operationId: get_api_keys_resource
export def "auth-api-key list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<active: bool, expire_at: string, roles: list<record>, token: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/api-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new API Key
#
# POST /auth/api-key
# operationId: post_api_keys_resource
# --roles item shape: {document_id?: string, inbox?: string, role: string}
export def "auth-api-key create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --active: oneof<nothing, bool> # Is the API Key active or not
  --expire-at: string # Expiration date (format: date-time)
  roles: list # Roles to grant to this token bearer — item shape: {document_id?: string, inbox?: string, role: string}
  user: string # User to give to the bearer
]: any -> record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/api-key")
  let req_body = {"active": $active, "expire_at": $expire_at, "roles": $roles, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all API-Keys for this inbox
#
# GET /auth/api-key/inbox/{inbox_id}
# operationId: get_api_keys_inbox_resource
export def "auth-api-key-inbox get-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<active: bool, expire_at: string, roles: list<record>, token: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/auth/api-key/inbox/{inbox_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new API Key on inbox level
#
# POST /auth/api-key/inbox/{inbox_id}
# operationId: post_api_keys_inbox_resource
# --roles item shape: {document_id?: string, inbox?: string, role: string}
export def "auth-api-key-inbox create-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --active: oneof<nothing, bool> # Is the API Key active or not
  --expire-at: string # Expiration date (format: date-time)
  roles: list # Roles to grant to this token bearer — item shape: {document_id?: string, inbox?: string, role: string}
  user: string # User to give to the bearer
]: any -> record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/auth/api-key/inbox/{inbox_id}"))
  let req_body = {"active": $active, "expire_at": $expire_at, "roles": $roles, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an API Key
#
# DELETE /auth/api-key/{key}
# operationId: delete_api_key_resource
export def "auth-api-key delete-resource" [
  key: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/auth/api-key/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get details of an API-Key
#
# GET /auth/api-key/{key}
# operationId: get_api_key_resource
export def "auth-api-key get-resource" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/auth/api-key/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an API-Key
#
# PATCH /auth/api-key/{key}
# operationId: patch_api_key_resource
export def "auth-api-key update-resource" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<active: bool, expire_at: string, roles: table<document_id: string, inbox: string, role: string>, token: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/auth/api-key/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new ephemeral token
#
# POST /auth/ephemeral
# operationId: post_ephemeral_token_resource
export def "auth-ephemeral create-token-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<authentication_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/ephemeral")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new JWT Token
#
# POST /auth/get_JWT
# DEPRECATED
# operationId: post_get_jwt_resource
# --roles item shape: {document_id?: string, inbox?: string, role: string}
@deprecated
export def "auth-get-jwt create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --roles: list # the user roles — item shape: {document_id?: string, inbox?: string, role: string}
  username: string # the user username
]: any -> record<authentication_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/get_JWT")
  let req_body = {"roles": $roles, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reset the user password
#
# POST /auth/reset_password
# operationId: post_reset_password
export def "auth-reset-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # the new user's password
  --body-token: string # the token to reset the password
  --user-name: string # the username
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/reset_password")
  let req_body = {"new_password": $new_password, "token": $body_token, "user_name": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new token
#
# POST /auth/token
# operationId: post_token_resource
# --roles item shape: {document_id?: string, inbox?: string, role: string}
export def "auth-token create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --roles: list # the user roles — item shape: {document_id?: string, inbox?: string, role: string}
  username: string # the user username
]: any -> record<authentication_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let req_body = {"roles": $roles, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all Connections
#
# GET /connections
# operationId: get_connections_resource
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<event: string, integration: string, routing: list<record>, scope: string, what: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create connection
#
# POST /connections
# operationId: post_connections_resource
# --routing item shape: {and_conditions?: record, target?: string}
export def "connections create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  event: string@event-completer # e.g. document_predict
  integration: string # e.g. abcdef123456789abcdef123
  --routing: list # item shape: {and_conditions?: record, target?: string}
  --scope: string # e.g. abcdef123456789abcdef123
  what: string@what-completer # e.g. original
]: any -> record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connections")
  let req_body = {"event": $event, "integration": $integration, "routing": $routing, "scope": $scope, "what": $what} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a connection
#
# DELETE /connections/{connection_id}
# operationId: delete_connection_resource
export def "connections delete-resource" [
  connection_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connection_id' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get connection
#
# GET /connections/{connection_id}
# operationId: get_connection_resource
export def "connections get-resource" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connection_id' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update connection
#
# PATCH /connections/{connection_id}
# operationId: patch_connection_resource
# --routing item shape: {and_conditions?: record, target?: string}
export def "connections update-resource" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  event: string@event-completer # e.g. document_predict
  integration: string # e.g. abcdef123456789abcdef123
  --routing: list # item shape: {and_conditions?: record, target?: string}
  --scope: string # e.g. abcdef123456789abcdef123
  what: string@what-completer # e.g. original
]: any -> record<event: string, integration: string, routing: table<and_conditions: record, target: string>, scope: string, what: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connection_id' must be non-empty" } }
  let full_url = (build-url $base ({connection_id: (encode-path-segment $connection_id)} | format pattern "/connections/{connection_id}"))
  let req_body = {"event": $event, "integration": $integration, "routing": $routing, "scope": $scope, "what": $what} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all data retention settings
#
# GET /data_retention_settings
# operationId: get_data_retention_resource
export def "data-retention-settings get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<scope: record<id: string, level: string>, settings: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data_retention_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete scoped sampling settings
#
# DELETE /data_retention_settings/{level}/{id}
# operationId: delete_data_retention_resource
export def "data-retention-settings delete-resource" [
  level: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($level | is-empty) { error make --unspanned { msg: "path parameter 'level' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({level: (encode-path-segment $level), id: (encode-path-segment $id)} | format pattern "/data_retention_settings/{level}/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get scoped data retention settings
#
# GET /data_retention_settings/{level}/{id}
export def "data-retention-settings get" [
  level: string
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
  --x-fields: string # An optional fields mask
]: nothing -> record<scope: record<id: string, level: string>, settings: table<age: int, how: string, what: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($level | is-empty) { error make --unspanned { msg: "path parameter 'level' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({level: (encode-path-segment $level), id: (encode-path-segment $id)} | format pattern "/data_retention_settings/{level}/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update scoped data retention settings
#
# PATCH /data_retention_settings/{level}/{id}
# operationId: patch_data_retention_resource
# --settings item shape: {age?: int, how?: "FULL"|"SOURCE_FILES", what?: "ALL"|"DONE"}
export def "data-retention-settings update-resource" [
  level: string
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
  --x-fields: string # An optional fields mask
  --settings: list # item shape: {age?: int, how?: "FULL"|"SOURCE_FILES", what?: "ALL"|"DONE"}
]: any -> record<scope: record<id: string, level: string>, settings: table<age: int, how: string, what: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($level | is-empty) { error make --unspanned { msg: "path parameter 'level' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({level: (encode-path-segment $level), id: (encode-path-segment $id)} | format pattern "/data_retention_settings/{level}/{id}"))
  let req_body = {"settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Upload a new document
#
# POST /documents/
# operationId: post_simple_documents_resource
export def "documents create-simple-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --experimental: oneof<nothing, bool> # Use the experimental processing workflow
  file: string # File to process (format: binary)
  --inbox-id: string # Inbox to use. Default to the **invoice** inbox
  --key-value-flag: oneof<nothing, bool> # If true the result will only contains mapping of prediction = value (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/")
  let req_body = {"experimental": $experimental, "file": $file, "inbox_id": $inbox_id, "key_value_flag": $key_value_flag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Generate custom output for documents
#
# POST /documents/custom_output
# operationId: post_document_custom_output_resource
# --excel shape: {add_automation_blockers?: bool, add_confidence?: bool, add_text?: bool, enable_key_value: bool, multiple_value_separator?: string}
# --filter shape: {end_date?: string, list?: list<string>, start_date?: string, type: "project"|"inbox"|"document"}
export def "documents-custom-output create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom: record
  --excel: record # shape: {add_automation_blockers?: bool, add_confidence?: bool, add_text?: bool, enable_key_value: bool, multiple_value_separator?: string}
  --filter: record # shape: {end_date?: string, list?: list<string>, start_date?: string, type: "project"|"inbox"|"document"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/custom_output")
  let req_body = {"custom": $custom, "excel": $excel, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /documents/enrich
#
# operationId: post_enrichment_resource
export def "documents-enrich create-enrichment-resource" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/enrich")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /documents/file_query/{data_type}
#
# operationId: post_document_data_resource
export def "documents-file-query create-resource" [
  data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-ids: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($data_type | is-empty) { error make --unspanned { msg: "path parameter 'data_type' must be non-empty" } }
  let full_url = (build-url $base ({data_type: (encode-path-segment $data_type)} | format pattern "/documents/file_query/{data_type}"))
  let req_body = {"document_ids": $document_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /documents/query/{query_type}
#
# operationId: post_document_query
# --filter shape: {_id?: record, inbox?: record, timing_fields?: record, timings?: record}
export def "documents-query create" [
  query_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # shape: {_id?: record, inbox?: record, timing_fields?: record, timings?: record}
  --type: string@type-completer # e.g. inbox
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($query_type | is-empty) { error make --unspanned { msg: "path parameter 'query_type' must be non-empty" } }
  let full_url = (build-url $base ({query_type: (encode-path-segment $query_type)} | format pattern "/documents/query/{query_type}"))
  let req_body = {"filter": $filter, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the document
#
# DELETE /documents/{document_id}
# operationId: delete_document_delete_resource
export def "documents delete-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --how: string@how-completer # default: predicted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let qp = [(serialize-qp "how" $how "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"how": $how} | compact), body: null}
}

# Get the document
#
# GET /documents/{document_id}
# operationId: get_document_delete_resource
export def "documents get-delete-resource" [
  document_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /documents/{document_id}/compare_versions
#
# operationId: post_document_compare_versions_resource
export def "documents-compare-versions create-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cmp_version_1: string
  cmp_version_2: string
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/compare_versions"))
  let req_body = {"cmp_version_1": $cmp_version_1, "cmp_version_2": $cmp_version_2, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get custom output formatted document
#
# GET /documents/{document_id}/custom_output
# operationId: get_document_transform_resource
export def "documents-custom-output get-transform-resource" [
  document_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/custom_output"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit a feedback
#
# POST /documents/{document_id}/feedback
# operationId: post_document_submit_eval_resource
# --annotations shape: {string?: list}
# --lines shape: {string?: list}
# --sections item shape: {confidence?: int, document_type?: string, format?: string, page: int}
export def "documents-feedback create-submit-eval-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # shape: {string?: list}
  --cmp-version: string
  --evaluate: oneof<nothing, bool> # default: true
  --lines: record # shape: {string?: list}
  --name: string
  --sections: list # item shape: {confidence?: int, document_type?: string, format?: string, page: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/feedback"))
  let req_body = {"annotations": $annotations, "cmp_version": $cmp_version, "evaluate": $evaluate, "lines": $lines, "name": $name, "sections": $sections} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get latest version
#
# GET /documents/{document_id}/last_version
# operationId: get_document_last_version_resource
export def "documents-last-version get-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return a specific named version, default is latest
  --qp-source: string # human or machine (default either)
  --is-evaluated: oneof<nothing, bool> # Do you want to receive unevaluated version (for display, default) or evaluated (for stats) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "is_evaluated" $is_evaluated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/last_version") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "source": $qp_source, "is_evaluated": $is_evaluated} | compact), body: null}
}

# Get document original file
#
# GET /documents/{document_id}/original_file
# operationId: get_document_original_file_resource
export def "documents-original-file get-resource" [
  document_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/original_file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /documents/{document_id}/page/{page_range}
#
# operationId: get_document_page_image_resource
export def "documents-page get-image-resource" [
  document_id: string
  page_range: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  if ($page_range | is-empty) { error make --unspanned { msg: "path parameter 'page_range' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), page_range: (encode-path-segment $page_range)} | format pattern "/documents/{document_id}/page/{page_range}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /documents/{document_id}/page_thumbnail/{page_range}
#
# operationId: get_document_page_image_thumbnail_resource
export def "documents-page-thumbnail get-image-resource" [
  document_id: string
  page_range: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  if ($page_range | is-empty) { error make --unspanned { msg: "path parameter 'page_range' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), page_range: (encode-path-segment $page_range)} | format pattern "/documents/{document_id}/page_thumbnail/{page_range}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Process a table-level annotation
#
# POST /documents/{document_id}/process_table_annotation
# operationId: post_document_process_table_annotation
# --columns item shape: {field_name?: string, x_bounds?: list<int>}
export def "documents-process-table-annotation create" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottom-right: list<int>
  --columns: list # item shape: {field_name?: string, x_bounds?: list<int>}
  --first-row-y-bounds: list<int>
  --header-bottom-y: int
  --name: string
  --top-left: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/process_table_annotation"))
  let req_body = {"bottom_right": $bottom_right, "columns": $columns, "first_row_y_bounds": $first_row_y_bounds, "header_bottom_y": $header_bottom_y, "name": $name, "top_left": $top_left} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Schedule document reprocessing
#
# POST /documents/{document_id}/reprocess
# operationId: post_reprocess_document_resource
export def "documents-reprocess create-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # default: reprocessed
  --reviewer: string@reviewer-completer # If human repcrocessing is triggered, the last version will become the passed version. No processing is done. (default: Machine)
  --x-fields: string # An optional fields mask
]: nothing -> record<escalate: record<by: string, since: string, value: bool>, feedback: record, files: table<embedded_attachment: bool, filehash: string, filename: string, leaf: bool, page: int, page_count: int>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: table<by: string, since: string, value: bool>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "reviewer" $reviewer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/reprocess") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "reviewer": $reviewer} | compact), body: null}
}

# GET /documents/{document_id}/reverse/{page_range}
#
# operationId: get_document_reverse_resource
export def "documents-reverse get-resource" [
  document_id: string
  page_range: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  if ($page_range | is-empty) { error make --unspanned { msg: "path parameter 'page_range' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), page_range: (encode-path-segment $page_range)} | format pattern "/documents/{document_id}/reverse/{page_range}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update document status
#
# POST /documents/{document_id}/status_data
# operationId: post_document_status_data_resource
# --escalate shape: {by?: string, since?: string, value?: bool}
# --lock shape: {by?: string, since?: string, value?: bool}
# --opened_by shape: {by?: string, since?: string, value?: bool}
# --reject shape: {by?: string, since?: string, value?: bool}
# --status_data shape: {archived?: bool, data?: bool, escalate?: bool, feedback?: bool, lock?: bool, ready_accepted?: bool, ready_attempts?: int, reject?: bool, reject_accepted?: bool, reject_attempts?: int, sampling?: bool, submit_accepted?: bool, submit_attempts?: int, success?: bool}
# --submitted shape: {by?: string, since?: string, value?: bool}
# --timings shape: {done_time?: string, feedback_time?: string, processing_period?: float, receive_time?: string, start_time?: string, submit_time?: string}
export def "documents-status-data create-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --escalate: record # shape: {by?: string, since?: string, value?: bool}
  --last-version: string
  --lock: record # shape: {by?: string, since?: string, value?: bool}
  --opened-by: record # shape: {by?: string, since?: string, value?: bool}
  --reject: record # shape: {by?: string, since?: string, value?: bool}
  --status-data: record # shape: {archived?: bool, data?: bool, escalate?: bool, feedback?: bool, lock?: bool, ready_accepted?: bool, ready_attempts?: int, reject?: bool, reject_accepted?: bool, reject_attempts?: int, sampling?: bool, submit_accepted?: bool, submit_attempts?: int, success?: bool}
  --submitted: record # shape: {by?: string, since?: string, value?: bool}
  --timings: record # shape: {done_time?: string, feedback_time?: string, processing_period?: float, receive_time?: string, start_time?: string, submit_time?: string}
]: any -> record<escalate: record<by: string, since: string, value: bool>, feedback: record, files: table<embedded_attachment: bool, filehash: string, filename: string, leaf: bool, page: int, page_count: int>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: table<by: string, since: string, value: bool>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/status_data"))
  let req_body = {"escalate": $escalate, "last_version": $last_version, "lock": $lock, "opened_by": $opened_by, "reject": $reject, "status_data": $status_data, "submitted": $submitted, "timings": $timings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the document text
#
# GET /documents/{document_id}/text
# operationId: get_document_text_resource
export def "documents-text get-resource" [
  document_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/text"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the document Workflow
#
# GET /documents/{document_id}/workflow
# operationId: get_document_workflow_resource
export def "documents-workflow get-resource" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<graph: record, links: record, nodes: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/workflow"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload a new doc to the inbox
#
# POST /documents/{inbox_id}
# operationId: post_documents_resource
export def "documents create-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --experimental: oneof<nothing, bool> # Use the experimental processing workflow
  file: string # File to process (format: binary)
  --key-value-flag: oneof<nothing, bool> # If true the result will only contains mapping of prediction = value (default: false)
  --sync: oneof<nothing, bool> # Flag enable sync or async processing (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/documents/{inbox_id}"))
  let req_body = {"experimental": $experimental, "file": $file, "key_value_flag": $key_value_flag, "sync": $sync} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Copy documents to another inbox
#
# PATCH /documents/{inbox_id}/copy_inbox
# operationId: patch_document_copy_resource
export def "documents-copy-inbox update-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-ids: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/documents/{inbox_id}/copy_inbox"))
  let req_body = {"document_ids": $document_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Move documents to another inbox
#
# PATCH /documents/{inbox_id}/move_inbox
# operationId: patch_document_move_resource
export def "documents-move-inbox update-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-ids: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/documents/{inbox_id}/move_inbox"))
  let req_body = {"document_ids": $document_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get lists of format
#
# GET /formats
# operationId: get_formats_resource
export def "formats list" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/formats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create format
#
# POST /formats
# operationId: post_formats_resource
# --document_types item shape: {display_name?: string, field_name: string}
# --labels item shape: {category?: "annotation"|"tag"|"separator"|"computed", count_in_evaluation?: bool, description?: string, display_name?: string, field_name: string, formula?: string, initialized?: bool, is_library?: bool, mandatory?: bool, mandatory_if?: record, multiple?: bool, options?: list, scope?: "document"|"page"|"section", type?: "string"|"date"|"integer"|"float"|"currency"|"alphanumeric"|"national_identification_number_be"|"boolean"|"datetime"|"address", visible?: bool, visible_if?: record}
# --separators item shape: {name: string, page: int}
# --table_types item shape: {collapsed?: bool, columns?: list, contains_line_items?: bool, initialized?: bool, label?: string, scope?: "document"|"page"|"section"}
export def "formats create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string
  --document-types: list # item shape: {display_name?: string, field_name: string}
  labels: list # item shape: {category?: "annotation"|"tag"|"separator"|"computed", count_in_evaluation?: bool, description?: string, display_name?: string, field_name: string, formula?: string, initialized?: bool, is_library?: bool, mandatory?: bool, mandatory_if?: record, multiple?: bool, options?: list, scope?: "document"|"page"|"section", type?: "string"|"date"|"integer"|"float"|"currency"|"alphanumeric"|"national_identification_number_be"|"boolean"|"datetime"|"address", visible?: bool, visible_if?: record}
  name: string
  --separators: list # default: [] — item shape: {name: string, page: int}
  --table-types: list # item shape: {collapsed?: bool, columns?: list, contains_line_items?: bool, initialized?: bool, label?: string, scope?: "document"|"page"|"section"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/formats")
  let req_body = {"display_name": $display_name, "document_types": $document_types, "labels": $labels, "name": $name, "separators": $separators, "table_types": $table_types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get supported document_types
#
# GET /formats/document_types
# operationId: get_formats_doc_types_resource
export def "formats-document-types get-doc-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<document_types: table<display_name: string, field_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/formats/document_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete the format
#
# DELETE /formats/{format_id}
# operationId: delete_format_resource
export def "formats delete-resource" [
  format_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($format_id | is-empty) { error make --unspanned { msg: "path parameter 'format_id' must be non-empty" } }
  let full_url = (build-url $base ({format_id: (encode-path-segment $format_id)} | format pattern "/formats/{format_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get format attributes
#
# GET /formats/{format_id}
# operationId: get_format_resource
export def "formats get-resource" [
  format_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($format_id | is-empty) { error make --unspanned { msg: "path parameter 'format_id' must be non-empty" } }
  let full_url = (build-url $base ({format_id: (encode-path-segment $format_id)} | format pattern "/formats/{format_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the format
#
# PATCH /formats/{format_id}
# operationId: patch_format_resource
# --document_types item shape: {display_name?: string, field_name: string}
# --labels item shape: {category?: "annotation"|"tag"|"separator"|"computed", count_in_evaluation?: bool, description?: string, display_name?: string, field_name: string, formula?: string, initialized?: bool, is_library?: bool, mandatory?: bool, mandatory_if?: record, multiple?: bool, options?: list, scope?: "document"|"page"|"section", type?: "string"|"date"|"integer"|"float"|"currency"|"alphanumeric"|"national_identification_number_be"|"boolean"|"datetime"|"address", visible?: bool, visible_if?: record}
# --separators item shape: {name: string, page: int}
# --table_types item shape: {collapsed?: bool, columns?: list, contains_line_items?: bool, initialized?: bool, label?: string, scope?: "document"|"page"|"section"}
export def "formats update-resource" [
  format_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --display-name: string
  --document-types: list # item shape: {display_name?: string, field_name: string}
  --labels: list # item shape: {category?: "annotation"|"tag"|"separator"|"computed", count_in_evaluation?: bool, description?: string, display_name?: string, field_name: string, formula?: string, initialized?: bool, is_library?: bool, mandatory?: bool, mandatory_if?: record, multiple?: bool, options?: list, scope?: "document"|"page"|"section", type?: "string"|"date"|"integer"|"float"|"currency"|"alphanumeric"|"national_identification_number_be"|"boolean"|"datetime"|"address", visible?: bool, visible_if?: record}
  --name: string
  --separators: list # default: [] — item shape: {name: string, page: int}
  --table-types: list # item shape: {collapsed?: bool, columns?: list, contains_line_items?: bool, initialized?: bool, label?: string, scope?: "document"|"page"|"section"}
]: any -> record<document_types: table<display_name: string, field_name: string>, id: string, labels: table<category: string, count_in_evaluation: bool, description: string, display_name: string, field_name: string, formula: string, initialized: bool, is_library: bool, mandatory: bool, mandatory_if: record, multiple: bool, options: list, scope: string, type: string, visible: bool, visible_if: record>, name: string, separators: table<name: string, page: int>, table_types: table<collapsed: bool, columns: list, contains_line_items: bool, initialized: bool, label: string, scope: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($format_id | is-empty) { error make --unspanned { msg: "path parameter 'format_id' must be non-empty" } }
  let full_url = (build-url $base ({format_id: (encode-path-segment $format_id)} | format pattern "/formats/{format_id}"))
  let req_body = {"display_name": $display_name, "document_types": $document_types, "labels": $labels, "name": $name, "separators": $separators, "table_types": $table_types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get tags values
#
# GET /formats/{scope}/tag_fields
# operationId: get_format_tag_fields_resource
export def "formats-tag-fields get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<tag_fields: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/formats/{scope}/tag_fields"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of inboxes
#
# GET /inboxes
# operationId: get_inboxes_resource
export def "inboxes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<name: string, project: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inboxes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an inbox
#
# POST /inboxes
# operationId: post_inboxes_resource
export def "inboxes create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  name: string
  project: string # e.g. abcdef123456789abcdef123
]: any -> record<name: string, project: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inboxes")
  let req_body = {"name": $name, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an inbox
#
# DELETE /inboxes/{inbox_id}
# operationId: delete_inbox_resource
export def "inboxes delete-resource" [
  inbox_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Inbox attributes
#
# GET /inboxes/{inbox_id}
# operationId: get_inbox_resource
export def "inboxes get-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<name: string, project: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update inbox
#
# PATCH /inboxes/{inbox_id}
# operationId: patch_inbox_resource
export def "inboxes update-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --name: string
  --project: string # e.g. abcdef123456789abcdef123
]: any -> record<name: string, project: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}"))
  let req_body = {"name": $name, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /inboxes/{inbox_id}/document_versions
#
# operationId: get_inbox_document_versions_resource
export def "inboxes-document-versions get-resource" [
  inbox_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}/document_versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete documents
#
# DELETE /inboxes/{inbox_id}/documents
# operationId: delete_inbox_document_resource
export def "inboxes-documents delete-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --how: string@how-completer # default: FULL
  --what: string@what-completer-1 # default: ALL
  --start-date: string # format: date-time
  --end-date: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "how" $how "scalar") (serialize-qp "what" $what "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"how": $how, "what": $what, "start_date": $start_date, "end_date": $end_date} | compact), body: null}
}

# Get documents in the inbox
#
# GET /inboxes/{inbox_id}/documents
# operationId: get_inbox_document_resource
export def "inboxes-documents get-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<escalate: record<by: string, since: string, value: bool>, feedback: record, files: list<record>, flag_for_review: bool, id: string, inbox: string, last_version: string, lock: record<by: string, since: string, value: bool>, meta_information: record, opened_by: list<record>, original_filename: string, page_count: int, prediction: record, reject: record<by: string, since: string, value: bool>, status_data: record<archived: bool, data: bool, escalate: bool, feedback: bool, lock: bool, ready_accepted: bool, ready_attempts: int, reject: bool, reject_accepted: bool, reject_attempts: int, sampling: bool, submit_accepted: bool, submit_attempts: int, success: bool>, submitted: record<by: string, since: string, value: bool>, timings: record<done_time: string, feedback_time: string, processing_period: float, receive_time: string, start_time: string, submit_time: string>, usage_data: record, versions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}/documents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get paginated list of documents in the inbox
#
# GET /inboxes/{inbox_id}/paginated
# operationId: get_inbox_paginated_resource
export def "inboxes-paginated get-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number to fetch (default: 1)
  --per-page: int # Results per page (default: 20)
  --start-receive-date: string # format: date-time
  --end-receive-date: string # format: date-time
  --order-by: string # comma seperated list of fields to order by
  --x-fields: string # An optional fields mask
]: nothing -> table<page: int, per_page: int, results: list<record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "start_receive_date" $start_receive_date "scalar") (serialize-qp "end_receive_date" $end_receive_date "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}/paginated") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "start_receive_date": $start_receive_date, "end_receive_date": $end_receive_date, "order_by": $order_by} | compact), body: null}
}

# Schedule inbox reprocessing
#
# POST /inboxes/{inbox_id}/reprocess
# operationId: post_inbox_reprocess_resource
export def "inboxes-reprocess create-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # default: predicted
  --reviewer: string@reviewer-completer # If human repcrocessing is triggered, the last version will become the passed version. No processing is done. (default: Machine)
  --hints: string # Additional hints as a dictionary. Example: {"VAT_number":{"blacklist":"XXXX.XXX.XXX", "whitelist": ["YYYY.YYY.YYY", "ZZZZ.ZZZ.ZZZ"]}}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "reviewer" $reviewer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/inboxes/{inbox_id}/reprocess") $qp)
  let req_body = {"hints": $hints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"name": $name, "reviewer": $reviewer} | compact), body: $req_body}
}

# Get all integrations
#
# GET /integrations/
# operationId: get_integration_resources
export def "integrations get-resources" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create integration
#
# POST /integrations/
# operationId: post_integration_resources
export def "integrations create-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # e.g. webhook
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/")
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an integration
#
# DELETE /integrations/{integration_id}
# operationId: delete_integration_resource
export def "integrations delete-resource" [
  integration_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_id' must be non-empty" } }
  let full_url = (build-url $base ({integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get integration attributes
#
# GET /integrations/{integration_id}
# operationId: get_integration_resource
export def "integrations get-resource" [
  integration_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_id' must be non-empty" } }
  let full_url = (build-url $base ({integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update integration
#
# PATCH /integrations/{integration_id}
# operationId: patch_integration_resource
export def "integrations update-resource" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # e.g. webhook
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_id' must be non-empty" } }
  let full_url = (build-url $base ({integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_id}"))
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /integrations/{integration_id}/activate
#
# operationId: get_email_integration_activation_resource
export def "integrations-activate get-email-activation-resource" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_id' must be non-empty" } }
  let qp = [(serialize-qp "secret" $secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_id}/activate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"secret": $secret} | compact), body: null}
}

# Get all predictor settings
#
# GET /predictor_settings
# operationId: get_predictor_settings_resource
export def "predictor-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record>, whitelist: record, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predictor_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete scoped predictor settings
#
# DELETE /predictor_settings/{scope}
# operationId: delete_predictor_setting_resource
export def "predictor-settings delete-resource" [
  scope: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/predictor_settings/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get scoped predictor settings
#
# GET /predictor_settings/{scope}
# operationId: get_predictor_setting_resource
export def "predictor-settings get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record<_: record>>, whitelist: record, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/predictor_settings/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update scoped predictor settings
#
# PATCH /predictor_settings/{scope}
# operationId: patch_predictor_setting_resource
# --key_value_pairs shape: {classification_cutoff?: int, rule_config?: record, splitting_cutoff?: int, uer_pre_config?: record}
# --table_extraction_settings shape: {field_settings?: record}
export def "predictor-settings update-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --blacklist: record
  --expected-values: record
  --fallback: record
  --key-value-pairs: record # shape: {classification_cutoff?: int, rule_config?: record, splitting_cutoff?: int, uer_pre_config?: record}
  --table-extraction-settings: record # shape: {field_settings?: record}
  --whitelist: record
]: any -> record<blacklist: record, expected_values: record, fallback: record, key_value_pairs: record<classification_cutoff: int, rule_config: record, splitting_cutoff: int, uer_pre_config: record>, table_extraction_settings: record<field_settings: record<_: record>>, whitelist: record, scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/predictor_settings/{scope}"))
  let req_body = {"blacklist": $blacklist, "expected_values": $expected_values, "fallback": $fallback, "key_value_pairs": $key_value_pairs, "table_extraction_settings": $table_extraction_settings, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the list of projects
#
# GET /projects
# operationId: get_projects_resource
export def "projects list" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a project
#
# POST /projects
# operationId: post_projects_resource
export def "projects create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-document-type: string # This format is chosen as fallback
  --default-format: string # This format is chosen as fallback
  formats: list<string>
  name: string
  --split-into-sections: oneof<nothing, bool> # default: true
  --sub-page-splitting: oneof<nothing, bool> # default: false
  --timeout: int # e.g. 10
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let req_body = {"default_document_type": $default_document_type, "default_format": $default_format, "formats": $formats, "name": $name, "split_into_sections": $split_into_sections, "sub_page_splitting": $sub_page_splitting, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete project
#
# DELETE /projects/{project_id}
# operationId: delete_project_resource
export def "projects delete-resource" [
  project_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get project attributes
#
# GET /projects/{project_id}
# operationId: get_project_resource
export def "projects get-resource" [
  project_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update project
#
# PATCH /projects/{project_id}
# operationId: patch_project_resource
export def "projects update-resource" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-document-type: string # This format is chosen as fallback
  --default-format: string # This format is chosen as fallback
  --formats: list<string>
  --name: string
  --split-into-sections: oneof<nothing, bool>
  --sub-page-splitting: oneof<nothing, bool>
  --timeout: int # e.g. 10
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let req_body = {"default_document_type": $default_document_type, "default_format": $default_format, "formats": $formats, "name": $name, "split_into_sections": $split_into_sections, "sub_page_splitting": $sub_page_splitting, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all reports
#
# GET /reports
# operationId: get_reports_resource
export def "reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list, fields: record, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create report
#
# POST /reports
# operationId: post_reports_resource
# --annotations shape: {add_text?: bool, include?: bool}
# --automation_blockers shape: {include?: bool}
# --automation_score shape: {include?: bool}
# --automation_what_if shape: {include?: bool}
# --cover shape: {include?: bool}
# --elapse_time shape: {include?: bool}
# --evaluations shape: {additional_column?: string, include?: bool}
# --field_automation shape: {include?: bool}
# --lines shape: {include?: bool}
# --metadata shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
# --page_classification shape: {include?: bool}
# --sections shape: {include?: bool}
# --text shape: {include?: bool}
export def "reports create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --annotations: record # shape: {add_text?: bool, include?: bool}
  --automation-blockers: record # shape: {include?: bool}
  --automation-score: record # shape: {include?: bool}
  --automation-what-if: record # shape: {include?: bool}
  --cover: record # shape: {include?: bool}
  --documents: list<string>
  --elapse-time: record # shape: {include?: bool}
  --evaluations: record # shape: {additional_column?: string, include?: bool}
  --field-automation: record # shape: {include?: bool}
  --inboxes: list<string>
  --lines: record # shape: {include?: bool}
  --metadata: record # shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
  --name: string
  --page-classification: record # shape: {include?: bool}
  --projects: list<string>
  --sections: record # shape: {include?: bool}
  --separator: string # default: |
  --sources: list<string> # default: [human, machine]
  --text: record # shape: {include?: bool}
  --version-name: string
]: any -> record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports")
  let req_body = {"annotations": $annotations, "automation_blockers": $automation_blockers, "automation_score": $automation_score, "automation_what_if": $automation_what_if, "cover": $cover, "documents": $documents, "elapse_time": $elapse_time, "evaluations": $evaluations, "field_automation": $field_automation, "inboxes": $inboxes, "lines": $lines, "metadata": $metadata, "name": $name, "page_classification": $page_classification, "projects": $projects, "sections": $sections, "separator": $separator, "sources": $sources, "text": $text, "version_name": $version_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate report based on input
#
# POST /reports/generate
# operationId: post_generate_report_resource
# --annotations shape: {add_text?: bool, include?: bool}
# --automation_blockers shape: {include?: bool}
# --automation_score shape: {include?: bool}
# --automation_what_if shape: {include?: bool}
# --cover shape: {include?: bool}
# --elapse_time shape: {include?: bool}
# --evaluations shape: {additional_column?: string, include?: bool}
# --field_automation shape: {include?: bool}
# --lines shape: {include?: bool}
# --metadata shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
# --page_classification shape: {include?: bool}
# --sections shape: {include?: bool}
# --text shape: {include?: bool}
export def "reports-generate create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotations: record # shape: {add_text?: bool, include?: bool}
  --automation-blockers: record # shape: {include?: bool}
  --automation-score: record # shape: {include?: bool}
  --automation-what-if: record # shape: {include?: bool}
  --cover: record # shape: {include?: bool}
  --documents: list<string>
  --elapse-time: record # shape: {include?: bool}
  --evaluations: record # shape: {additional_column?: string, include?: bool}
  --field-automation: record # shape: {include?: bool}
  --inboxes: list<string>
  --lines: record # shape: {include?: bool}
  --metadata: record # shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
  --name: string
  --page-classification: record # shape: {include?: bool}
  --projects: list<string>
  --sections: record # shape: {include?: bool}
  --separator: string # default: |
  --sources: list<string> # default: [human, machine]
  --text: record # shape: {include?: bool}
  --version-name: string
  --delivery-method: string@delivery-method-completer # default: download, e.g. email
  --email: string
  --end-date: string # format: date-time
  --start-date: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/generate")
  let req_body = {"annotations": $annotations, "automation_blockers": $automation_blockers, "automation_score": $automation_score, "automation_what_if": $automation_what_if, "cover": $cover, "documents": $documents, "elapse_time": $elapse_time, "evaluations": $evaluations, "field_automation": $field_automation, "inboxes": $inboxes, "lines": $lines, "metadata": $metadata, "name": $name, "page_classification": $page_classification, "projects": $projects, "sections": $sections, "separator": $separator, "sources": $sources, "text": $text, "version_name": $version_name, "delivery_method": $delivery_method, "email": $email, "end_date": $end_date, "start_date": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a report
#
# DELETE /reports/{report_id}
# operationId: delete_report_resource
export def "reports delete-resource" [
  report_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get report
#
# GET /reports/{report_id}
# operationId: get_report_resource
export def "reports get-resource" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update report
#
# PATCH /reports/{report_id}
# operationId: patch_report_resource
# --annotations shape: {add_text?: bool, include?: bool}
# --automation_blockers shape: {include?: bool}
# --automation_score shape: {include?: bool}
# --automation_what_if shape: {include?: bool}
# --cover shape: {include?: bool}
# --elapse_time shape: {include?: bool}
# --evaluations shape: {additional_column?: string, include?: bool}
# --field_automation shape: {include?: bool}
# --lines shape: {include?: bool}
# --metadata shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
# --page_classification shape: {include?: bool}
# --sections shape: {include?: bool}
# --text shape: {include?: bool}
export def "reports update-resource" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --annotations: record # shape: {add_text?: bool, include?: bool}
  --automation-blockers: record # shape: {include?: bool}
  --automation-score: record # shape: {include?: bool}
  --automation-what-if: record # shape: {include?: bool}
  --cover: record # shape: {include?: bool}
  --documents: list<string>
  --elapse-time: record # shape: {include?: bool}
  --evaluations: record # shape: {additional_column?: string, include?: bool}
  --field-automation: record # shape: {include?: bool}
  --inboxes: list<string>
  --lines: record # shape: {include?: bool}
  --metadata: record # shape: {columns?: list<string>, fields?: record, include?: bool, rename?: record}
  --name: string
  --page-classification: record # shape: {include?: bool}
  --projects: list<string>
  --sections: record # shape: {include?: bool}
  --separator: string # default: |
  --sources: list<string> # default: [human, machine]
  --text: record # shape: {include?: bool}
  --version-name: string
]: any -> record<annotations: record<add_text: bool, include: bool>, automation_blockers: record<include: bool>, automation_score: record<include: bool>, automation_what_if: record<include: bool>, cover: record<include: bool>, documents: list<string>, elapse_time: record<include: bool>, evaluations: record<additional_column: string, include: bool>, field_automation: record<include: bool>, inboxes: list<string>, lines: record<include: bool>, metadata: record<columns: list<string>, fields: record<annotations: list, lines: list, meta_information: list>, include: bool, rename: record>, name: string, page_classification: record<include: bool>, projects: list<string>, sections: record<include: bool>, separator: string, sources: list<string>, text: record<include: bool>, version_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}"))
  let req_body = {"annotations": $annotations, "automation_blockers": $automation_blockers, "automation_score": $automation_score, "automation_what_if": $automation_what_if, "cover": $cover, "documents": $documents, "elapse_time": $elapse_time, "evaluations": $evaluations, "field_automation": $field_automation, "inboxes": $inboxes, "lines": $lines, "metadata": $metadata, "name": $name, "page_classification": $page_classification, "projects": $projects, "sections": $sections, "separator": $separator, "sources": $sources, "text": $text, "version_name": $version_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate report based on report id
#
# POST /reports/{report_id}/generate
# operationId: post_generate_report_id_resource
export def "reports-generate create-resource-by-report-id" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delivery-method: string@delivery-method-completer
  --email: string
  --start-date: string # format: date-time
  --end-date: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let qp = [(serialize-qp "delivery_method" $delivery_method "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/generate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"delivery_method": $delivery_method, "email": $email, "start_date": $start_date, "end_date": $end_date} | compact), body: null}
}

# Get all roles
#
# GET /roles
# operationId: get_roles_resource
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create role
#
# POST /roles
# operationId: post_roles_resource
# --permissions shape: {create_dropbox_user?: bool, create_inbox?: bool, create_webhook?: bool, de_escalate_document?: bool, delete_tenant?: bool, delete_webhook?: bool, edit_backend_settings?: bool, edit_beats?: bool, edit_dashboard_settings?: bool, edit_data_retention_settings?: bool, edit_flow_settings?: bool, edit_format_settings?: bool, edit_integration_settings?: bool, edit_integrations?: bool, edit_predictor_settings?: bool, edit_reports?: bool, edit_retention_settings?: bool, edit_review_settings?: bool, ... (32 more fields)}
export def "roles create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  name: string
  permissions: record # shape: {create_dropbox_user?: bool, create_inbox?: bool, create_webhook?: bool, de_escalate_document?: bool, delete_tenant?: bool, delete_webhook?: bool, edit_backend_settings?: bool, edit_beats?: bool, edit_dashboard_settings?: bool, edit_data_retention_settings?: bool, edit_flow_settings?: bool, edit_format_settings?: bool, edit_integration_settings?: bool, edit_integrations?: bool, edit_predictor_settings?: bool, edit_reports?: bool, edit_retention_settings?: bool, edit_review_settings?: bool, ... (32 more fields)}
]: any -> record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let req_body = {"name": $name, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role
#
# DELETE /roles/{role_id}
# operationId: delete_role_resource
export def "roles delete-resource" [
  role_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role_id' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get role
#
# GET /roles/{role_id}
# operationId: get_role_resource
export def "roles get-resource" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role_id' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update role
#
# PATCH /roles/{role_id}
# operationId: patch_role_resource
# --permissions shape: {create_dropbox_user?: bool, create_inbox?: bool, create_webhook?: bool, de_escalate_document?: bool, delete_tenant?: bool, delete_webhook?: bool, edit_backend_settings?: bool, edit_beats?: bool, edit_dashboard_settings?: bool, edit_data_retention_settings?: bool, edit_flow_settings?: bool, edit_format_settings?: bool, edit_integration_settings?: bool, edit_integrations?: bool, edit_predictor_settings?: bool, edit_reports?: bool, edit_retention_settings?: bool, edit_review_settings?: bool, ... (32 more fields)}
export def "roles update-resource" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --name: string
  --permissions: record # shape: {create_dropbox_user?: bool, create_inbox?: bool, create_webhook?: bool, de_escalate_document?: bool, delete_tenant?: bool, delete_webhook?: bool, edit_backend_settings?: bool, edit_beats?: bool, edit_dashboard_settings?: bool, edit_data_retention_settings?: bool, edit_flow_settings?: bool, edit_format_settings?: bool, edit_integration_settings?: bool, edit_integrations?: bool, edit_predictor_settings?: bool, edit_reports?: bool, edit_retention_settings?: bool, edit_review_settings?: bool, ... (32 more fields)}
]: any -> record<name: string, permissions: record<create_dropbox_user: bool, create_inbox: bool, create_webhook: bool, de_escalate_document: bool, delete_tenant: bool, delete_webhook: bool, edit_backend_settings: bool, edit_beats: bool, edit_dashboard_settings: bool, edit_data_retention_settings: bool, edit_flow_settings: bool, edit_format_settings: bool, edit_integration_settings: bool, edit_integrations: bool, edit_predictor_settings: bool, edit_reports: bool, edit_retention_settings: bool, edit_review_settings: bool, edit_roles: bool, edit_sampling_settings: bool, edit_security_settings: bool, edit_templates: bool, edit_thresholds_settings: bool, edit_translations: bool, edit_users: bool, escalate_document: bool, never_twice: bool, pick_next_escalated: bool, read_beats: bool, read_data_retention_settings: bool, read_feedback: bool, read_integrations: bool, read_release_notes: bool, read_reports: bool, read_thresholds_settings: bool, read_webhook: bool, reject_document: bool, release_lock: bool, review: bool, submit: bool, update_webhook: bool, upload: bool, versions: bool, view_api_keys: bool, view_list: bool, view_projects: bool, view_statistics: bool, view_templates: bool, write_feedback: bool, write_release_notes: bool>, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role_id' must be non-empty" } }
  let full_url = (build-url $base ({role_id: (encode-path-segment $role_id)} | format pattern "/roles/{role_id}"))
  let req_body = {"name": $name, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all rule configs
#
# GET /rule_config
# operationId: get_rule_configs_resource
export def "rule-config list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<rule_config: record, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rule_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the regexes that are generated by the rule
#
# POST /rule_config/rule_entity/
# operationId: post_debug_rule_entity_resource
export def "rule-config-rule-entity create-debug-resource" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rule_config/rule_entity/")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Evaluate a rule on a document
#
# POST /rule_config/rule_entity/{document_id}
# operationId: post_debug_rule_entity_document_resource
export def "rule-config-rule-entity create-debug-resource-by-document-id" [
  document_id: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/rule_config/rule_entity/{document_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the text a where_to_search specification will generate
#
# POST /rule_config/where_to_search/{document_id}
# operationId: post_debug_where_to_search
export def "rule-config-where-to-search create-debug" [
  document_id: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/rule_config/where_to_search/{document_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete scoped rule config
#
# DELETE /rule_config/{scope}
# operationId: delete_rule_config_resource
export def "rule-config delete-resource" [
  scope: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/rule_config/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get scoped rule config
#
# GET /rule_config/{scope}
# operationId: get_rule_config_resource
export def "rule-config get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<rule_config: record, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/rule_config/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update scoped rule config
#
# PATCH /rule_config/{scope}
# operationId: patch_rule_config_resource
export def "rule-config update-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --rule-config: record
]: any -> record<rule_config: record, scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/rule_config/{scope}"))
  let req_body = {"rule_config": $rule_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all sampling settings
#
# GET /sampling_settings
# operationId: get_setting_samplings_resource
export def "sampling-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sampling_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete scoped sampling settings
#
# DELETE /sampling_settings/{scope}
# operationId: delete_setting_sampling_resource
export def "sampling-settings delete-resource" [
  scope: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/sampling_settings/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get scoped sampling settings
#
# GET /sampling_settings/{scope}
# operationId: get_setting_sampling_resource
export def "sampling-settings get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/sampling_settings/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update scoped sampling settings
#
# PATCH /sampling_settings/{scope}
# operationId: patch_setting_sampling_resource
export def "sampling-settings update-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --auto-reject-ffr: int
  --auto-submit-ffr: int
  --second-pass-ffr: int
  --second-pass-stp: int
]: any -> record<auto_reject_FFR: int, auto_submit_FFR: int, second_pass_FFR: int, second_pass_STP: int, scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/sampling_settings/{scope}"))
  let req_body = {"auto_reject_FFR": $auto_reject_ffr, "auto_submit_FFR": $auto_submit_ffr, "second_pass_FFR": $second_pass_ffr, "second_pass_STP": $second_pass_stp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get scoped dashboard setting
#
# GET /settings/dashboard
# operationId: get_dashboard_settings_atomic_resource
export def "settings-dashboard get-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
  --qp-full: oneof<nothing, bool> # default: false
  --x-fields: string # An optional fields mask
]: nothing -> record<autolearning: bool, dashboard_timeout: int, default_date_range: record, default_inbox_size: record, default_inbox_sorting: record, flexible_filters: list<record>, navigation_menu: record, process_unreadable: bool, sequence_columns_of_inbox: record<columns_headers: list<record>, inline_headers: list<record>>, show_digital_annotations: bool, show_filters: record, show_inbox_actions: record, studio_format_options: record, upload_options: record, welcome_counters: bool, welcome_counters_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "full" $qp_full "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settings/dashboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scope": $scope, "full": $qp_full} | compact), body: null}
}

# Update scoped dashboard setting
#
# PATCH /settings/dashboard
# operationId: patch_dashboard_settings_atomic_resource
# --settings shape: {autolearning?: bool, dashboard_timeout?: int, default_date_range?: record, default_inbox_size?: record, default_inbox_sorting?: record, flexible_filters?: list, navigation_menu?: record, process_unreadable?: bool, sequence_columns_of_inbox?: record, show_digital_annotations?: bool, show_filters?: record, show_inbox_actions?: record, studio_format_options?: record, upload_options?: record, welcome_counters?: bool, welcome_counters_options?: record}
export def "settings-dashboard update-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --scope: string
  --settings: record # shape: {autolearning?: bool, dashboard_timeout?: int, default_date_range?: record, default_inbox_size?: record, default_inbox_sorting?: record, flexible_filters?: list, navigation_menu?: record, process_unreadable?: bool, sequence_columns_of_inbox?: record, show_digital_annotations?: bool, show_filters?: record, show_inbox_actions?: record, studio_format_options?: record, upload_options?: record, welcome_counters?: bool, welcome_counters_options?: record}
]: any -> record<autolearning: bool, dashboard_timeout: int, default_date_range: record, default_inbox_size: record, default_inbox_sorting: record, flexible_filters: list<record>, navigation_menu: record, process_unreadable: bool, sequence_columns_of_inbox: record<columns_headers: list<record>, inline_headers: list<record>>, show_digital_annotations: bool, show_filters: record, show_inbox_actions: record, studio_format_options: record, upload_options: record, welcome_counters: bool, welcome_counters_options: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/dashboard")
  let req_body = {"scope": $scope, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get scoped review setting
#
# GET /settings/review
# operationId: get_review_settings_atomic_resource
export def "settings-review get-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
  --qp-full: oneof<nothing, bool> # default: false
  --x-fields: string # An optional fields mask
]: nothing -> record<default_zoom: record, first_toolbar: record, lock_expiry: record, review_options: record, second_toolbar: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "full" $qp_full "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settings/review" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scope": $scope, "full": $qp_full} | compact), body: null}
}

# Update scoped review setting
#
# PATCH /settings/review
# operationId: patch_review_settings_atomic_resource
# --settings shape: {default_zoom?: record, first_toolbar?: record, lock_expiry?: record, review_options?: record, second_toolbar?: record}
export def "settings-review update-atomic-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --scope: string
  --settings: record # shape: {default_zoom?: record, first_toolbar?: record, lock_expiry?: record, review_options?: record, second_toolbar?: record}
]: any -> record<default_zoom: record, first_toolbar: record, lock_expiry: record, review_options: record, second_toolbar: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/review")
  let req_body = {"scope": $scope, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /sso/config
#
# operationId: get_sso_config_resources
export def "sso-config get-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<extra: record<entity_id: string, specification_url: string>, id: string, provider: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sso/config
#
# operationId: post_sso_config_resources
# --extra shape: {entity_id?: string, specification_url?: string}
export def "sso-config create-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --extra: record # shape: {entity_id?: string, specification_url?: string}
  provider: string # usually your company name, only used for visualisation: log in as employee
  --type: string@type-completer-2 # Type of SSO integration, for now only SAML is supported (default: saml, e.g. saml)
  --url: string # SAML-P sign-on endpoint (e.g. https://login.microsoftonline.com/e8656a10-4ec3-4cea-aa49-cbe9424c312d/saml2)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/config")
  let req_body = {"extra": $extra, "provider": $provider, "type": $type, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get integration attributes
#
# DELETE /sso/config/{sso_config_id}
# operationId: delete_sso_config_resources
export def "sso-config delete-resources" [
  sso_config_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($sso_config_id | is-empty) { error make --unspanned { msg: "path parameter 'sso_config_id' must be non-empty" } }
  let full_url = (build-url $base ({sso_config_id: (encode-path-segment $sso_config_id)} | format pattern "/sso/config/{sso_config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /sso/login
#
# operationId: post_oauth_login_resource
export def "sso-login create-oauth-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # the access token (JWT for oauth or SAML response)
  --type: string@type-completer-3 # the type of SSO token (e.g. oauth)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/login")
  let req_body = {"token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /stats/usage
#
# operationId: get_usage_stats_resource
export def "stats-usage get-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbox-id: string
  --start-date: string # default: 2023-01-31T13:36:39
  --end-date: string # default: 2023-03-02T13:36:39
  --excel-output: oneof<nothing, bool> # Set to 'true' to get data in an excel. (Default output format: JSON) (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inbox_id" $inbox_id "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "excel_output" $excel_output "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"inbox_id": $inbox_id, "start_date": $start_date, "end_date": $end_date, "excel_output": $excel_output} | compact), body: null}
}

# Get inbox statistics
#
# GET /stats/{inbox_id}
# operationId: get_stats_resource
export def "stats get-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string # The field names to include in the stats. If left empty, all fields are included.Additionally, `__all_fields__` field name is also added, and aggregates the stats for all fields
  --start-date: string # The minimum upload time of the file. If left empty, no filter is applied. (format: date-time)
  --end-date: string # The maximum upload time of the file. If left empty, no filter is applied. (format: date-time)
  --version-name: string # The name of the version to evaluate. If left empty, latest evaluated version is chosen.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "field_name" $field_name "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "version_name" $version_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/stats/{inbox_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"field_name": $field_name, "start_date": $start_date, "end_date": $end_date, "version_name": $version_name} | compact), body: null}
}

# Get summary or details of automation blockers
#
# GET /stats/{inbox_id}/automation_blockers
# operationId: get_automation_blockers_stats
export def "stats-automation-blockers get" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.252495
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.252527
  --version-name: string # provide the version name to evaluate (default: predicted)
  --include-detail: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "version_name" $version_name "scalar") (serialize-qp "include_detail" $include_detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/stats/{inbox_id}/automation_blockers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "version_name": $version_name, "include_detail": $include_detail} | compact), body: null}
}

# Get the Blue Dots statistics for the inbox
#
# POST /stats/{inbox_id}/blue_dots
# operationId: post_blue_dots_resource
export def "stats-blue-dots create-resource" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.250962
  --fields-to-exclude: string # gross_amount,due_date (default: )
  --level: string # possible values: file, field (default: file)
  --option-level-fields: string # invoice,receipt (default: )
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.250933
  --version-name: string # provide the version name to evaluate (default: submitted)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/stats/{inbox_id}/blue_dots"))
  let req_body = {"end_date": $end_date, "fields_to_exclude": $fields_to_exclude, "level": $level, "option_level_fields": $option_level_fields, "start_date": $start_date, "version_name": $version_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get the documents with evaluated versions
#
# GET /stats/{inbox_id}/evaluated_versions
# operationId: get_evaluated_versions
export def "stats-evaluated-versions get" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.251355
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.251385
  --filter-versions: oneof<nothing, bool> # default: false
  --last-one-only: oneof<nothing, bool> # default: true
  --version-name: string # filter the version by name. If not specified, all version names are considered
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "filter_versions" $filter_versions "scalar") (serialize-qp "last_one_only" $last_one_only "scalar") (serialize-qp "version_name" $version_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/stats/{inbox_id}/evaluated_versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "filter_versions": $filter_versions, "last_one_only": $last_one_only, "version_name": $version_name} | compact), body: null}
}

# Get processing runtime stats
#
# GET /stats/{inbox_id}/processing
# operationId: get_processing_stats
export def "stats-processing get" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.251761
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.251794
  --group-by: string # Group stats per this given attribute. Only **pages** is supported (default: pages)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/stats/{inbox_id}/processing") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "group_by": $group_by} | compact), body: null}
}

# **Permission required:** view_statistics
#
# GET /stats/{inbox_id}/volume
# operationId: get_volume_stats
export def "stats-volume get" [
  inbox_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.252098
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.252127
  --status: string # default: to_review
  --user: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($inbox_id | is-empty) { error make --unspanned { msg: "path parameter 'inbox_id' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inbox_id: (encode-path-segment $inbox_id)} | format pattern "/stats/{inbox_id}/volume") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "status": $status, "user": $user} | compact), body: null}
}

# Get the Accuracy counts on documents, sections and fields in the given inbox
#
# GET /stats/{scope}/accuracy
# operationId: get_accuracy_resource
export def "stats-accuracy get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.250494
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.250527
  --stp-files-only: oneof<nothing, bool> # default: false
  --stp-fields-only: oneof<nothing, bool> # default: false
  --version-name: string # provide the version name to evaluate
  --filter-by: string # Choose to filter the results by doctype, process label, ...
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "stp_files_only" $stp_files_only "scalar") (serialize-qp "stp_fields_only" $stp_fields_only "scalar") (serialize-qp "version_name" $version_name "scalar") (serialize-qp "filter_by" $filter_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/stats/{scope}/accuracy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "stp_files_only": $stp_files_only, "stp_fields_only": $stp_fields_only, "version_name": $version_name, "filter_by": $filter_by} | compact), body: null}
}

# Get the STP counts on documents, sections and fields in the given inbox
#
# GET /stats/{scope}/stp
# operationId: get_stp_resource
export def "stats-stp get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, default: 2023-02-02T13:36:39.250021
  --end-date: string # format: date-time, default: 2023-03-02T13:36:39.250091
  --version-name: string # Provide the evaluated version name to inspect automation (of the predictions) for (default: predicted)
  --filter-by: string # Choose to filter the results by doctype, process label, ...
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "version_name" $version_name "scalar") (serialize-qp "filter_by" $filter_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/stats/{scope}/stp") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "version_name": $version_name, "filter_by": $filter_by} | compact), body: null}
}

# Get the custom CSS file
#
# GET /style/custom.css
# operationId: get_style_sheet_resource
export def "style-custom-css get-sheet-resource" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/style/custom.css")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload the custom logo
#
# POST /style/custom.css
# operationId: post_style_sheet_resource
export def "style-custom-css create-sheet-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # File to handle (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/style/custom.css")
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get the custom logo
#
# GET /style/logo.png
# operationId: get_style_logo_resource
export def "style-logo-png get-resource" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/style/logo.png")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload the custom logo
#
# POST /style/logo.png
# operationId: post_style_logo_resource
export def "style-logo-png create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # File to handle (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/style/logo.png")
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# DELETE /tenant
#
# operationId: delete_tenant_resource
export def "tenant delete-resource" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tenant")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PATCH /tenant/activate
#
# operationId: patch_activate_tenant_resource
export def "tenant-activate update-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --code: int
  --email: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tenant/activate")
  let req_body = {"code": $code, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all thresholds settings
#
# GET /threshold_settings
# operationId: get_settings_threshold_resource
export def "threshold-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<thresholds: record<annotations: record, lines: record, sections: record>, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/threshold_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete the thresholds settings
#
# DELETE /threshold_settings/{scope}
# operationId: delete_setting_threshold_resource
export def "threshold-settings delete-resource" [
  scope: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/threshold_settings/{scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the scoped thresholds settings
#
# GET /threshold_settings/{scope}
# operationId: get_setting_threshold_resource
export def "threshold-settings get-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool> # default: false
  --x-fields: string # An optional fields mask
]: nothing -> record<thresholds: record<annotations: record, lines: record, sections: record>, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let qp = [(serialize-qp "default" $default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/threshold_settings/{scope}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"default": $default} | compact), body: null}
}

# Update the scoped thresholds settings
#
# PATCH /threshold_settings/{scope}
# operationId: patch_setting_threshold_resource
# --thresholds shape: {annotations?: record, lines?: record, sections?: record}
export def "threshold-settings update-resource" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --thresholds: record # shape: {annotations?: record, lines?: record, sections?: record}
]: any -> record<thresholds: record<annotations: record, lines: record, sections: record>, scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/threshold_settings/{scope}"))
  let req_body = {"thresholds": $thresholds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all users
#
# GET /users
# operationId: get_users_resource
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<active: bool, confirmed_at: string, id: string, roles: list<record>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create user
#
# POST /users
# operationId: post_users_resource
# --roles item shape: {document_id?: string, inbox?: string, role: string}
export def "users create-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --active: oneof<nothing, bool> # Inactive users have to reset their password first
  --password: string # the user password
  roles: list # the user roles — item shape: {document_id?: string, inbox?: string, role: string}
  username: string # the user username
]: any -> record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"active": $active, "password": $password, "roles": $roles, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return info on the current user
#
# GET /users/me
# operationId: get_me
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Change the current user password
#
# POST /users/me/change_password
# operationId: post_change_password
export def "users-me-change-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # the new user's password
  --old-password: string # the old user's password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/change_password")
  let req_body = {"new_password": $new_password, "old_password": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a user
#
# DELETE /users/{user_id}
# operationId: delete_user_resource
export def "users delete-resource" [
  user_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get user
#
# GET /users/{user_id}
# operationId: get_user_resource
export def "users get-resource" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update user
#
# PATCH /users/{user_id}
# operationId: patch_user_resource
# --roles item shape: {inbox?: string, role?: string}
export def "users update-resource" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --roles: list # the user roles — item shape: {inbox?: string, role?: string}
  --username: string # the user username
]: any -> record<active: bool, confirmed_at: string, id: string, roles: table<document_id: string, inbox: string, role: string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let req_body = {"roles": $roles, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
