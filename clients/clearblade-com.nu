# Auto-generated client for ClearBlade API v3.0
# Source: https://api.apis.guru/v2/specs/clearblade.com/3.0/swagger.json
# Auth: --token flag or $env.CLEARBLADE_API_TOKEN

const BASE_URL = "https://platform.clearblade.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CLEARBLADE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://platform.clearblade.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dev-get-assets" } } | get name | first)
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

# DEVELOPER - Get platform assets
#
# GET /admin/allapps
# operationId: DevGetAssets
export def "dev-get-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/allapps" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get collections
#
# GET /admin/allcollections
# operationId: DevGetCollections
export def "dev-get-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --appid: string # System Key that identifies the system the collections belong to.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appid" $appid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/allcollections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"appid": $appid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get systems
#
# GET /admin/allsystems
# operationId: GetSystems
export def "get-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/allsystems" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# AUDIT - Get Audit Info
#
# GET /admin/audit
# operationId: GetAudit
export def "get-audit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/audit" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Audit - Get counts
#
# GET /admin/audit/count
# operationId: GetCounts
export def "get-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/audit/count" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# AUDIT - Get Audit Info
#
# GET /admin/audit/{systemKey}
# operationId: GetAuditDev
export def "get-audit-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/audit/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# AUDIT - Get counts
#
# GET /admin/audit/{systemKey}/count
# operationId: GetCountsDev
export def "get-counts-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/audit/{system_key}/count") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Authenticate dev
#
# POST /admin/auth
# operationId: AuthDev
export def "auth-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/auth" $auth.query)
  let req_body = {"email": $email, "password": $password} | compact
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

