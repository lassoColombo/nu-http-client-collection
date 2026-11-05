# Auto-generated client for IllumiDesk v1.0
# Source: https://api.apis.guru/v2/specs/illumidesk.com/1.0/swagger.json
# Auth: --token flag or $env.ILLUMIDESK_TOKEN

const BASE_URL = "https://api.illumidesk.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ILLUMIDESK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "jwt" => { {scheme: $scheme, headers: {"Authorization": $"JWT ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
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
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# HEAD — bodyless; default surfaces just the headers on success
def send-head [req: record, insecure: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http head --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure $req.url
  if (not $full) and (not $allow_errors) and (status-ok $resp.status $ok_codes) { return $resp.headers }
  $resp | handle-response $allow_errors $full $ok_codes
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
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

def base-url-completer [] { ["https://api.illumidesk.com"] }
def auth-scheme-completer [] { ["jwt" "none"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html"] }
def provider-completer [] { ["github" "google" "slack"] }
def entity-completer [] { ["billing"] }
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["auth-jwt-token-auth" "auth-jwt-token-refresh" "auth-jwt-token-verify" "oauth-login" "auth-register" "me" "servers-options-sizes-list" "servers-options-server-size-create" "servers-options-server-size-delete" "servers-options-resources-read" "servers-options-server-size-update" "servers-options-server-size-replace" "teams-list" "teams-create" "teams-delete" "teams-read" "teams-update" "teams-replace" "teams-billing-invoices-list" "teams-billing-invoices-read" "teams-billing-invoice-items-list" "teams-billing-invoice-items-read" "teams-billing-subscriptions-list" "teams-billing-subscriptions-create" "teams-billing-subscriptions-delete" "teams-billing-subscriptions-read" "teams-groups-list" "teams-groups-delete" "teams-groups-read" "teams-groups-update" "teams-groups-replace" "teams-groups-add-to-group" "teams-groups-remove-from-group" "users-list" "users-create" "users-delete" "users-read" "users-update" "users-api-key-list" "user-avatar-delete" "user-avatar-get" "user-avatar-update" "user-avatar-set" "users-emails-list" "users-emails-create" "users-emails-delete" "users-emails-read" "users-emails-update" "users-emails-replace" "users-ssh-key-list" "users-ssh-key-reset" "billing-cards-list" "billing-cards-create" "billing-cards-delete" "billing-cards-read" "billing-cards-update" "billing-cards-replace" "billing-invoices-list" "billing-invoices-read" "billing-invoice-items-list" "billing-invoice-items-read" "billing-plans-list" "billing-plans-read" "billing-subscriptions-list" "billing-subscriptions-create" "billing-subscriptions-delete" "billing-subscriptions-read" "notifications-list" "notifications-update-list" "notifications-list-entity" "notifications-update-entity-list" "notification-settings-read" "notification-settings-update" "notification-settings-create" "notification-settings-entity-read" "notification-settings-entity-update" "notification-settings-entity-create" "notification-read" "notification-update" "oauth-applications-list" "oauth-application-create" "oauth-application-delete" "oauth-application-read" "oauth-application-update" "oauth-application-replace" "projects-list" "projects-create" "project-copy-check" "project-copy" "projects-delete" "projects-read" "projects-update" "projects-replace" "projects-collaborators-list" "projects-collaborators-create" "projects-collaborators-delete" "projects-collaborators-read" "projects-collaborators-update" "projects-deployments-list" "projects-deployments-create" "projects-deployment-delete" "projects-deployments-read" "projects-deployments-update" "projects-deployments-replace" "projects-deployments-deploy" "projects-project-files-list" "projects-project-files-create" "projects-project-files-delete" "projects-project-files-read" "projects-project-files-update" "projects-project-files-replace" "projects-servers-list" "projects-servers-create" "projects-servers-statuses" "projects-servers-delete" "projects-servers-read" "projects-servers-update" "projects-servers-replace" "projects-servers-api-key" "projects-servers-auth" "projects-servers-run-stats-create" "projects-servers-run-stats-delete" "projects-servers-run-stats-read" "projects-servers-run-stats-update" "projects-servers-run-stats-replace" "projects-servers-ssh-tunnels-list" "projects-servers-ssh-tunnels-create" "projects-servers-ssh-tunnels-delete" "projects-servers-ssh-tunnels-read" "projects-servers-ssh-tunnels-update" "projects-servers-ssh-tunnels-replace" "projects-servers-start" "projects-servers-stats-delete" "projects-servers-stats-read" "projects-servers-stats-update" "projects-servers-stats-replace" "projects-servers-stop" "service-trigger-list" "service-trigger-create" "service-trigger-delete" "service-trigger-read" "service-trigger-update" "service-trigger-replace" "search" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "auth-jwt-token-auth" [
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
]: any -> oneof<record<token: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt-token-auth/" $auth.query)
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Refresh a JSON Web Token (JWT)
#
# POST /auth/jwt-token-refresh/
# operationId: auth_jwt-token-refresh
export def "auth-jwt-token-refresh" [
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
]: any -> oneof<record<token: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt-token-refresh/" $auth.query)
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Validate JSON Web Token (JWT)
#
# POST /auth/jwt-token-verify/
# operationId: auth_jwt-token-verify
export def "auth-jwt-token-verify" [
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
]: any -> oneof<record<token: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt-token-verify/" $auth.query)
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# GET /auth/login/{provider}/
#
# operationId: oauth_login
export def "oauth-login" [
  provider: string@provider-completer
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
  let full_url = (build-url $base ({provider: (encode-path-segment $provider)} | format pattern "/auth/login/{provider}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-get $req $insecure $raw $allow_errors $full [302]
}

# Register a user
#
# POST /auth/register/
# operationId: auth_register
export def "auth-register" [
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
]: any -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/register/" $auth.query)
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "password": $password, "profile": $profile, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# A convenience endpoint that is equivalent to GET /v1/users/profiles//
#
# GET /v1/me
# operationId: me
export def "me" [
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
]: nothing -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve available server sizes
#
# GET /v1/servers/options/server-size/
# operationId: servers_options_sizes_list
export def "servers-options-sizes-list" [
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
]: nothing -> oneof<table<active: bool, cpu: int, id: string, memory: int, name: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/servers/options/server-size/" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new server size item
#
# POST /v1/servers/options/server-size/
# operationId: servers_options_server_size_create
export def "servers-options-server-size-create" [
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
]: any -> oneof<record<active: bool, cpu: int, id: string, memory: int, name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/servers/options/server-size/" $auth.query)
  let req_body = {"active": $active, "cpu": $cpu, "memory": $memory, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "active") == null) { error make --unspanned { msg: "required body field 'active' missing: pass --active or pipe a record" } }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a server size by id
#
# DELETE /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_delete
export def "servers-options-server-size-delete" [
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
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a server size by id
#
# GET /v1/servers/options/server-size/{size}/
# operationId: servers_options_resources_read
export def "servers-options-resources-read" [
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
]: nothing -> oneof<record<active: bool, cpu: int, id: string, memory: int, name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a server size by id
#
# PATCH /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_update
export def "servers-options-server-size-update" [
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
]: any -> oneof<record<active: bool, cpu: int, id: string, memory: int, name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/") $auth.query)
  let req_body = {"active": $active, "cpu": $cpu, "memory": $memory, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "active") == null) { error make --unspanned { msg: "required body field 'active' missing: pass --active or pipe a record" } }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a server size by id
#
# PUT /v1/servers/options/server-size/{size}/
# operationId: servers_options_server_size_replace
export def "servers-options-server-size-replace" [
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
]: any -> oneof<record<active: bool, cpu: int, id: string, memory: int, name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({size: (encode-path-segment $size)} | format pattern "/v1/servers/options/server-size/{size}/") $auth.query)
  let req_body = {"active": $active, "cpu": $cpu, "memory": $memory, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "active") == null) { error make --unspanned { msg: "required body field 'active' missing: pass --active or pipe a record" } }
  let accept_val = ($accept | default "application/json")
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

# Get teams
#
# GET /v1/teams/
# operationId: teams_list
export def "teams-list" [
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
]: nothing -> oneof<table<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/teams/" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new team
#
# POST /v1/teams/
# operationId: teams_create
export def "teams-create" [
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
]: any -> oneof<record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams/" $auth.query)
  let req_body = {"avatar": $avatar, "avatar_url": $avatar_url, "description": $description, "location": $location, "name": $name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a team
#
# DELETE /v1/teams/{team}/
# operationId: teams_delete
export def "teams-delete" [
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
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a team
#
# GET /v1/teams/{team}/
# operationId: teams_read
export def "teams-read" [
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
]: nothing -> oneof<record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a team
#
# PATCH /v1/teams/{team}/
# operationId: teams_update
export def "teams-update" [
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
]: any -> oneof<record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/") $auth.query)
  let req_body = {"avatar": $avatar, "avatar_url": $avatar_url, "description": $description, "location": $location, "name": $name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a team
#
# PUT /v1/teams/{team}/
# operationId: teams_replace
export def "teams-replace" [
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
]: any -> oneof<record<avatar: string, avatar_url: string, created_by: string, description: string, id: string, location: string, name: string, website: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/") $auth.query)
  let req_body = {"avatar": $avatar, "avatar_url": $avatar_url, "description": $description, "location": $location, "name": $name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get team invoices
#
# GET /v1/teams/{team}/billing/invoices/
# operationId: teams_billing_invoices_list
export def "teams-billing-invoices-list" [
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
]: nothing -> oneof<table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/billing/invoices/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an invoice
#
# GET /v1/teams/{team}/billing/invoices/{id}/
# operationId: teams_billing_invoices_read
export def "teams-billing-invoices-read" [
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
]: nothing -> oneof<record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/invoices/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get team invoice items for a given invoice.
#
# GET /v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/
# operationId: teams_billing_invoice_items_list
export def "teams-billing-invoice-items-list" [
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
]: nothing -> oneof<table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific team InvoiceItem.
#
# GET /v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/{id}
# operationId: teams_billing_invoice_items_read
export def "teams-billing-invoice-items-read" [
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
]: nothing -> oneof<record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), invoice_id: (encode-path-segment $invoice_id), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/invoices/{invoice_id}/invoice-items/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get active team subscriptons
#
# GET /v1/teams/{team}/billing/subscriptions/
# operationId: teams_billing_subscriptions_list
export def "teams-billing-subscriptions-list" [
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
]: nothing -> oneof<table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/billing/subscriptions/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new team subscription
#
# POST /v1/teams/{team}/billing/subscriptions/
# operationId: teams_billing_subscriptions_create
export def "teams-billing-subscriptions-create" [
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
]: any -> oneof<record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/billing/subscriptions/") $auth.query)
  let req_body = {"plan": $plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a subscription
#
# DELETE /v1/teams/{team}/billing/subscriptions/{id}/
# operationId: teams_billing_subscriptions_delete
export def "teams-billing-subscriptions-delete" [
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
  let full_url = (build-url $base ({team: (encode-path-segment $team), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/subscriptions/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get team subscriptions
#
# GET /v1/teams/{team}/billing/subscriptions/{id}/
# operationId: teams_billing_subscriptions_read
export def "teams-billing-subscriptions-read" [
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
]: nothing -> oneof<record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), id: (encode-path-segment $id)} | format pattern "/v1/teams/{team}/billing/subscriptions/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get team groups
#
# GET /v1/teams/{team}/groups/
# operationId: teams_groups_list
export def "teams-groups-list" [
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
]: nothing -> oneof<table<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/v1/teams/{team}/groups/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete team group
#
# DELETE /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_delete
export def "teams-groups-delete" [
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
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get team group
#
# GET /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_read
export def "teams-groups-read" [
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
]: nothing -> oneof<record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Patch team group
#
# PATCH /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_update
export def "teams-groups-update" [
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
]: any -> oneof<record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/") $auth.query)
  let req_body = {"description": $description, "name": $name, "parent": $parent, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Patch team group
#
# PUT /v1/teams/{team}/groups/{group}/
# operationId: teams_groups_replace
export def "teams-groups-replace" [
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
]: any -> oneof<record<created_by: string, description: string, id: string, members: list<string>, name: string, parent: string, permissions: list<string>, private: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/") $auth.query)
  let req_body = {"description": $description, "name": $name, "parent": $parent, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Add user to group
#
# POST /v1/teams/{team}/groups/{group}/add/
# operationId: teams_groups_add_to_group
export def "teams-groups-add-to-group" [
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
]: nothing -> oneof<record<user: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/add/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# User removed from group
#
# POST /v1/teams/{team}/groups/{group}/remove/
# operationId: teams_groups_remove_from_group
export def "teams-groups-remove-from-group" [
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
  let full_url = (build-url $base ({team: (encode-path-segment $team), group: (encode-path-segment $group)} | format pattern "/v1/teams/{team}/groups/{group}/remove/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get user list
#
# GET /v1/users/profiles/
# operationId: users_list
export def "users-list" [
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
]: nothing -> oneof<table<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/profiles/" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "username": $username, "email": $email, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new user
#
# POST /v1/users/profiles/
# operationId: users_create
export def "users-create" [
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
]: any -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/profiles/" $auth.query)
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "password": $password, "profile": $profile, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a user
#
# DELETE /v1/users/profiles/{user}/
# operationId: users_delete
export def "users-delete" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/profiles/{user}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve a user
#
# GET /v1/users/profiles/{user}/
# operationId: users_read
export def "users-read" [
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
]: nothing -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/profiles/{user}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a user
#
# PATCH /v1/users/profiles/{user}/
# operationId: users_update
export def "users-update" [
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
]: any -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/profiles/{user}/") $auth.query)
  let req_body = {"email": $email, "first_name": $first_name, "last_name": $last_name, "password": $password, "profile": $profile, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve account's API key
#
# GET /v1/users/{user}/api-key/
# operationId: users_api-key_list
export def "users-api-key-list" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/api-key/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Delete avatar
#
# DELETE /v1/users/{user}/avatar/
# operationId: user_avatar_delete
export def "user-avatar-delete" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve user's avatar
#
# GET /v1/users/{user}/avatar/
# operationId: user_avatar_get
export def "user-avatar-get" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a project file
#
# PATCH /v1/users/{user}/avatar/
# operationId: user_avatar_update
export def "user-avatar-update" [
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
]: nothing -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# Add user avatar
#
# POST /v1/users/{user}/avatar/
# operationId: user_avatar_set
export def "user-avatar-set" [
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
]: nothing -> oneof<record<email: string, first_name: string, id: string, last_name: string, profile: record<avatar: string, bio: string, company: string, location: string, timezone: string, url: string>, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/avatar/") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Retrieve account email addresses
#
# GET /v1/users/{user}/emails/
# operationId: users_emails_list
export def "users-emails-list" [
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
]: nothing -> oneof<table<address: string, id: string, public: bool, unsubscribed: bool, user: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/emails/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an email address
#
# POST /v1/users/{user}/emails/
# operationId: users_emails_create
export def "users-emails-create" [
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
]: any -> oneof<record<address: string, id: string, public: bool, unsubscribed: bool, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/emails/") $auth.query)
  let req_body = {"address": $address, "public": $public, "unsubscribed": $unsubscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an email address
#
# DELETE /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_delete
export def "users-emails-delete" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve a user's email addresses
#
# GET /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_read
export def "users-emails-read" [
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
]: nothing -> oneof<record<address: string, id: string, public: bool, unsubscribed: bool, user: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an email address
#
# PATCH /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_update
export def "users-emails-update" [
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
]: any -> oneof<record<address: string, id: string, public: bool, unsubscribed: bool, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/") $auth.query)
  let req_body = {"address": $address, "public": $public, "unsubscribed": $unsubscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace an email address
#
# PUT /v1/users/{user}/emails/{email_id}/
# operationId: users_emails_replace
export def "users-emails-replace" [
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
]: any -> oneof<record<address: string, id: string, public: bool, unsubscribed: bool, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), email_id: (encode-path-segment $email_id)} | format pattern "/v1/users/{user}/emails/{email_id}/") $auth.query)
  let req_body = {"address": $address, "public": $public, "unsubscribed": $unsubscribed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Retrieve an SSH key
#
# GET /v1/users/{user}/ssh-key/
# operationId: users_ssh-key_list
export def "users-ssh-key-list" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/ssh-key/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Recreate an SSH key
#
# POST /v1/users/{user}/ssh-key/reset/
# operationId: users_ssh-key_reset
export def "users-ssh-key-reset" [
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
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/v1/users/{user}/ssh-key/reset/") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Get credit cards
#
# GET /v1/{namespace}/billing/cards/
# operationId: billing_cards_list
export def "billing-cards-list" [
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
]: nothing -> oneof<table<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/cards/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new credit card
#
# POST /v1/{namespace}/billing/cards/
# operationId: billing_cards_create
export def "billing-cards-create" [
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
]: any -> oneof<record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/cards/") $auth.query)
  let req_body = {"address_city": $address_city, "address_country": $address_country, "address_line1": $address_line1, "address_line2": $address_line2, "address_state": $address_state, "address_zip": $address_zip, "exp_month": $exp_month, "exp_year": $exp_year, "name": $name, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a credit card
#
# DELETE /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_delete
export def "billing-cards-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get credit card by id
#
# GET /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_read
export def "billing-cards-read" [
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
]: nothing -> oneof<record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a credit card
#
# PATCH /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_update
export def "billing-cards-update" [
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
]: any -> oneof<record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/") $auth.query)
  let req_body = {"address_city": $address_city, "address_country": $address_country, "address_line1": $address_line1, "address_line2": $address_line2, "address_state": $address_state, "address_zip": $address_zip, "exp_month": $exp_month, "exp_year": $exp_year, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a credit card
#
# PUT /v1/{namespace}/billing/cards/{id}/
# operationId: billing_cards_replace
export def "billing-cards-replace" [
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
]: any -> oneof<record<address_city: string, address_country: string, address_line1: string, address_line1_check: string, address_line2: string, address_state: string, address_zip: string, address_zip_check: string, brand: string, created: string, customer: string, cvc_check: string, exp_month: int, exp_year: int, fingerprint: string, funding: string, id: string, last4: string, name: string, stripe_id: string, token: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/cards/{id}/") $auth.query)
  let req_body = {"address_city": $address_city, "address_country": $address_country, "address_line1": $address_line1, "address_line2": $address_line2, "address_state": $address_state, "address_zip": $address_zip, "exp_month": $exp_month, "exp_year": $exp_year, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get invoices
#
# GET /v1/{namespace}/billing/invoices/
# operationId: billing_invoices_list
export def "billing-invoices-list" [
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
]: nothing -> oneof<table<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/invoices/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an invoice
#
# GET /v1/{namespace}/billing/invoices/{id}/
# operationId: billing_invoices_read
export def "billing-invoices-read" [
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
]: nothing -> oneof<record<amount_due: int, application_fee: int, attempt_count: int, attempted: bool, closed: bool, created: string, currency: string, customer: string, description: string, id: string, invoice_date: string, livemode: bool, metadata: record, next_payment_attempt: string, paid: bool, period_end: string, period_start: string, reciept_number: string, starting_balance: int, statement_descriptor: string, stripe_id: string, subscription: string, subtotal: int, tax: int, total: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/invoices/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get invoice items for a given invoice.
#
# GET /v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/
# operationId: billing_invoice_items_list
export def "billing-invoice-items-list" [
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
]: nothing -> oneof<table<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific InvoiceItem.
#
# GET /v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/{id}
# operationId: billing_invoice_items_read
export def "billing-invoice-items-read" [
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
]: nothing -> oneof<record<amount: int, created: string, currency: string, description: string, id: string, invoice: string, invoice_date: string, livemode: bool, metadata: record, proration: bool, quantity: int, stripe_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), invoice_id: (encode-path-segment $invoice_id), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/invoices/{invoice_id}/invoice-items/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get billing plans
#
# GET /v1/{namespace}/billing/plans/
# operationId: billing_plans_list
export def "billing-plans-list" [
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
]: nothing -> oneof<table<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/plans/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a billing plan
#
# GET /v1/{namespace}/billing/plans/{id}/
# operationId: billing_plans_read
export def "billing-plans-read" [
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
]: nothing -> oneof<record<amount: int, created: string, currency: string, id: string, interval: string, interval_count: int, livemode: bool, metadata: record, name: string, statement_descriptor: string, stripe_id: string, trial_period_days: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/plans/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get active subscriptons
#
# GET /v1/{namespace}/billing/subscriptions/
# operationId: billing_subscriptions_list
export def "billing-subscriptions-list" [
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
]: nothing -> oneof<table<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/subscriptions/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new subscription
#
# POST /v1/{namespace}/billing/subscriptions/
# operationId: billing_subscriptions_create
export def "billing-subscriptions-create" [
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
]: any -> oneof<record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/billing/subscriptions/") $auth.query)
  let req_body = {"plan": $plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a subscription
#
# DELETE /v1/{namespace}/billing/subscriptions/{id}/
# operationId: billing_subscriptions_delete
export def "billing-subscriptions-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/subscriptions/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a subscriptions
#
# GET /v1/{namespace}/billing/subscriptions/{id}/
# operationId: billing_subscriptions_read
export def "billing-subscriptions-read" [
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
]: nothing -> oneof<record<application_fee_percent: float, cancel_at_period_end: bool, canceled_at: string, created: string, current_period_end: string, current_period_start: string, ended_at: string, id: string, livemode: bool, plan: string, quantity: int, start: string, status: string, stripe_id: string, trial_end: string, trial_start: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/billing/subscriptions/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get notifications of all types and entities for the authenticated user.
#
# GET /v1/{namespace}/notifications/
# operationId: notifications_list
export def "notifications-list" [
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
]: nothing -> oneof<table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "read" $read "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering, "read": $read} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Mark a list of notifications as either read or unread.
#
# PATCH /v1/{namespace}/notifications/
# operationId: notifications_update_list
export def "notifications-update-list" [
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
]: any -> oneof<record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/") $auth.query)
  let req_body = {"notifications": $notifications, "read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "read") == null) { error make --unspanned { msg: "required body field 'read' missing: pass --read or pipe a record" } }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get notifications of all types and entities for the authenticated user.
#
# GET /v1/{namespace}/notifications/entity/{entity}
# operationId: notifications_list_entity
export def "notifications-list-entity" [
  namespace: string
  entity: string@entity-completer
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
]: nothing -> oneof<table<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "read" $read "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/entity/{entity}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering, "read": $read} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Mark a list of notifications as either read or unread.
#
# PATCH /v1/{namespace}/notifications/entity/{entity}
# operationId: notifications_update_entity_list
export def "notifications-update-entity-list" [
  namespace: string
  entity: string@entity-completer
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
]: any -> oneof<record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/entity/{entity}") $auth.query)
  let req_body = {"notifications": $notifications, "read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "read") == null) { error make --unspanned { msg: "required body field 'read' missing: pass --read or pipe a record" } }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve global notification settings for the authenticated user
#
# GET /v1/{namespace}/notifications/settings/
# operationId: notification_settings_read
export def "notification-settings-read" [
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
]: nothing -> oneof<table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/settings/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Modify global notification settings.
#
# PATCH /v1/{namespace}/notifications/settings/
# operationId: notification_settings_update
export def "notification-settings-update" [
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
]: any -> oneof<record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/settings/") $auth.query)
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "emails_enabled") == null) { error make --unspanned { msg: "required body field 'emails_enabled' missing: pass --emails-enabled or pipe a record" } }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create global notification settings
#
# POST /v1/{namespace}/notifications/settings/
# operationId: notification_settings_create
export def "notification-settings-create" [
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
]: any -> oneof<record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/notifications/settings/") $auth.query)
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "emails_enabled") == null) { error make --unspanned { msg: "required body field 'emails_enabled' missing: pass --emails-enabled or pipe a record" } }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve global notification settings for the authenticated user
#
# GET /v1/{namespace}/notifications/settings/entity/{entity}
# operationId: notification_settings_entity_read
export def "notification-settings-entity-read" [
  namespace: string
  entity: string@entity-completer
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
]: nothing -> oneof<table<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/settings/entity/{entity}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Modify global notification settings.
#
# PATCH /v1/{namespace}/notifications/settings/entity/{entity}
# operationId: notification_settings_entity_update
export def "notification-settings-entity-update" [
  namespace: string
  entity: string@entity-completer
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
]: any -> oneof<record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/settings/entity/{entity}") $auth.query)
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "emails_enabled") == null) { error make --unspanned { msg: "required body field 'emails_enabled' missing: pass --emails-enabled or pipe a record" } }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create global notification settings
#
# POST /v1/{namespace}/notifications/settings/entity/{entity}
# operationId: notification_settings_entity_create
export def "notification-settings-entity-create" [
  namespace: string
  entity: string@entity-completer
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
]: any -> oneof<record<email_address: string, emails_enabled: bool, enabled: bool, entity: string, id: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($entity | is-empty) { error make --unspanned { msg: "path parameter 'entity' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), entity: (encode-path-segment $entity)} | format pattern "/v1/{namespace}/notifications/settings/entity/{entity}") $auth.query)
  let req_body = {"emails_enabled": $emails_enabled, "enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "emails_enabled") == null) { error make --unspanned { msg: "required body field 'emails_enabled' missing: pass --emails-enabled or pipe a record" } }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve a specific notification.
#
# GET /v1/{namespace}/notifications/{notification_id}
# operationId: notification_read
export def "notification-read" [
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
]: nothing -> oneof<record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notification_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), notification_id: (encode-path-segment $notification_id)} | format pattern "/v1/{namespace}/notifications/{notification_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Mark a specific notification as either read or unread.
#
# PATCH /v1/{namespace}/notifications/{notification_id}
# operationId: notification_update
export def "notification-update" [
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
]: any -> oneof<record<actor: string, id: string, read: bool, target: string, timestamp: string, type: string, user: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($notification_id | is-empty) { error make --unspanned { msg: "path parameter 'notification_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), notification_id: (encode-path-segment $notification_id)} | format pattern "/v1/{namespace}/notifications/{notification_id}") $auth.query)
  let req_body = {"read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "read") == null) { error make --unspanned { msg: "required body field 'read' missing: pass --read or pipe a record" } }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve oauth applications
#
# GET /v1/{namespace}/oauth/applications/
# operationId: oauth_applications_list
export def "oauth-applications-list" [
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
]: nothing -> oneof<table<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/oauth/applications/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new OAuth2 application
#
# POST /v1/{namespace}/oauth/applications/
# operationId: oauth_application_create
export def "oauth-application-create" [
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
]: any -> oneof<record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/oauth/applications/") $auth.query)
  let req_body = {"authorization_grant_type": $authorization_grant_type, "client_type": $client_type, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an application by id
#
# DELETE /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_delete
export def "oauth-application-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get an application by id
#
# GET /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_read
export def "oauth-application-read" [
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
]: nothing -> oneof<record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an application by id
#
# PATCH /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_update
export def "oauth-application-update" [
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
]: any -> oneof<record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/") $auth.query)
  let req_body = {"authorization_grant_type": $authorization_grant_type, "client_type": $client_type, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace an application by id
#
# PUT /v1/{namespace}/oauth/applications/{application}/
# operationId: oauth_application_replace
export def "oauth-application-replace" [
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
]: any -> oneof<record<authorization_grant_type: string, client_id: string, client_secret: string, client_type: string, id: string, name: string, redirect_uris: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($application | is-empty) { error make --unspanned { msg: "path parameter 'application' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), application: (encode-path-segment $application)} | format pattern "/v1/{namespace}/oauth/applications/{application}/") $auth.query)
  let req_body = {"authorization_grant_type": $authorization_grant_type, "client_type": $client_type, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get available projects
#
# GET /v1/{namespace}/projects/
# operationId: projects_list
export def "projects-list" [
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
]: nothing -> oneof<table<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "private": $private, "name": $name, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new project
#
# POST /v1/{namespace}/projects/
# operationId: projects_create
export def "projects-create" [
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
]: any -> oneof<record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/") $auth.query)
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Check if you are able to copy a project to your account.
#
# HEAD /v1/{namespace}/projects/project-copy-check/
# operationId: project_copy_check
export def "project-copy-check" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/project-copy-check/") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "head"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-head $req $insecure $allow_errors $full [200]
}

# Copy a project to your own account.
#
# POST /v1/{namespace}/projects/project-copy/
# operationId: project_copy
export def "project-copy" [
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
]: any -> oneof<record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/projects/project-copy/") $auth.query)
  let req_body = {"name": $name, "project": $project} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a project
#
# DELETE /v1/{namespace}/projects/{project}/
# operationId: projects_delete
export def "projects-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a project
#
# GET /v1/{namespace}/projects/{project}/
# operationId: projects_read
export def "projects-read" [
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
]: nothing -> oneof<record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a project
#
# PATCH /v1/{namespace}/projects/{project}/
# operationId: projects_update
export def "projects-update" [
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
]: any -> oneof<record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/") $auth.query)
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a project
#
# PUT /v1/{namespace}/projects/{project}/
# operationId: projects_replace
export def "projects-replace" [
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
]: any -> oneof<record<collaborators: list<string>, description: string, id: string, last_updated: string, name: string, owner: string, private: bool, team: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/") $auth.query)
  let req_body = {"description": $description, "name": $name, "private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get project collaborators
#
# GET /v1/{namespace}/projects/{project}/collaborators/
# operationId: projects_collaborators_list
export def "projects-collaborators-list" [
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
]: nothing -> oneof<table<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create project collaborators
#
# POST /v1/{namespace}/projects/{project}/collaborators/
# operationId: projects_collaborators_create
export def "projects-collaborators-create" [
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
]: any -> oneof<record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/") $auth.query)
  let req_body = {"member": $member, "owner": $owner, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a project collaborator
#
# DELETE /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_delete
export def "projects-collaborators-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), collaborator: (encode-path-segment $collaborator)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a project collaborator
#
# GET /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_read
export def "projects-collaborators-read" [
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
]: nothing -> oneof<record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), collaborator: (encode-path-segment $collaborator)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update project collaborator
#
# PATCH /v1/{namespace}/projects/{project}/collaborators/{collaborator}/
# operationId: projects_collaborators_update
export def "projects-collaborators-update" [
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
]: any -> oneof<record<email: string, first_name: string, id: string, joined: string, last_name: string, owner: bool, permissions: list<string>, project: string, user: string, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), collaborator: (encode-path-segment $collaborator)} | format pattern "/v1/{namespace}/projects/{project}/collaborators/{collaborator}/") $auth.query)
  let req_body = {"member": $member, "owner": $owner, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve deployments
#
# GET /v1/{namespace}/projects/{project}/deployments/
# operationId: projects_deployments_list
export def "projects-deployments-list" [
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
]: nothing -> oneof<table<config: record<files: list, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/deployments/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new deployment
#
# POST /v1/{namespace}/projects/{project}/deployments/
# operationId: projects_deployments_create
export def "projects-deployments-create" [
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
]: any -> oneof<record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/deployments/") $auth.query)
  let req_body = {"config": $config, "framework": $framework, "name": $name, "runtime": $runtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a deployment
#
# DELETE /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployment_delete
export def "projects-deployment-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve a deployment
#
# GET /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployments_read
export def "projects-deployments-read" [
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
]: nothing -> oneof<record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a deployment
#
# PATCH /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployments_update
export def "projects-deployments-update" [
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
]: any -> oneof<record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/") $auth.query)
  let req_body = {"config": $config, "framework": $framework, "name": $name, "runtime": $runtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a deployment
#
# PUT /v1/{namespace}/projects/{project}/deployments/{deployment}/
# operationId: projects_deployments_replace
export def "projects-deployments-replace" [
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
]: any -> oneof<record<config: record<files: list<string>, handler: string>, created_at: string, created_by: string, framework: string, id: string, name: string, project: string, runtime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($deployment | is-empty) { error make --unspanned { msg: "path parameter 'deployment' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/") $auth.query)
  let req_body = {"config": $config, "framework": $framework, "name": $name, "runtime": $runtime} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Deploy an existing model
#
# POST /v1/{namespace}/projects/{project}/deployments/{deployment}/deploy/
# operationId: projects_deployments_deploy
export def "projects-deployments-deploy" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), deployment: (encode-path-segment $deployment)} | format pattern "/v1/{namespace}/projects/{project}/deployments/{deployment}/deploy/") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Get project files
#
# GET /v1/{namespace}/projects/{project}/project_files/
# operationId: projects_project_files_list
export def "projects-project-files-list" [
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
]: nothing -> oneof<table<content: string, id: string, name: string, path: string, project: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "content" $content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/project_files/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering, "filename": $filename, "content": $content} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create project files
#
# POST /v1/{namespace}/projects/{project}/project_files/
# operationId: projects_project_files_create
export def "projects-project-files-create" [
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
]: any -> oneof<record<content: string, id: string, name: string, path: string, project: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/project_files/") $auth.query)
  let req_body = {"file": $file, "base64_data": $base64_data, "name": $name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else if ($req_body == null) { {} } else { $req_body }
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body ["file"] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
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
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# Delete a project file
#
# DELETE /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_delete
export def "projects-project-files-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a project file
#
# GET /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_read
export def "projects-project-files-read" [
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
]: nothing -> oneof<record<content: string, id: string, name: string, path: string, project: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "content" $content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"content": $content} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a project file
#
# PATCH /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_update
export def "projects-project-files-update" [
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
]: any -> oneof<record<content: string, id: string, name: string, path: string, project: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/") $auth.query)
  let req_body = {"file": $file, "base64_data": $base64_data, "name": $name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else if ($req_body == null) { {} } else { $req_body }
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body ["file"] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Replace a project file
#
# PUT /v1/{namespace}/projects/{project}/project_files/{id}/
# operationId: projects_project_files_replace
export def "projects-project-files-replace" [
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
]: any -> oneof<record<content: string, id: string, name: string, path: string, project: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/project_files/{id}/") $auth.query)
  let req_body = {"file": $file, "base64_data": $base64_data, "name": $name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else if ($req_body == null) { {} } else { $req_body }
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body ["file"] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Retrieve servers
#
# GET /v1/{namespace}/projects/{project}/servers/
# operationId: projects_servers_list
export def "projects-servers-list" [
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
]: nothing -> oneof<table<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/servers/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new server
#
# POST /v1/{namespace}/projects/{project}/servers/
# operationId: projects_servers_create
export def "projects-servers-create" [
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
]: any -> oneof<record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/servers/") $auth.query)
  let req_body = {"config": $config, "connected": $connected, "host": $host, "image_name": $image_name, "name": $name, "server_size": $server_size, "startup_script": $startup_script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve server statuses
#
# GET /v1/{namespace}/projects/{project}/servers/statuses/
# operationId: projects_servers_statuses
export def "projects-servers-statuses" [
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
]: nothing -> oneof<table<id: string, status: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project)} | format pattern "/v1/{namespace}/projects/{project}/servers/statuses/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Delete a server
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_delete
export def "projects-servers-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_read
export def "projects-servers-read" [
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
]: nothing -> oneof<record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a server
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_update
export def "projects-servers-update" [
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
]: any -> oneof<record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/") $auth.query)
  let req_body = {"config": $config, "connected": $connected, "host": $host, "image_name": $image_name, "name": $name, "server_size": $server_size, "startup_script": $startup_script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a server
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/
# operationId: projects_servers_replace
export def "projects-servers-replace" [
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
]: any -> oneof<record<config: record, connected: list<string>, created_at: string, created_by: string, endpoint: string, host: string, id: string, image_name: string, logs_url: string, name: string, project: string, server_size: string, startup_script: string, status: string, status_url: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/") $auth.query)
  let req_body = {"config": $config, "connected": $connected, "host": $host, "image_name": $image_name, "name": $name, "server_size": $server_size, "startup_script": $startup_script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get server API key
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/api-key/
# operationId: projects_servers_api-key
export def "projects-servers-api-key" [
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
]: nothing -> oneof<record<token: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/api-key/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Server api key validation
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/auth/
# operationId: projects_servers_auth
export def "projects-servers-auth" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/auth/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Create a new server's run statistics
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/run-stats/
# operationId: projects_servers_run-stats_create
export def "projects-servers-run-stats-create" [
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
]: any -> oneof<record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/") $auth.query)
  let req_body = {"exit_code": $exit_code, "size": $size, "stacktrace": $stacktrace, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a server's statistics
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_delete
export def "projects-servers-run-stats-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve statistics for a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_read
export def "projects-servers-run-stats-read" [
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
]: nothing -> oneof<record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a server's statistics
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_update
export def "projects-servers-run-stats-update" [
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
]: any -> oneof<record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/") $auth.query)
  let req_body = {"exit_code": $exit_code, "size": $size, "stacktrace": $stacktrace, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a server's statistics
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/
# operationId: projects_servers_run-stats_replace
export def "projects-servers-run-stats-replace" [
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
]: any -> oneof<record<exit_code: int, id: string, server: string, size: int, stacktrace: string, start: string, stop: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/run-stats/{id}/") $auth.query)
  let req_body = {"exit_code": $exit_code, "size": $size, "stacktrace": $stacktrace, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get SSH Tunnels associated to a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/
# operationId: projects_servers_ssh-tunnels_list
export def "projects-servers-ssh-tunnels-list" [
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
]: nothing -> oneof<table<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create SSH Tunnel associated to a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/
# operationId: projects_servers_ssh-tunnels_create
export def "projects-servers-ssh-tunnels-create" [
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
]: any -> oneof<record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/") $auth.query)
  let req_body = {"endpoint": $endpoint, "host": $host, "local_port": $local_port, "name": $name, "remote_port": $remote_port, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an SSH Tunnel associated to a server
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_delete
export def "projects-servers-ssh-tunnels-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get an SSH Tunnel associated to a server
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_read
export def "projects-servers-ssh-tunnels-read" [
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
]: nothing -> oneof<record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an SSH Tunnel associated to a server
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_update
export def "projects-servers-ssh-tunnels-update" [
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
]: any -> oneof<record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/") $auth.query)
  let req_body = {"endpoint": $endpoint, "host": $host, "local_port": $local_port, "name": $name, "remote_port": $remote_port, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace SSH Tunnel associated to a server
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/
# operationId: projects_servers_ssh-tunnels_replace
export def "projects-servers-ssh-tunnels-replace" [
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
]: any -> oneof<record<endpoint: string, host: string, id: string, local_port: int, name: string, remote_port: int, server: string, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($tunnel | is-empty) { error make --unspanned { msg: "path parameter 'tunnel' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), tunnel: (encode-path-segment $tunnel)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/ssh-tunnels/{tunnel}/") $auth.query)
  let req_body = {"endpoint": $endpoint, "host": $host, "local_port": $local_port, "name": $name, "remote_port": $remote_port, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Start a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/start/
# operationId: projects_servers_start
export def "projects-servers-start" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/start/") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Delete a server's statistics
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_delete
export def "projects-servers-stats-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve a server's statistics
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_read
export def "projects-servers-stats-read" [
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
]: nothing -> oneof<record<id: string, server: string, size: int, start: string, stop: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a server's statistics
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_update
export def "projects-servers-stats-update" [
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
]: any -> oneof<record<id: string, server: string, size: int, start: string, stop: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/") $auth.query)
  let req_body = {"id": $body_id, "non_field_errors": $non_field_errors, "size": $size, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a server's statistics
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/
# operationId: projects_servers_stats_replace
export def "projects-servers-stats-replace" [
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
]: any -> oneof<record<id: string, server: string, size: int, start: string, stop: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), id: (encode-path-segment $id)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stats/{id}/") $auth.query)
  let req_body = {"id": $body_id, "non_field_errors": $non_field_errors, "size": $size, "start": $start, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Stop a server
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/stop/
# operationId: projects_servers_stop
export def "projects-servers-stop" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/stop/") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Retrieve server triggers
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/triggers/
# operationId: service_trigger_list
export def "service-trigger-list" [
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
]: nothing -> oneof<table<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "limit": $limit, "offset": $offset, "ordering": $ordering} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new server trigger
#
# POST /v1/{namespace}/projects/{project}/servers/{server}/triggers/
# operationId: service_trigger_create
export def "service-trigger-create" [
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
]: any -> oneof<record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/") $auth.query)
  let req_body = {"name": $name, "operation": $operation, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a server trigger
#
# DELETE /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_delete
export def "service-trigger-delete" [
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
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a server trigger
#
# GET /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_read
export def "service-trigger-read" [
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
]: nothing -> oneof<record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a server trigger
#
# PATCH /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_update
export def "service-trigger-update" [
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
]: any -> oneof<record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/") $auth.query)
  let req_body = {"name": $name, "operation": $operation, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Replace a server trigger
#
# PUT /v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/
# operationId: service_trigger_replace
export def "service-trigger-replace" [
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
]: any -> oneof<record<id: string, name: string, operation: string, webhook: record<payload: record, url: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($server | is-empty) { error make --unspanned { msg: "path parameter 'server' must be non-empty" } }
  if ($trigger | is-empty) { error make --unspanned { msg: "path parameter 'trigger' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), project: (encode-path-segment $project), server: (encode-path-segment $server), trigger: (encode-path-segment $trigger)} | format pattern "/v1/{namespace}/projects/{project}/servers/{server}/triggers/{trigger}/") $auth.query)
  let req_body = {"name": $name, "operation": $operation, "webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get a search results
#
# GET /v1/{namespace}/search/
# operationId: search
export def "search" [
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
  --q: string # Search string. (required)
  --type: string@type-completer # Limit results to specific types.
  --limit: string # Limit data when getting items.
  --offset: string # Offset data when getting items.
]: nothing -> oneof<list<record>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($q == null) { error make --unspanned { msg: "required query parameter 'q' missing: pass --q" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/v1/{namespace}/search/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "type": $type, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