# DEVELOPER - Verifies access to the system
#
# POST /admin/checkauth
# operationId: VerifyAuth
export def "verify-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/checkauth" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# DEVELOPER - Delete collection
#
# DELETE /admin/collectionmanagement
# operationId: DevDeleteCollection
export def "dev-delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/collectionmanagement" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Create collection
#
# POST /admin/collectionmanagement
# operationId: DevCreateCollection
export def "dev-create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication.
  app_id: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collection-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/collectionmanagement" $auth.query)
  let req_body = {"appID": $app_id, "collectionID": $collection_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update collection
#
# PUT /admin/collectionmanagement
# operationId: DevUpdateCollection
# --addColumn shape: {id: string, name: string, type: string}
export def "dev-update-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --add-column: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/collectionmanagement" $auth.query)
  let req_body = {"addColumn": $add_column, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADMIN - Get number of admin developers
#
# GET /admin/count/developers
# operationId: GetAdminDevCount
export def "get-admin-dev-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/count/developers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADMIN - Get number of systems available
#
# GET /admin/count/systems
# operationId: GetSystemCount
export def "get-system-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/count/systems" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DATABASES - Retrieves all internal and external database statuses
#
# GET /admin/database/status
# operationId: GetDatabaseStatus
export def "get-database-status" [
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
  let full_url = (build-url $base "/admin/database/status" $auth.query)
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

# ADMIN - Add/Remove/Change owner
#
# PUT /admin/developers/{systemKey}
# operationId: AdminOwnerChange
export def "admin-owner-change" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  change: any
  owner: string # e.g. owner@clearblade.com
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/developers/{system_key}") $auth.query)
  let req_body = {"change": $change, "owner": $owner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete rotating keys for a device
#
# DELETE /admin/devices/keys/{systemKey}/{deviceName}
# operationId: DeleteDeviceKeys
export def "delete-device-keys" [
  system_key: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($device_name | is-empty) { error make --unspanned { msg: "path parameter 'deviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), device_name: (encode-path-segment $device_name)} | format pattern "/admin/devices/keys/{system_key}/{device_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVICE -Creates rotating keys for a device.
#
# POST /admin/devices/keys/{systemKey}/{deviceName}
# operationId: CreateRotatingKeys
export def "create-rotating-keys" [
  system_key: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
  --body: record
]: any -> record<active_key: string, keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($device_name | is-empty) { error make --unspanned { msg: "path parameter 'deviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), device_name: (encode-path-segment $device_name)} | format pattern "/admin/devices/keys/{system_key}/{device_name}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete devices using a query
#
# DELETE /admin/devices/{systemKey}
# operationId: DeleteDevicesAdmin
export def "delete-devices-admin" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-dev-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/devices/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get devices with or without a query
#
# GET /admin/devices/{systemKey}
# operationId: GetSystemDevices
export def "get-system-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example. All devices are returned if a query is not specified.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/devices/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Update devices using a query
#
# PUT /admin/devices/{systemKey}
# operationId: UpdateDevicesAdmin
# --$set shape: {[columnName]?: any}
# --query item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
export def "update-devices-admin" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through user authentication.
  --set: record # shape: {[columnName]?: any}
  --query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> record<DATA: list<record>, TOTAL: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/devices/{system_key}") $auth.query)
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete device
#
# DELETE /admin/devices/{systemKey}/{name}
# operationId: DeleteSystemDevice
export def "delete-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get device
#
# GET /admin/devices/{systemKey}/{name}
# operationId: GetSystemDevice
export def "get-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Create device
#
# POST /admin/devices/{systemKey}/{name}
# operationId: CreateSystemDevice
export def "create-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --active-key: string
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --custom: string
  --description: string
  --enabled: oneof<nothing, bool>
  --keys: string
  --body-name: string
  state: string
  type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}") $auth.query)
  let req_body = {"active_key": $active_key, "allow_certificate_auth": $allow_certificate_auth, "allow_key_auth": $allow_key_auth, "certificate": $certificate, "custom": $custom, "description": $description, "enabled": $enabled, "keys": $keys, "name": $body_name, "state": $state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update device
#
# PUT /admin/devices/{systemKey}/{name}
# operationId: UpdateSystemDevice
export def "update-system-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --active-key: string
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --custom: string
  --description: string
  --enabled: oneof<nothing, bool>
  --keys: string
  --state: string
  --type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}") $auth.query)
  let req_body = {"active_key": $active_key, "allow_certificate_auth": $allow_certificate_auth, "allow_key_auth": $allow_key_auth, "certificate": $certificate, "custom": $custom, "description": $description, "enabled": $enabled, "keys": $keys, "state": $state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get edge template
#
# GET /admin/edges/template/{systemKey}
# operationId: GetEdgeTemplate
export def "get-edge-template" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/edges/template/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update edge template
#
# PUT /admin/edges/template/{systemKey}/{edgeName}
# operationId: UpdateEdgeTemplate
# --def_module shape: {module?: "trigger"|"service"|"library"}
export def "update-edge-template" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --def-module: any # shape: {module?: "trigger"|"service"|"library"}
  def_name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($edge_name | is-empty) { error make --unspanned { msg: "path parameter 'edgeName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/template/{system_key}/{edge_name}") $auth.query)
  let req_body = {"def_module": $def_module, "def_name": $def_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get edges
#
# GET /admin/edges/{systemKey}
# operationId: GetEdges
export def "get-edges" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/edges/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get edges for the adapter
#
# GET /admin/edges/{systemKey}/control
# operationId: GetAdapterEdges
export def "get-adapter-edges" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/edges/{system_key}/control") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete edge
#
# DELETE /admin/edges/{systemKey}/{edgeName}
# operationId: DeleteEdge
export def "delete-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($edge_name | is-empty) { error make --unspanned { msg: "path parameter 'edgeName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get edge
#
# GET /admin/edges/{systemKey}/{edgeName}
# operationId: GetEdge
export def "get-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($edge_name | is-empty) { error make --unspanned { msg: "path parameter 'edgeName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Create edge
#
# POST /admin/edges/{systemKey}/{edgeName}
# operationId: CreateEdge
export def "create-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($edge_name | is-empty) { error make --unspanned { msg: "path parameter 'edgeName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}") $auth.query)
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update edge
#
# PUT /admin/edges/{systemKey}/{edgeName}
# operationId: UpdateEdge
export def "update-edge" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($edge_name | is-empty) { error make --unspanned { msg: "path parameter 'edgeName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}") $auth.query)
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Log out dev
#
# POST /admin/logout
# operationId: DevLogout
export def "dev-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/logout" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# ADMIN - Get platform license key.
#
# GET /admin/pkey
# operationId: GetLicenseKey
export def "get-license-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/pkey" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADMIN - Get developer
#
# GET /admin/platform/developer
# operationId: GetDev
export def "get-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer: string # Email of the developer in question.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developer" $developer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/developer" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"developer": $developer} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Disable developer
#
# POST /admin/platform/developer
# operationId: DisableDev
export def "disable-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --admin: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/platform/developer" $auth.query)
  let req_body = {"admin": $admin, "disabled": $disabled, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADMIN - Get developers
#
# GET /admin/platform/developers
# operationId: GetDevs
export def "get-devs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: string # Response page size.
  --pagenum: string # Response page number.
  --total: string
  --filter: string # Filter response.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenum" $pagenum "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/developers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "pagenum": $pagenum, "total": $total, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems
# operationId: GetSystemUpdates
export def "get-system-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/systems" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Clearblade-DevToken": $clearblade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems/{systemKey}
# operationId: GetSystemUpdatesDev
export def "get-system-updates-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-devtoken: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/platform/systems/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"clearblade-devtoken": $clearblade_devtoken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# ADMIN - Get system status
#
# GET /admin/platform/{systemKey}
# operationId: GetSystemStatus
export def "get-system-status" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/platform/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Gets the information for a portal
#
# GET /admin/portals/{systemKey}
# operationId: GetPortalInfo
export def "get-portal-info" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
]: nothing -> table<config: record, description: string, last_updated: string, name: string, namespace: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/portals/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Change dev password
#
# PUT /admin/putpass
# operationId: ChangeDevPassword
export def "change-dev-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  new_password: string # e.g. bieberluver
  old_password: string # e.g. bieberboy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/putpass" $auth.query)
  let req_body = {"new_password": $new_password, "old_password": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Register new dev
#
# POST /admin/reg
# operationId: RegDev
export def "reg-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Developer's email. (e.g. martin@clearblade.com)
  fname: string # Developer's first name. (e.g. Martin)
  lname: string # Developer's last name. (e.g. theMachine)
  org: string # Developer's organization. (e.g. ClearBlade)
  password: string # Developer's password. (e.g. bieberboy)
]: any -> record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/reg" $auth.query)
  let req_body = {"email": $email, "fname": $fname, "lname": $lname, "org": $org, "password": $password} | compact
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

# DEVELOPER - Regen secret
#
# PUT /admin/regensystemsecret
# operationId: RegenSecret
export def "regen-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  id: string # e.g. [systemID]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/regensystemsecret" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADMIN - Change dev password (Admin)
#
# POST /admin/resetpassword
# operationId: ResetPassword
export def "reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --email: string # e.g. example@clearblade.com
  --new-password: string # e.g. password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/resetpassword" $auth.query)
  let req_body = {"email": $email, "new_password": $new_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Delete email settings
#
# DELETE /admin/settings/email-service
# operationId: DeleteEmailSettings
export def "delete-email-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Get Email Settings
#
# GET /admin/settings/email-service
# operationId: EmailSettings
export def "email-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<encryption_type: string, from: string, host: string, password: string, port: string, protocol: string, two_factor_message: string, two_factor_subject: string, username: string, validation_message: string, validation_subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Create Email Communication
#
# POST /admin/settings/email-service
# operationId: CreateEmailCommunication
export def "create-email-communication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --encryption-type: string # e.g. STARTTLS
  --body-from: string # e.g. example@gmail.com
  --host: string # e.g. smtp.gmail.com
  --password: string # e.g. test
  --port: string # e.g. 587
  --protocol: string # e.g. SMTP
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --two-factor-subject: string # e.g. Login code
  --username: string # e.g. example@gmail.com
  --validation-message: string # e.g. Please validate your email here: $LINK
  --validation-subject: string # e.g. Email validation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service" $auth.query)
  let req_body = {"encryption_type": $encryption_type, "from": $body_from, "host": $host, "password": $password, "port": $port, "protocol": $protocol, "two_factor_message": $two_factor_message, "two_factor_subject": $two_factor_subject, "username": $username, "validation_message": $validation_message, "validation_subject": $validation_subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Update Email Settings
#
# PUT /admin/settings/email-service
# operationId: UpdateEmailSettings
export def "update-email-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --encryption-type: string # e.g. STARTTLS
  --body-from: string # e.g. example@gmail.com
  --host: string # e.g. smtp.gmail.com
  --password: string # e.g. test
  --port: string # e.g. 587
  --protocol: string # e.g. SMTP
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --two-factor-subject: string # e.g. Login code
  --username: string # e.g. example@gmail.com
  --validation-message: string # e.g. Please validate your email here: $LINK
  --validation-subject: string # e.g. Email validation
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service" $auth.query)
  let req_body = {"encryption_type": $encryption_type, "from": $body_from, "host": $host, "password": $password, "port": $port, "protocol": $protocol, "two_factor_message": $two_factor_message, "two_factor_subject": $two_factor_subject, "username": $username, "validation_message": $validation_message, "validation_subject": $validation_subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Test Email Service
#
# POST /admin/settings/email-service/test
# operationId: TestEmail
export def "test-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --recipient: string # e.g. example@companyname.com
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service/test" $auth.query)
  let req_body = {"recipient": $recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - View Security Settings
#
# GET /admin/settings/security
# operationId: ViewSecurity
export def "view-security" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/security" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Update Security Settings
#
# PUT /admin/settings/security
# operationId: UpdateSecurity
# --two_factor_auth shape: {enabled?: bool}
export def "update-security" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --developer-token-ttl: int # e.g. 86400
  --two-factor-auth: any # shape: {enabled?: bool}
]: any -> record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/security" $auth.query)
  let req_body = {"developer_token_ttl": $developer_token_ttl, "two_factor_auth": $two_factor_auth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Delete SMS settings
#
# DELETE /admin/settings/sms-service
# operationId: DeleteSMSSettings
export def "delete-sms-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Get SMS Settings
#
# GET /admin/settings/sms-service
# operationId: SMSSettings
export def "sms-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<from: string, password: string, service_name: string, two_factor_message: string, url: string, username: string, validation_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Create SMS Communication
#
# POST /admin/settings/sms-service
# operationId: CreateSMSCommunication
export def "create-sms-communication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body-from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service" $auth.query)
  let req_body = {"from": $body_from, "password": $password, "service_name": $service_name, "two_factor_message": $two_factor_message, "url": $url, "username": $username, "validation_message": $validation_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Update SMS Settings
#
# PUT /admin/settings/sms-service
# operationId: UpdateSMSSettings
export def "update-sms-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body-from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service" $auth.query)
  let req_body = {"from": $body_from, "password": $password, "service_name": $service_name, "two_factor_message": $two_factor_message, "url": $url, "username": $username, "validation_message": $validation_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Test SMS Service
#
# POST /admin/settings/sms-service/test
# operationId: TestSMS
export def "test-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --recipient: string # e.g. +15120000000
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service/test" $auth.query)
  let req_body = {"recipient": $recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# Get Systems for a developer
#
# GET /admin/systems/{devEmail}
# operationId: GetSystemsForDev
export def "get-systems-for-dev" [
  dev_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dev_email | is-empty) { error make --unspanned { msg: "path parameter 'devEmail' must be non-empty" } }
  let full_url = (build-url $base ({dev_email: (encode-path-segment $dev_email)} | format pattern "/admin/systems/{dev_email}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get trigger definitions
#
# GET /admin/triggers/definitions
# operationId: GetTriggers
export def "get-triggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/triggers/definitions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get trigger handlers
#
# GET /admin/triggers/handlers/{systemKey}
# operationId: GetTriggerHandlers
export def "get-trigger-handlers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/triggers/handlers/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/handlers/{systemKey}/{name}
# operationId: DeleteTriggerHandler
export def "delete-trigger-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get trigger handler
#
# GET /admin/triggers/handlers/{systemKey}/{name}
# operationId: GetTriggerHandler
export def "get-trigger-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Create trigger handler
#
# POST /admin/triggers/handlers/{systemKey}/{name}
# operationId: CreateTrigger
# --key_value_pairs shape: {topic?: string}
export def "create-trigger" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}") $auth.query)
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update trigger handler
#
# PUT /admin/triggers/handlers/{systemKey}/{name}
# operationId: UpdateTriggerHandler
# --key_value_pairs shape: {topic?: string}
export def "update-trigger-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}") $auth.query)
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get timer handlers
#
# GET /admin/triggers/timers/{systemKey}
# operationId: GetTimerHandlers
export def "get-timer-handlers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/triggers/timers/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/timers/{systemKey}/{name}
# operationId: DeleteTimerHandler
export def "delete-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get timer handler
#
# GET /admin/triggers/timers/{systemKey}/{name}
# operationId: GetTimerHandler
export def "get-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Create time handler
#
# POST /admin/triggers/timers/{systemKey}/{name}
# operationId: create_timer_handler
export def "create-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}") $auth.query)
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update timer handler
#
# PUT /admin/triggers/timers/{systemKey}/{name}
# operationId: UpdateTimerHandler
export def "update-timer-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}") $auth.query)
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete user
#
# DELETE /admin/user/{systemKey}
# operationId: DeleteUser
export def "delete-user" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # UserId of the user to delete
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get list of users and information
#
# GET /admin/user/{systemKey}
# operationId: GetUserList
export def "get-user-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter users. Check 'users' model at the bottom of this page.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Add user
#
# POST /admin/user/{systemKey}
# operationId: AddUser
export def "add-user" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  email: string # e.g. helpme@clearblade.com
  password: string # e.g. c13rb1ad3ru13z
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}") $auth.query)
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Change user information and permissions
#
# PUT /admin/user/{systemKey}
# operationId: UserChangeUserInfo
# --changes shape: {roles: any}
export def "user-change-user-info" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  changes: any # Changes roles — shape: {roles: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}") $auth.query)
  let req_body = {"changes": $changes, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get users column info.
#
# GET /admin/user/{systemKey}/columns
# operationId: GetUserColumnData
export def "get-user-column-data" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/columns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Add new column
#
# POST /admin/user/{systemKey}/columns
# operationId: AddColumn
export def "add-column" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  column_name: string # e.g. phone_number
  type: string # e.g. string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/columns") $auth.query)
  let req_body = {"column_name": $column_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete roles
#
# DELETE /admin/user/{systemKey}/roles
# operationId: DeleteRoles
export def "delete-roles" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Role identification key.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get list of roles
#
# GET /admin/user/{systemKey}/roles
# operationId: GetRoles
export def "get-roles" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Refer to the example query above.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Add new role
#
# POST /admin/user/{systemKey}/roles
# operationId: AddRole
export def "add-role" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --collections: list # e.g. []
  --description: string # e.g. 
  name: string # e.g. Administrator
  --services: list # e.g. []
  --topics: list # e.g. []
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles") $auth.query)
  let req_body = {"collections": $collections, "description": $description, "name": $name, "services": $services, "topics": $topics} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Changes roles settings
#
# PUT /admin/user/{systemKey}/roles
# operationId: SettingsChanges
# --changes shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
export def "settings-changes" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  changes: any # Assets with permission changes — shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
  id: string # e.g. Administrator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles") $auth.query)
  let req_body = {"changes": $changes, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get number of roles
#
# GET /admin/user/{systemKey}/roles/count
# operationId: GetRolesCount
export def "get-roles-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Identifies page size and page number for roles list.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles/count") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get dev info
#
# GET /admin/userinfo
# operationId: GetDevInfo
export def "get-dev-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<admin: bool, creation_date: int, email: string, email_validated: bool, fname: string, last_login: int, lname: string, org: string, phone: string, phone_validated: bool, two_factor_enabled: bool, two_factor_enabled_instance_: bool, two_factor_method: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/userinfo" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Update developer 2FA information.
#
# PUT /admin/userinfo
# operationId: UpdateDev2FA
export def "update-dev2-fa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --phone: string # e.g. +15120000000
  --two-factor-enabled: oneof<nothing, bool> # e.g. true
  --two-factor-method: string # e.g. sms
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/userinfo" $auth.query)
  let req_body = {"phone": $phone, "two_factor_enabled": $two_factor_enabled, "two_factor_method": $two_factor_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# SHARED CACHE - Gets shared caches for a system
#
# GET /admin/v/4/service_caches/{systemKey}
# operationId: GetSharedCache
export def "get-shared-cache" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
]: nothing -> table<description: string, id: string, name: string, system_key: string, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/service_caches/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# SHARED CACHE - Delete a shared cache
#
# DELETE /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: DeleteSharedCache
export def "delete-shared-cache" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($cache_name | is-empty) { error make --unspanned { msg: "path parameter 'cacheName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), cache_name: (encode-path-segment $cache_name)} | format pattern "/admin/v/4/service_caches/{system_key}/{cache_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# SHARED CACHE - Add a shared cache
#
# POST /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: addSharedCache
export def "add-shared-cache" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
  --description: string # Description of new shared cache
  --name: string # e.g. sharedCache
  ttl: int # e.g. 30
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($cache_name | is-empty) { error make --unspanned { msg: "path parameter 'cacheName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), cache_name: (encode-path-segment $cache_name)} | format pattern "/admin/v/4/service_caches/{system_key}/{cache_name}") $auth.query)
  let req_body = {"description": $description, "name": $name, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# SHARED CACHE - Update a shared cache
#
# PUT /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: UpdateSharedCache
export def "update-shared-cache" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
  --description: string
  ttl: int # e.g. 30
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($cache_name | is-empty) { error make --unspanned { msg: "path parameter 'cacheName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), cache_name: (encode-path-segment $cache_name)} | format pattern "/admin/v/4/service_caches/{system_key}/{cache_name}") $auth.query)
  let req_body = {"description": $description, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# SESSION - Delete device session
#
# DELETE /admin/v/4/session/{systemKey}/device
# operationId: DeleteDeviceSession
export def "delete-device-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/device") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# SESSION - Get device session info
#
# GET /admin/v/4/session/{systemKey}/device
# operationId: GetDeviceSession
export def "get-device-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<device_key: string, issued: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/device") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# SESSION - Get device session count
#
# GET /admin/v/4/session/{systemKey}/device/count
# operationId: GetDeviceSessionCount
export def "get-device-session-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/device/count") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# SESSION - Delete user session
#
# DELETE /admin/v/4/session/{systemKey}/user
# operationId: DeleteUserSession
export def "delete-user-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/user") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# SESSION - Get user session info
#
# GET /admin/v/4/session/{systemKey}/user
# operationId: GetUserSession
export def "get-user-session" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<issued: int, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/user") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# SESSION - Get user session count
#
# GET /admin/v/4/session/{systemKey}/user/count
# operationId: GetUserSessionCount
export def "get-user-session-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/user/count") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Delete system
#
# DELETE /admin/v/4/systemmanagement
# operationId: DeleteSystem
export def "delete-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want to delete.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get system info
#
# GET /admin/v/4/systemmanagement
# operationId: GetSystemInfo
export def "get-system-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Create system
#
# POST /admin/v/4/systemmanagement
# operationId: CreateSystem
export def "create-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
  description: string # e.g. Here is my new system.
  name: string # e.g. ExampleSystem
]: any -> record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $auth.query)
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update system info
#
# PUT /admin/v/4/systemmanagement
# operationId: UpdateSystem
export def "update-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --dev: string # Developer Id for the owner of the system (e.g. 92f8dbbb0bccb3fff4be5cdb601)
  --app-id: string # system key (e.g. a6e0f8e20bbefcec789de6b8f4cf01)
  --app-secret: string # system secret (e.g. A6E0F8E20BDEB0C2838EF2B6D09801)
  --auth-service: string # Configure the system to have all authentication requests go through a specific Code Service. (e.g. )
  --description: string # e.g. Here is my new system.
  --name: string # e.g. ExampleSystem
  --reg-service: string # Configure the system to have all registration requests go through a specific Code Service. (e.g. )
  --registration: string # e.g. 
  --token-ttl: string # ttl for developer tokens in seconds. Min - 86400 (1 day), Max- 2592000 (30 days), Default - 432000 Infinite - -1 (e.g. 432000)
  --token-ttl-anon: int # ttl for anonymous tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-device: string # ttl for device tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-user: string # ttl for user tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $auth.query)
  let req_body = {"Dev": $dev, "appId": $app_id, "appSecret": $app_secret, "auth_service": $auth_service, "description": $description, "name": $name, "reg_service": $reg_service, "registration": $registration, "token_ttl": $token_ttl, "token_ttl_anon": $token_ttl_anon, "token_ttl_device": $token_ttl_device, "token_ttl_user": $token_ttl_user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# WEBHOOKS - Returns webhooks in the system
#
# GET /admin/v/4/webhook/{systemKey}
# operationId: GetWebhooks
export def "get-webhooks" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> table<auth_method: string, description: string, id: string, name: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/webhook/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# WEBHOOKS - Delete a webhook
#
# DELETE /admin/v/4/webhook/{systemKey}/{name}
# operationId: DeleteWebhook
export def "delete-webhook" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/v/4/webhook/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# WEBHOOKS - Creates a webhook
#
# POST /admin/v/4/webhook/{systemKey}/{name}
# operationId: CreateWebhook
export def "create-webhook" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
  --body-name: string # e.g. webhook_example
  service_name: string # e.g. service_example
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/v/4/webhook/{system_key}/{name}") $auth.query)
  let req_body = {"auth_method": $auth_method, "description": $description, "name": $body_name, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# WEBHOOKS - Update a webhook
#
# PUT /admin/v/4/webhook/{systemKey}/{name}
# operationId: UpdateWebhook
export def "update-webhook" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/v/4/webhook/{system_key}/{name}") $auth.query)
  let req_body = {"auth_method": $auth_method, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# 2FA - Send validation link
#
# POST /admin/validate
# operationId: SendValidation
export def "send-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --type: string # e.g. email
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/validate" $auth.query)
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# EDGE - Gets sync status for all edges
#
# GET /admin/{systemKey}/sync/alledges/status
# operationId: AllEdgeSyncStatus
export def "all-edge-sync-status" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/{system_key}/sync/alledges/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEPLOYMENTS - Gets sync status for a deployment
#
# GET /admin/{systemKey}/sync/deployment/status/{deploymentName}
# operationId: GetSyncStatus
export def "get-sync-status" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/admin/{system_key}/sync/deployment/status/{deployment_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# EDGE - Gets sync status for an edge
#
# GET /admin/{systemKey}/sync/edge/status/{edgeName}
# operationId: EdgeSyncStatus
export def "edge-sync-status" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($edge_name | is-empty) { error make --unspanned { msg: "path parameter 'edgeName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/{system_key}/sync/edge/status/{edge_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEPLOYMENTS - Retries sync for an asset
#
# POST /admin/{systemKey}/sync/retry
# operationId: RetrySync
export def "retry-sync" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
  --asset-class: string # Asset Type (e.g. services)
  --asset-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  --edge: string # Edge Name (e.g. ExampleEdge)
  --is-collection: oneof<nothing, bool>
  --sync-event: int # e.g. 0 (Insert)/1 (Update)/2 (Delete)/5 (Upsert)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/{system_key}/sync/retry") $auth.query)
  let req_body = {"asset_class": $asset_class, "asset_id": $asset_id, "edge": $edge, "is_collection": $is_collection, "sync_event": $sync_event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Gets the information for the platform
#
# GET /api/about
# operationId: APIInfo
export def "api-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<about: record, buildId: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/about" $auth.query)
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

# CODE - Retrieve information about service
#
# GET /api/v/1/code/{systemKey}/{serviceName}
# operationId: GetService
export def "get-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/api/v/1/code/{system_key}/{service_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# CODE - Call/Execute code service
#
# POST /api/v/1/code/{systemKey}/{serviceName}
# operationId: ExecuteService
export def "execute-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/api/v/1/code/{system_key}/{service_name}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATA(name) - Delete items
#
# DELETE /api/v/1/collection/{systemKey}/{collectionName}
# operationId: DeleteCollectionData
export def "delete-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to limit scope of deletion.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DATA(name) - Get items
#
# GET /api/v/1/collection/{systemKey}/{collectionName}
# operationId: GetCollectionData
export def "get-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model below for example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DATA(name) - Create items
#
# POST /api/v/1/collection/{systemKey}/{collectionName}
# operationId: CreateCollectionData
export def "create-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: list
]: any -> table<item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATA(name) - Update items
#
# PUT /api/v/1/collection/{systemKey}/{collectionName}
# operationId: UpdateCollectionData
# --$set shape: {columnName?: any}
# --query shape: {FILTERS?: list}
export def "update-collection-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --set: record # shape: {columnName?: any}
  --query: any # shape: {FILTERS?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}") $auth.query)
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATA(id) - Delete items
#
# DELETE /api/v/1/data/{collectionID}
# operationId: DeleteCollectionDataAlt
export def "delete-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to limit scope of deletion.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionID' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DATA(id) - Get items
#
# GET /api/v/1/data/{collectionID}
# operationId: GetCollectionDataAlt
export def "get-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model below for example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionID' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DATA(id) - Create items
#
# POST /api/v/1/data/{collectionID}
# operationId: CreateCollectionDataAlt
export def "create-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: list
]: any -> table<item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionID' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATA(id) - Update items
#
# PUT /api/v/1/data/{collectionID}
# operationId: UpdateCollectionDataAlt
# --$set shape: {columnName?: any}
# --query shape: {FILTERS?: list}
export def "update-collection-data-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --set: record # shape: {columnName?: any}
  --query: any # shape: {FILTERS?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionID' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}") $auth.query)
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATA(id) - Get columns
#
# GET /api/v/1/data/{collectionID}/columns
# operationId: GetColumns
export def "get-columns" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system that holds the collection.
  --clear-blade-system-secret: string # header parameter for ensuring authenticity
]: nothing -> table<ColumnName: string, ColumnType: string, PK: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionID' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}/columns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
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

# MESSAGING - Delete history
#
# DELETE /api/v/1/message/{systemKey}
# operationId: DeleteMessageHistory
export def "delete-message-history" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # Messaging topic to delete the history for.
  --count: string # Number of messages to delete. 0 deletes all messages.
  --last: string # Point in time to start deleting. (epoch timestamp)
  --start: string # Start time for deleting within a timeframe. (epoch timestamp)
  --stop: string # End time for deleting within a timeframe. (epoch timestamp)
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "topic" $topic "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/1/message/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"topic": $topic, "count": $count, "last": $last, "start": $start, "stop": $stop} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# MESSAGING - Get history
#
# GET /api/v/1/message/{systemKey}
# operationId: GetMessageHistory
export def "get-message-history" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # Messaging topic to retrieve the history for.
  --count: string # Number of messages to retrieve. 0 retrieves all messages.
  --last: string # Point in time to start search. (epoch timestamp)
  --start: string # Start time for searching within a timeframe. (epoch timestamp)
  --stop: string # End time for searching within a timeframe. (epoch timestamp)
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "topic" $topic "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/1/message/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"topic": $topic, "count": $count, "last": $last, "start": $start, "stop": $stop} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# MESSAGING - Publish message
#
# POST /api/v/1/message/{systemKey}/publish
# operationId: PublishMessage
export def "publish-message" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: string # e.g. {"temperature":43}
  --qos: float # e.g. 0
  topic: string # e.g. /sensor/111111
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/1/message/{system_key}/publish") $auth.query)
  let req_body = {"body": $body, "qos": $qos, "topic": $topic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# USERS - Get all users
#
# GET /api/v/1/user
# operationId: GetUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the user list. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<Data: table<creation_date: string, email: string, user_id: string>, Total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v/1/user" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# USERS - Authenticate anonymous user
#
# POST /api/v/1/user/anon
# operationId: AuthAnon
export def "auth-anon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're logging the user into.
  --clear-blade-system-secret: string # System Secret that ensures authenticity.
]: nothing -> record<user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/anon" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# USERS - Authenticate user
#
# POST /api/v/1/user/auth
# operationId: AuthUser
export def "auth-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're logging the user into.
  --clear-blade-system-secret: string # System Secret that ensures authenticity.
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> record<expires_at: int, refresh_token: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/auth" $auth.query)
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
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

# USERS - Check user auth
#
# POST /api/v/1/user/checkauth
# operationId: UserCheckAuth
export def "user-check-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system the user might be logged into.
  --clear-blade-user-token: string # User Token obtained through previous authentication.
]: nothing -> record<is_authenticated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/checkauth" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Allows an user with adequate permissions to delete another user
#
# DELETE /api/v/1/user/info
# operationId: DeleteUserAsUser
export def "delete-user-as-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string
  --clear-blade-system-secret: string
  --user-id: string # e.g. c6b4cf0b8ca5b7c3fad793cb12
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info" $auth.query)
  let req_body = {"user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# USERS - Get user info
#
# GET /api/v/1/user/info
# operationId: GetUserInfo
export def "get-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<creation_date: string, email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# USERS - Update user info
#
# PUT /api/v/1/user/info
# operationId: UpdateUserInfo
export def "update-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --column-name: string # e.g. column_value
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info" $auth.query)
  let req_body = {"column_name": $column_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# USERS - Log out user
#
# POST /api/v/1/user/logout
# operationId: UserLogout
export def "user-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/logout" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# USERS - Change user password
#
# PUT /api/v/1/user/pass
# operationId: UpdateUserPass
export def "update-user-pass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  new_password: string # e.g. P@ssw0rd
  old_password: string # e.g. cl34rbl4d3
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/pass" $auth.query)
  let req_body = {"new_password": $new_password, "old_password": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# USERS - Register new user
#
# POST /api/v/1/user/reg
# operationId: RegUser
export def "reg-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
  --clear-blade-system-secret: string # System Secret that ensures authenticity.
  --clear-blade-user-token: string # Token obtained through user authentication.
  email: string # User's email. (e.g. cbman@clearblade.com)
  password: string # User's password. (e.g. cl34rbl4d3)
]: any -> record<creation_date: string, email: string, expires_at: int, options: string, refresh_token: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/reg" $auth.query)
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret, "ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEVICES - Delete devices using a query
#
# DELETE /api/v/2/devices/{SystemKey}
# operationId: DeleteDevices
export def "delete-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DEVICES - Get all devices
#
# GET /api/v/2/devices/{SystemKey}
# operationId: GetDevices
export def "get-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVICES - Update devices using a query
#
# PUT /api/v/2/devices/{SystemKey}
# operationId: UpdateDevices
# --$set shape: {[columnName]?: any}
# --query item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
export def "update-devices" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --set: record # shape: {[columnName]?: any}
  --query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> record<DATA: list<record>, TOTAL: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}") $auth.query)
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEVICES - Authenticate device
#
# POST /api/v/2/devices/{SystemKey}/auth
# operationId: AuthDevice
export def "auth-device" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  active_key: string # e.g. 378BLE
  device_name: string # e.g. BLEdevice
]: any -> record<deviceName: string, deviceToken: string, expiresAt: int, refreshToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}/auth") $auth.query)
  let req_body = {"activeKey": $active_key, "deviceName": $device_name} | compact
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

# DEVICES - Adds a device
#
# POST /api/v/2/devices/{systemKey}/{name}
# operationId: AddDevice
export def "add-device" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --active-key: string # e.g. 1574445864
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --description: string # e.g. This is a sensor
  --body-name: string # e.g. device_name
  --state: string # e.g. On
  --type: string # e.g. Sensor
]: any -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/2/devices/{system_key}/{name}") $auth.query)
  let req_body = {"active_key": $active_key, "allow_certificate_auth": $allow_certificate_auth, "allow_key_auth": $allow_key_auth, "certificate": $certificate, "description": $description, "name": $body_name, "state": $state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEVICES - Update info
#
# PUT /api/v/2/devices/{systemKey}/{name}
# operationId: UpdateDeviceInfo
export def "update-device-info" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --custom-attribute: string # e.g. custom_setting
  --state: string # e.g. On
]: any -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/2/devices/{system_key}/{name}") $auth.query)
  let req_body = {"custom_attribute": $custom_attribute, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# EDGE - Fetch all edges
#
# GET /api/v/2/edges/{systemKey}
# operationId: GetAllEdges
export def "get-all-edges" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/edges/{system_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DATA - Get collections
#
# GET /api/v/3/allcollections/{systemKey}
# operationId: GetCollections
export def "get-collections" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<appID: string, collectionID: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/allcollections/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# CODE - Returns code services and settings
#
# GET /api/v/3/code/codemeta/{systemKey}
# operationId: ReturnServiceSettings
export def "return-service-settings" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record<code: table<auto_balance: bool, auto_balance_euid: string, auto_restart: bool, concurrency: int, euid: string, execution_timeout: int, logging_enabled: bool, name: string, namespace: string, system_key: string, uuid: string, version: int, version_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/code/codemeta/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/timer/{name}
# operationId: DeleteTimerByName
export def "delete-timer-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Get timer handler
#
# GET /api/v/3/code/{systemKey}/timer/{name}
# operationId: GetTimerByName
export def "get-timer-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Create timer handler
#
# POST /api/v/3/code/{systemKey}/timer/{name}
# operationId: CreateNewTimer
export def "create-new-timer" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}") $auth.query)
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Update timer handler
#
# PUT /api/v/3/code/{systemKey}/timer/{name}
# operationId: UpdateTimerByName
export def "update-timer-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}") $auth.query)
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Get timer handlers
#
# GET /api/v/3/code/{systemKey}/timers
# operationId: GetAllTimers
export def "get-all-timers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/code/{system_key}/timers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/trigger/{name}
# operationId: DeleteTriggerByName
export def "delete-trigger-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Get trigger handler
#
# GET /api/v/3/code/{systemKey}/trigger/{name}
# operationId: GetTriggerByName
export def "get-trigger-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Create trigger handler
#
# POST /api/v/3/code/{systemKey}/trigger/{name}
# operationId: CreateNewTrigger
# --key_value_pairs shape: {topic?: string}
export def "create-new-trigger" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}") $auth.query)
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Update trigger handler
#
# PUT /api/v/3/code/{systemKey}/trigger/{name}
# operationId: UpdateTriggerByName
# --key_value_pairs shape: {topic?: string}
export def "update-trigger-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}") $auth.query)
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# HANDLERS - Get trigger handlers
#
# GET /api/v/3/code/{systemKey}/triggers
# operationId: GetAllTrigger
export def "get-all-trigger" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/code/{system_key}/triggers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATA - Delete collection
#
# DELETE /api/v/3/collectionmanagement
# operationId: DeleteCollection
export def "delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted.
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v/3/collectionmanagement" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DATA - Create collection
#
# POST /api/v/3/collectionmanagement
# operationId: CreateCollection
export def "create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
  app_id: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collection-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> record<appID: string, collectionID: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/3/collectionmanagement" $auth.query)
  let req_body = {"appID": $app_id, "collectionID": $collection_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key} | compact
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

# DATA - Update collection
#
# PUT /api/v/3/collectionmanagement
# operationId: UpdateCollection
# --addColumn shape: {id: string, name: string, type: string}
export def "update-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
  --add-column: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/3/collectionmanagement" $auth.query)
  let req_body = {"addColumn": $add_column, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key} | compact
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

# EDGE - Get device columns
#
# GET /api/v/3/devices/{systemKey}/columns
# operationId: GetDeviceTableSchema
export def "get-device-table-schema" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<ColumnName: string, ColumnType: string, PK: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/devices/{system_key}/columns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEVICES - Get count
#
# GET /api/v/3/devices/{systemKey}/count
# operationId: GetDeviceCount
export def "get-device-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/devices/{system_key}/count") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# EDGE - Get columns
#
# GET /api/v/3/edges/{systemKey}/columns
# operationId: GetEdgeTableSchema
export def "get-edge-table-schema" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/edges/{system_key}/columns") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# EDGE - Get count
#
# GET /api/v/3/edges/{systemKey}/count
# operationId: GetEdgeCount
export def "get-edge-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/edges/{system_key}/count") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# Edge - Delete edge
#
# DELETE /api/v/3/edges/{systemKey}/{name}
# operationId: DeleteEdgeByName
export def "delete-edge-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# Edge(name) - Get edge info
#
# GET /api/v/3/edges/{systemKey}/{name}
# operationId: GetEdgeDataByName
export def "get-edge-data-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# EDGE - Create edge
#
# POST /api/v/3/edges/{systemKey}/{name}
# operationId: CreateNewEdge
export def "create-new-edge" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}") $auth.query)
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# EDGE - Update edge
#
# PUT /api/v/3/edges/{systemKey}/{name}
# operationId: UpdateEdgeByName
export def "update-edge-by-name" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}") $auth.query)
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEPLOYMENTS - Gets all deployment names and descriptions for a system
#
# GET /api/v/3/{systemKey}/deployments
# operationId: GetAllDeployments
export def "get-all-deployments" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter deployments by. See the query model above for an example.
  --clear-blade-user-token: string # User Token obtained through user authentication.
]: nothing -> table<description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/{system_key}/deployments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEPLOYMENTS - Creates a deployment
#
# POST /api/v/3/{systemKey}/deployments
# operationId: CreateDeployment
# --assets item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
export def "create-deployment" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication.
  --assets: list # item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
  --edges: list # Names of edges to be included in the deployment (e.g. [edge1, edge2, edge3])
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/{system_key}/deployments") $auth.query)
  let req_body = {"assets": $assets, "edges": $edges, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEPLOYMENT - Delete a deployment
#
# DELETE /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: DeleteDeployment
export def "delete-deployment" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/3/{system_key}/deployments/{deployment_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEPLOYMENTS - Gets a deloyment for a system
#
# GET /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: GetADeployment
export def "get-a-deployment" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clearblade-usertoken: string # User Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/3/{system_key}/deployments/{deployment_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"clearblade-usertoken": $clearblade_usertoken} | compact
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

# DEPLOYMENT - Update deployment
#
# PUT /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: UpdateDeployment
# --assets shape: {add?: list, remove?: list}
# --edges shape: {adds?: list<string>, removes?: list<string>}
export def "update-deployment" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication.
  assets: record # Assets to be added and removed from deployment — shape: {add?: list, remove?: list}
  edges: record # Edges to be added and removed from deployment — shape: {adds?: list<string>, removes?: list<string>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/3/{system_key}/deployments/{deployment_name}") $auth.query)
  let req_body = {"assets": $assets, "edges": $edges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# FILES - Returns a list of metadata for buckets in system
#
# GET /api/v/4/bucket_sets/{systemKey}
# operationId: GetBucketsData
export def "get-buckets-data" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/bucket_sets/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# FILES - Returns metadata for specified bucket
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}
# operationId: GetSingleBucketData
export def "get-single-bucket-data" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# FILES - Copies a file to a new location within buckets
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/copy
# operationId: CopyBucketFile
export def "copy-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/copy") $auth.query)
  let req_body = {"from_box": $from_box, "from_path": $from_path, "to_box": $to_box, "to_path": $to_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# FILES - Creates a new file in a bucket
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/create
# operationId: CreateBucketFile
export def "create-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --box: string # Box Name (e.g. inbox)
  --contents: string # base64 encoded file contents (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  --path: string # Relative File Path (e.g. /relative/file/path)
]: any -> record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/create") $auth.query)
  let req_body = {"box": $box, "contents": $contents, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# FILES - Deletes a file from the bucket.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/delete
# operationId: DeleteBucketFile
export def "delete-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --box: string # Box Name of file being deleted (e.g. inbox)
  --path: string # Relative File Path Name of file being deleted (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/delete") $auth.query)
  let req_body = {"box": $box, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# FILES - Get a file's metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/meta
# operationId: GetBoxFilesMeta
export def "get-box-files-meta" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # one of inbox, outbox or sandbox, defaults to 'inbox' if empty.
  --path: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "box" $box "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/meta") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"box": $box, "path": $path} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# FILES - Moves a file to a new location within buckets.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/move
# operationId: MoveBucketFile
export def "move-bucket-file" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/move") $auth.query)
  let req_body = {"from_box": $from_box, "from_path": $from_path, "to_box": $to_box, "to_path": $to_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# FILES - Get all files metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/files
# operationId: GetBoxFiles
export def "get-box-files" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<example_full_path_to_file_txt: record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "box" $box "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/files") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"box": $box} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DATA - Delete collection
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/index
# operationId: DeleteNonUniqueIndex
export def "delete-non-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/index") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"columnName": $column_name} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DATA - Create collection
#
# POST /api/v/4/data/{systemKey}/{collectionName}/index
# operationId: CreateNonUniqueIndex
export def "create-non-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/index") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"columnName": $column_name} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# DATA - Get list of indexes
#
# GET /api/v/4/data/{systemKey}/{collectionName}/listindexes
# operationId: GetIndexes
export def "get-indexes" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record<Data: table<name: string, type: string>, Total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/listindexes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DATA - Delete unique index
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# operationId: DeleteUniqueIndex
export def "delete-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/uniqueindex") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"columnName": $column_name} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# DATA - Create Unique Index
#
# POST /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# operationId: CreateUniqueIndex
export def "create-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/uniqueindex") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"columnName": $column_name} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# DATA - Update upsert values
#
# PUT /api/v/4/data/{systemKey}/{collectionName}/upsert
# operationId: UpdateUpsert
export def "update-upsert" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflict-column: string # A column in your table that has a unique constraint. `columnName` can be used.
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'collectionName' must be non-empty" } }
  let qp = [(serialize-qp "conflictColumn" $conflict_column "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/upsert") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"conflictColumn": $conflict_column} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# DEVICES - Get total of connected devices
#
# GET /api/v/4/devices/{systemKey}/connectioncount
# operationId: ConnectedDeviceCount
export def "connected-device-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<total_device_connections: int, total_devices: int, unique_device_connections: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/devices/{system_key}/connectioncount") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEVICES - Get connected device list
#
# GET /api/v/4/devices/{systemKey}/connections
# operationId: GetConnectedDeviceList
export def "get-connected-device-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Dev Token obtained through authentication.
]: nothing -> record<device_name: table<client_id: string, time_connected: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/devices/{system_key}/connections") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DEVICES - Get information for a connected device
#
# GET /api/v/4/devices/{systemKey}/connections/{name}
# operationId: GetConnectedDeviceInfo
export def "get-connected-device-info" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, connections: table<client_id: string, time_connected: string>, created_date: int, description: string, device_key: string, enabled: bool, has_keys: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/devices/{system_key}/connections/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATABASES - Retrieves all external database connections
#
# GET /api/v/4/external-db/{systemKey}
# operationId: GetAllExternalDB
export def "get-all-external-db" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> table<dbtype: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/external-db/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}
# operationId: CreateExternalDB
# --credentials shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
export def "create-external-db" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  --credentials: any # shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
  --dbtype: string # e.g. mysql
  --name: string # e.g. mysql_example
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/external-db/{system_key}") $auth.query)
  let req_body = {"credentials": $credentials, "dbtype": $dbtype, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DATABASES - Delete a external database connection
#
# DELETE /api/v/4/external-db/{systemKey}/{name}
# operationId: DeleteExternalDB
export def "delete-external-db" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATABASES - Retrieve a specific external database connection
#
# GET /api/v/4/external-db/{systemKey}/{name}
# operationId: GetExternalDB
export def "get-external-db" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
]: nothing -> record<credentials: record<address: string, dbname: string, password: string, port: string, user: string>, dbtype: string, id: int, name: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATABASES - Update external database credentials
#
# PUT /api/v/4/external-db/{systemKey}/{name}
# operationId: UpdateDatabaseCredentials
export def "update-database-credentials" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
  --address: string # e.g. MYSQL_ADDRESS
  --dbname: string # e.g. MYSQL_DATABASE_NAME
  --password: string # e.g. MSQL_PASSWORD
  --port: string # e.g. 3306
  --user: string # e.g. MYSQL_USER
]: any -> record<address: string, dbname: string, password: string, port: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}") $auth.query)
  let req_body = {"address": $address, "dbname": $dbname, "password": $password, "port": $port, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}/{name}/data
# operationId: PerformDBOperation
export def "perform-db-operation" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
  --operation: any
]: any -> record<Data: list<any>, Total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}/data") $auth.query)
  let req_body = {"operation": $operation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# MESSAGING - Gets list of topics
#
# GET /api/v/4/message/{systemKey}/topics
# operationId: GetTopics
export def "get-topics" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model in the description for example.
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> table<ip: string, payload: string, payloadsize: int, pk: string, qos: int, time: int, topicid: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/message/{system_key}/topics") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# MESSAGING - Gets number of topics
#
# GET /api/v/4/message/{systemKey}/topics/count
# operationId: GetTopicCount
export def "get-topic-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/message/{system_key}/topics/count") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# USER - Users change roles and passwords for other users
#
# PUT /api/v/4/user/manage
# operationId: ChangeUserInfo
# --changes shape: {password?: string, roles?: any}
export def "change-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  changes: any # Changes roles and password — shape: {password?: string, roles?: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/4/user/manage" $auth.query)
  let req_body = {"changes": $changes, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# WEBHOOKS - Executes query string payload webhook
#
# GET /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: PayloadWebhookQuery
export def "payload-webhook-query" [
  system_key: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # User authentication and data pushed through webhook
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($webhook_name | is-empty) { error make --unspanned { msg: "path parameter 'webhookName' must be non-empty" } }
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), webhook_name: (encode-path-segment $webhook_name)} | format pattern "/api/v/4/webhook/execute/{system_key}/{webhook_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# WEBHOOKS - Executing a webhook
#
# POST /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: ExecuteWebhook
export def "execute-webhook" [
  system_key: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  data: string # e.g. Third party server data
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($webhook_name | is-empty) { error make --unspanned { msg: "path parameter 'webhookName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), webhook_name: (encode-path-segment $webhook_name)} | format pattern "/api/v/4/webhook/execute/{system_key}/{webhook_name}") $auth.query)
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
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

# ADAPTERS - Get all adapters
#
# GET /api/v/4/{SystemKey}/adapters
# operationId: GetAdapters
export def "get-adapters" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/{system_key}/adapters") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Add an adapter
#
# POST /api/v/4/{SystemKey}/adapters
# operationId: addAdapter
export def "add-adapter" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication..
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. )
  --logs-command: string # A command or shell script that will be used to retrieve any logs printed out by the adapter while it is running. (e.g. )
  name: string # Name of the adapter. (e.g. example-adapter)
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. )
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. )
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge. If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. )
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/{system_key}/adapters") $auth.query)
  let req_body = {"architecture": $architecture, "deploy_command": $deploy_command, "logs_command": $logs_command, "name": $name, "os": $os, "start_command": $start_command, "status_command": $status_command, "stop_command": $stop_command, "undeploy_command": $undeploy_command} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Delete adapter
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: DeleteAdapter
export def "delete-adapter" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Map Adapter command to execute a file
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: MapAdapterCommand
export def "map-adapter-command" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. ./deploy.sh)
  --logs-command: string # e.g. ./logs.sh
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --run-deploy-on-deploy: oneof<nothing, bool> # e.g. true
  --run-start-on-deploy: oneof<nothing, bool> # e.g. true
  --run-stop-on-deploy: oneof<nothing, bool> # e.g. true
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. ./start.sh)
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. ./status.sh)
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge. If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. ./stop.sh)
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. ./undeploy.sh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}") $auth.query)
  let req_body = {"architecture": $architecture, "deploy_command": $deploy_command, "logs_command": $logs_command, "os": $os, "run_deploy_on_deploy": $run_deploy_on_deploy, "run_start_on_deploy": $run_start_on_deploy, "run_stop_on_deploy": $run_stop_on_deploy, "start_command": $start_command, "status_command": $status_command, "stop_command": $stop_command, "undeploy_command": $undeploy_command} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Send command to edge
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/control
# operationId: AddEdgeCommand
export def "add-edge-command" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  command: string # The command the edge is currently using. (e.g. status)
  edges: string # Name of edge(s) being used. (e.g. [edgeName])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/control") $auth.query)
  let req_body = {"command": $command, "edges": $edges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# Gets list of configuration information for all adapter files
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: AdapterConfig
export def "adapter-config" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Add or replace file content & configuration
#
# POST /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: updateFileInfo
export def "update-file-info" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  --body-adapter-name: string # The adapter the file is a part of.
  --file: string # The base64 encoded file content. (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  name: string # The name of the file, spaces ` ` or `-` are not allowed
  --path-name: string # the file path where the adapter file is stored on the client side. For example, on the file system where edge is running. (e.g. start.sh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files") $auth.query)
  let req_body = {"adapter_name": $body_adapter_name, "file": $file, "name": $name, "path_name": $path_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Delete adapter files
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: DeleteFile
export def "delete-file" [
  system_key: string
  adapter_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'fileName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name), file_name: (encode-path-segment $file_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files/{file_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Download file from adapter
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: FileDownload
export def "file-download" [
  system_key: string
  adapter_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'fileName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name), file_name: (encode-path-segment $file_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files/{file_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# ADAPTERS - Update Existing File's content
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: updateExistingFileContent
export def "update-existing-file-content" [
  system_key: string
  adapter_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  file: string # base64 encoded string as file content to overwrite the existing content (e.g. IyEvYmluL2Jhc2gKZWNobyAiaGVsbG8gd29ybGQi)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'SystemKey' must be non-empty" } }
  if ($adapter_name | is-empty) { error make --unspanned { msg: "path parameter 'AdapterName' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'fileName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name), file_name: (encode-path-segment $file_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files/{file_name}") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# CODE - Get all failed services using Query
#
# GET /api/v/4/{systemKey}/code/failed
# operationId: GetFailedServiceQuery
export def "get-failed-service-query" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Uses query to limit scope of list of failed services. Check FailQuery Model at the bottom of this page.
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/{system_key}/code/failed") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get all failed services
#
# GET /codeadmin/failed
# operationId: GetFailedServices
export def "get-failed-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/codeadmin/failed" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete failed service run
#
# DELETE /codeadmin/failed/{systemKey}
# operationId: DeleteFailedService
export def "delete-failed-service" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/failed/{system_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# DEVELOPER - Get system's failed services
#
# GET /codeadmin/failed/{systemKey}
# operationId: GetSystemFailedServices
export def "get-system-failed-services" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/failed/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Retry failed service
#
# POST /codeadmin/failed/{systemKey}
# operationId: RetryFailedService
export def "retry-failed-service" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/failed/{system_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get library history
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}
# operationId: LibraryHistory
export def "library-history" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($lib_name | is-empty) { error make --unspanned { msg: "path parameter 'libName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/history/library/{system_key}/{lib_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get old library version
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}/{libVersion}
# operationId: GetOldLibraryVersion
export def "get-old-library-version" [
  system_key: string
  lib_name: string
  lib_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($lib_name | is-empty) { error make --unspanned { msg: "path parameter 'libName' must be non-empty" } }
  if ($lib_version | is-empty) { error make --unspanned { msg: "path parameter 'libVersion' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name), lib_version: (encode-path-segment $lib_version)} | format pattern "/codeadmin/v/2/history/library/{system_key}/{lib_name}/{lib_version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get all libraries
#
# GET /codeadmin/v/2/library/{systemKey}
# operationId: GetLibraries
export def "get-libraries" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/v/2/library/{system_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete library
#
# DELETE /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: DeleteLibrary
export def "delete-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($lib_name | is-empty) { error make --unspanned { msg: "path parameter 'libName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get library
#
# GET /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: GetLibrary
export def "get-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($lib_name | is-empty) { error make --unspanned { msg: "path parameter 'libName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Create library
#
# POST /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: CreateLibrary
export def "create-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  code: string # e.g. function getter(uri){var r=Requests();r.get({'uri':uri},function(err,resp){log(JSON.stringify(resp));});}
  dependencies: string # e.g. http,log
  visibility: string # e.g. system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($lib_name | is-empty) { error make --unspanned { msg: "path parameter 'libName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}") $auth.query)
  let req_body = {"code": $code, "dependencies": $dependencies, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update library
#
# PUT /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: UpdateLibrary
export def "update-library" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  code: string # e.g. function rand(){log('rolling die'); return 3;}
  dependencies: string # e.g. log
  description: string # e.g. Random number generator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($lib_name | is-empty) { error make --unspanned { msg: "path parameter 'libName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}") $auth.query)
  let req_body = {"code": $code, "dependencies": $dependencies, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Get services logs
#
# GET /codeadmin/v/2/logs/{systemKey}/{serviceName}
# operationId: GetLogs
export def "get-logs" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/logs/{system_key}/{service_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Delete code service
#
# DELETE /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: DeleteService
export def "delete-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/{system_key}/{service_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Add code service
#
# POST /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: AddService
export def "add-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  --dependencies: string # e.g. log
  name: string # e.g. serviceName
  parameters: string # e.g. [{}]
  --run-user: string # e.g. 
  system_id: string # e.g. c0f8e2c50bc6cc90b7a19abbbb8d01
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/{system_key}/{service_name}") $auth.query)
  let req_body = {"code": $code, "dependencies": $dependencies, "name": $name, "parameters": $parameters, "run_user": $run_user, "systemID": $system_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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

# DEVELOPER - Update code service
#
# PUT /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: UpdateService
export def "update-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --auto-balance: oneof<nothing, bool> # If concurrency > 0 then auto_balance can be set to true if needed
  --auto-restart: oneof<nothing, bool> # If execution_timeout = -1 => Stream Service then auto_restart can be set to true if needed
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  concurrency: int # e.g. 0
  current_version: int # e.g. 4
  --dependencies: string # e.g. log
  --execution-timeout: int # e.g. 60
  --logging-enabled: oneof<nothing, bool>
  name: string # e.g. serviceName
  --parameters: list # e.g. []
  --run-user: string # Uses user_id. (e.g. e8b7f0cb0bdccdb7a8a7c78cdfcb01)
  --timers: list # e.g. []
  --triggers: list # e.g. []
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($system_key | is-empty) { error make --unspanned { msg: "path parameter 'systemKey' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/{system_key}/{service_name}") $auth.query)
  let req_body = {"auto_balance": $auto_balance, "auto_restart": $auto_restart, "code": $code, "concurrency": $concurrency, "current_version": $current_version, "dependencies": $dependencies, "execution_timeout": $execution_timeout, "logging_enabled": $logging_enabled, "name": $name, "parameters": $parameters, "run_user": $run_user, "timers": $timers, "triggers": $triggers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
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
