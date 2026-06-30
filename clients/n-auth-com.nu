# Auto-generated client for nextAuth API v2.2
# Source: https://api.apis.guru/v2/specs/n-auth.com/2.2/swagger.json
# Auth: --token flag or $env.NEXTAUTH_API_TOKEN

const BASE_URL = "https://api.nextauth.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NEXTAUTH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-apikey" => { {scheme: $scheme, headers: {X-apikey: $token_val}, query: "", location: "header"} }
    "x-su" => { {scheme: $scheme, headers: {X-su: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.nextauth.com"] }
def auth-scheme-completer [] { ["x-apikey" "x-su"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apikeys get-keys" } } | get name | first)
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

# Get all API keys.
#
# GET /apikeys/
# operationId: getApiKeys
export def "apikeys get-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apikeys: table<apikey: string, description: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apikeys/" $auth.query)
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

# Create a new API key.
#
# POST /apikeys/
# operationId: createApiKey
export def "apikeys create-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description for the new role
]: nothing -> record<apikey: string, description: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apikeys/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"description": $description} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Delete all global attributes
#
# DELETE /attributes/
# operationId: deleteGlobalAttributes
export def "attributes delete-global" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/" $auth.query)
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

# Get all global attributes
#
# GET /attributes/
# operationId: getGlobalAttributes
export def "attributes get-global" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/" $auth.query)
  let accept_val = "text/plain"
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

# Set all global attributes
#
# POST /attributes/
# operationId: setGlobalAttributes
export def "attributes update-global" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/" $auth.query)
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

# Update specified global attributes
#
# PUT /attributes/
# operationId: updateGlobalAttributes
export def "attributes update-global-1" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes/" $auth.query)
  let req_body = $body
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

# Delete specific global attribute
#
# DELETE /attributes/{attributekey}
# operationId: deleteGlobalAttribute
export def "attributes delete-global-by-attributekey" [
  attributekey: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($attributekey | is-empty) { error make --unspanned { msg: "path parameter 'attributekey' must be non-empty" } }
  let full_url = (build-url $base ({attributekey: (encode-path-segment $attributekey)} | format pattern "/attributes/{attributekey}") $auth.query)
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

# List all your servers
#
# GET /servers/
# operationId: getServers
export def "servers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
]: nothing -> record<servers: table<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string>, totalnumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/servers/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "marker": $marker} | compact)
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
# POST /servers/
# operationId: createServer
export def "servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-count: int # Number of accounts registered with this server
  --appandroid: string # URL of the app in Google Play
  --appios: string # URL of the app in the App Store
  --appname: string # name of the app
  --appurl: string # URL (prefix) to launch the app
  --last-login: int # Last login on this server (format: int64)
  logo: string # Base 64 encoded logo
  --owner: int # Owner id
  pin_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at login. -1 means that the user is never asked for a PIN before logging in, 0 means that the user is asked every time he wants to login
  pin_trans_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at transaction approval. -1 means that the user is never asked for a PIN before approving a transaction, 0 means that the user is asked every time he wants to approve a transaction
  ping_time: int # Time (seconds) that the nextAuth app has before it needs to reply to a ping request from the nextAuth server (continuous authentication)
  server_flags: list<string> # Server flags
  server_name: string # Server name
  serverid: string # Base64 encoded id of the nextAuth server
  serverpk: string # Base64 encoded public key of the nextAuth server
  --siteurl: string # URL of the main website
  --wsurl: string # Websocket URL
]: any -> record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servers/" $auth.query)
  let req_body = {"accountCount": $account_count, "appandroid": $appandroid, "appios": $appios, "appname": $appname, "appurl": $appurl, "lastLogin": $last_login, "logo": $logo, "owner": $owner, "pinTimeout": $pin_timeout, "pinTransTimeout": $pin_trans_timeout, "pingTime": $ping_time, "serverFlags": $server_flags, "serverName": $server_name, "serverid": $serverid, "serverpk": $serverpk, "siteurl": $siteurl, "wsurl": $wsurl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/octet-stream"
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

# Configuration of a specific server
#
# GET /servers/{serverid}/
# operationId: getServer
export def "servers get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/") $auth.query)
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

# Update configuration of a specific server
#
# PUT /servers/{serverid}/
# operationId: updateServer
export def "servers update" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-count: int # Number of accounts registered with this server
  --appandroid: string # URL of the app in Google Play
  --appios: string # URL of the app in the App Store
  --appname: string # name of the app
  --appurl: string # URL (prefix) to launch the app
  --last-login: int # Last login on this server (format: int64)
  logo: string # Base 64 encoded logo
  --owner: int # Owner id
  pin_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at login. -1 means that the user is never asked for a PIN before logging in, 0 means that the user is asked every time he wants to login
  pin_trans_timeout: int # Time (minutes) since the last time the user entered his PIN, that the user is not requested a PIN at transaction approval. -1 means that the user is never asked for a PIN before approving a transaction, 0 means that the user is asked every time he wants to approve a transaction
  ping_time: int # Time (seconds) that the nextAuth app has before it needs to reply to a ping request from the nextAuth server (continuous authentication)
  server_flags: list<string> # Server flags
  server_name: string # Server name
  --body-serverid: string # Base64 encoded id of the nextAuth server
  serverpk: string # Base64 encoded public key of the nextAuth server
  --siteurl: string # URL of the main website
  --wsurl: string # Websocket URL
]: any -> record<accountCount: int, appandroid: string, appios: string, appname: string, appurl: string, lastLogin: int, logo: string, owner: int, pinTimeout: int, pinTransTimeout: int, pingTime: int, serverFlags: list<string>, serverName: string, serverid: string, serverpk: string, siteurl: string, wsurl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/") $auth.query)
  let req_body = {"accountCount": $account_count, "appandroid": $appandroid, "appios": $appios, "appname": $appname, "appurl": $appurl, "lastLogin": $last_login, "logo": $logo, "owner": $owner, "pinTimeout": $pin_timeout, "pinTransTimeout": $pin_trans_timeout, "pingTime": $ping_time, "serverFlags": $server_flags, "serverName": $server_name, "serverid": $body_serverid, "serverpk": $serverpk, "siteurl": $siteurl, "wsurl": $wsurl} | compact
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

# Get all accounts
#
# GET /servers/{serverid}/accounts/
# operationId: getAllAccounts
export def "servers-accounts get-list" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter users based on an attribute. Takes the format *attributename=attributevalue*. You can filter for multiple values at once, e.g. *group=in:group1,group2*
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --qp-sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/accounts/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter, "limit": $limit, "marker": $marker, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete specific account
#
# DELETE /servers/{serverid}/accounts/{accountid}/
# operationId: deleteAccount
export def "servers-accounts delete" [
  serverid: string
  accountid: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), accountid: (encode-path-segment $accountid)} | format pattern "/servers/{serverid}/accounts/{accountid}/") $auth.query)
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

# Get specific account
#
# GET /servers/{serverid}/accounts/{accountid}/
# operationId: getAccount
export def "servers-accounts get" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), accountid: (encode-path-segment $accountid)} | format pattern "/servers/{serverid}/accounts/{accountid}/") $auth.query)
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

# Update specific account
#
# PUT /servers/{serverid}/accounts/{accountid}/
# operationId: updateAccount
export def "servers-accounts update" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocked: oneof<nothing, bool> # True if the account is blocked
]: nothing -> record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let qp = [(serialize-qp "blocked" $blocked "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), accountid: (encode-path-segment $accountid)} | format pattern "/servers/{serverid}/accounts/{accountid}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"blocked": $blocked} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/accounts/{accountid}/provokelogin
# operationId: provokeLoginOnAccount
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-accounts-provokelogin create-provoke-login" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Base64 encoded nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), accountid: (encode-path-segment $accountid)} | format pattern "/servers/{serverid}/accounts/{accountid}/provokelogin") $auth.query)
  let req_body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Update user of the given account.
#
# PUT /servers/{serverid}/accounts/{accountid}/user
# operationId: updateAccountUser
export def "servers-accounts-user update" [
  serverid: string
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --userid: string # User name
]: nothing -> record<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let qp = [(serialize-qp "userid" $userid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), accountid: (encode-path-segment $accountid)} | format pattern "/servers/{serverid}/accounts/{accountid}/user") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"userid": $userid} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Delete all attributes of a specific server
#
# DELETE /servers/{serverid}/attributes/
# operationId: deleteServerAttributes
export def "servers-attributes delete-by-serverid" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/attributes/") $auth.query)
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

# Get all attributes of a specific server
#
# GET /servers/{serverid}/attributes/
# operationId: getServerAttributes
export def "servers-attributes get" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/attributes/") $auth.query)
  let accept_val = "text/plain"
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

# Set all attributes of a specific server
#
# POST /servers/{serverid}/attributes/
# operationId: setServerAttributes
export def "servers-attributes update-by-serverid" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/attributes/") $auth.query)
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

# Update specified attributes of a specific server
#
# PUT /servers/{serverid}/attributes/
# operationId: updateServerAttributes
export def "servers-attributes update-by-serverid-1" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/attributes/") $auth.query)
  let req_body = $body
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

# Delete specific attribute of a specific server
#
# DELETE /servers/{serverid}/attributes/{attributekey}
# operationId: deleteServerAttribute
export def "servers-attributes delete-by-serverid-attributekey" [
  serverid: string
  attributekey: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($attributekey | is-empty) { error make --unspanned { msg: "path parameter 'attributekey' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), attributekey: (encode-path-segment $attributekey)} | format pattern "/servers/{serverid}/attributes/{attributekey}") $auth.query)
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

# Get all permissions for the specified server.
#
# GET /servers/{serverid}/permissions/
# operationId: getAllPermissions
export def "servers-permissions get-list" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: table<acl: string, role: string, server: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/permissions/") $auth.query)
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

# Revoke all permissions for the specified server and role.
#
# DELETE /servers/{serverid}/permissions/{roleid}
# operationId: revokePermissions
export def "servers-permissions delete" [
  serverid: string
  roleid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($roleid | is-empty) { error make --unspanned { msg: "path parameter 'roleid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), roleid: (encode-path-segment $roleid)} | format pattern "/servers/{serverid}/permissions/{roleid}") $auth.query)
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

# Get all permissions for the specified server and role.
#
# GET /servers/{serverid}/permissions/{roleid}
# operationId: getPermissions
export def "servers-permissions get" [
  serverid: string
  roleid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: table<acl: string, role: string, server: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($roleid | is-empty) { error make --unspanned { msg: "path parameter 'roleid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), roleid: (encode-path-segment $roleid)} | format pattern "/servers/{serverid}/permissions/{roleid}") $auth.query)
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

# Set new permissions for the specified role on a server
#
# POST /servers/{serverid}/permissions/{roleid}
# operationId: grantPermissions
export def "servers-permissions create-grant" [
  serverid: string
  roleid: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($roleid | is-empty) { error make --unspanned { msg: "path parameter 'roleid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), roleid: (encode-path-segment $roleid)} | format pattern "/servers/{serverid}/permissions/{roleid}") $auth.query)
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

# Delete all privileged attributes of a specific server
#
# DELETE /servers/{serverid}/privilegedattributes/
# operationId: deleteServerPrivilegedAttributes
export def "servers-privilegedattributes delete-privileged-attributes" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/privilegedattributes/") $auth.query)
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

# Get all privileged attributes of a specific server
#
# GET /servers/{serverid}/privilegedattributes/
# operationId: getServerPrivilegedAttributes
export def "servers-privilegedattributes get-privileged-attributes" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/privilegedattributes/") $auth.query)
  let accept_val = "text/plain"
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

# Set all privileged attributes of a specific server
#
# POST /servers/{serverid}/privilegedattributes/
# operationId: setServerPrivilegedAttributes
export def "servers-privilegedattributes update-privileged-attributes-by-serverid" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/privilegedattributes/") $auth.query)
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

# Update privileged specified attributes of a specific server
#
# PUT /servers/{serverid}/privilegedattributes/
# operationId: updateServerPrivilegedAttributes
export def "servers-privilegedattributes update-privileged-attributes-by-serverid-1" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/privilegedattributes/") $auth.query)
  let req_body = $body
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

# Delete specific privileged attribute of a specific server
#
# DELETE /servers/{serverid}/privilegedattributes/{attributekey}
# operationId: deleteServerPrivilegedAttribute
export def "servers-privilegedattributes delete-privileged-attribute" [
  serverid: string
  attributekey: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($attributekey | is-empty) { error make --unspanned { msg: "path parameter 'attributekey' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), attributekey: (encode-path-segment $attributekey)} | format pattern "/servers/{serverid}/privilegedattributes/{attributekey}") $auth.query)
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

# Check if the user is logged in
#
# GET /servers/{serverid}/sessions/
# operationId: getSession
export def "servers-sessions get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> record<accountid: int, canprovoke: bool, hsid: string, loggedin: bool, loginqrdata: string, pk: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Generate HTML to enrol a new user
#
# GET /servers/{serverid}/sessions/html/enrol
# operationId: getHtmlEnrol
export def "servers-sessions-html-enrol get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to forward to the nextAuth app for this account
  --userid: string # User name to register this user under
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "userid" $userid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/html/enrol") $qp $auth.query)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "userid": $userid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generic HTML to add to footer. Required for login/logout/enrol functionality.
#
# GET /servers/{serverid}/sessions/html/footer
# operationId: getHtmlFooter
# --sessions item shape: {serverid: string, sessionid: string}
export def "servers-sessions-html-footer get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/html/footer") $auth.query)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Generate HTML for the login block
#
# GET /servers/{serverid}/sessions/html/login
# operationId: getHtmlLogin
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-sessions-html-login get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/html/login") $auth.query)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Force a logout on the given session
#
# POST /servers/{serverid}/sessions/logout
# operationId: logout
export def "servers-sessions-logout create" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/logout") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/sessions/provokelogin
# operationId: provokeLogin
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-sessions-provokelogin create-provoke-login" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/provokelogin") $auth.query)
  let req_body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Generate data for an enrol qr code
#
# GET /servers/{serverid}/sessions/qr/enrol
# operationId: getQrEnrol
export def "servers-sessions-qr-enrol get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name to forward to the nextAuth app for this account
  --userid: string # User name to register this user under
  --img: string # 'png' for a PNG image, not set for raw data in the qr code
  --s: int # size in pixels of the qr code, defaults to 500
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "userid" $userid "scalar") (serialize-qp "img" $img "scalar") (serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/qr/enrol") $qp $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "userid": $userid, "img": $img, "s": $s} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generate data for a login qr code
#
# GET /servers/{serverid}/sessions/qr/login
# operationId: getQrLogin
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-sessions-qr-login get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --img: string # "png" for a PNG image, not set for raw data in the qr code
  --s: int # size in pixels of the qr code, defaults to 500
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let qp = [(serialize-qp "img" $img "scalar") (serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/qr/login") $qp $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"img": $img, "s": $s} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Register a userid for the currently logged in account.
#
# POST /servers/{serverid}/sessions/registeruser
# operationId: registerUser
export def "servers-sessions-registeruser create-user" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --userid: string # Username to register
  --x-nonce: string # Nonce to identify the browser/webserver session
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let qp = [(serialize-qp "userid" $userid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/registeruser") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"userid": $userid} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Create a transaction to be approved within the current session.
#
# POST /servers/{serverid}/sessions/transactions
# operationId: createTransaction
export def "servers-sessions-transactions create" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --amount: string
  --benificiary: string
  --description: string
]: any -> record<tid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/sessions/transactions") $auth.query)
  let req_body = {"amount": $amount, "benificiary": $benificiary, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Get transaction result for a given transaction.
#
# GET /servers/{serverid}/transactions/{transactionid}
# operationId: getTransactionResult
export def "servers-transactions get-result" [
  serverid: string
  transactionid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tstatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($transactionid | is-empty) { error make --unspanned { msg: "path parameter 'transactionid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), transactionid: (encode-path-segment $transactionid)} | format pattern "/servers/{serverid}/transactions/{transactionid}") $auth.query)
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

# Get all users
#
# GET /servers/{serverid}/users/
# operationId: getUsers
export def "servers-users get" [
  serverid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter users based on an attribute. Takes the format *attributename=attributevalue*. You can filter for multiple values at once, e.g. *group=in:group1,group2*
  --search: string # Search for a username LIKE %search%
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --qp-sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> record<totalnumber: int, users: table<lastlogin: int, numberaccounts: int, userid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/users/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter, "search": $search, "limit": $limit, "marker": $marker, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a specific user
#
# DELETE /servers/{serverid}/users/{userid}/
# operationId: deleteUser
export def "servers-users delete" [
  serverid: string
  userid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/") $auth.query)
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

# Delete all accounts of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/accounts
# operationId: deleteUserAccounts
export def "servers-users-accounts delete" [
  serverid: string
  userid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/accounts") $auth.query)
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

# Get all accounts of a specific user
#
# GET /servers/{serverid}/users/{userid}/accounts
# operationId: getUser
export def "servers-users-accounts get" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of results
  --marker: int # Offset in the result list
  --qp-sort: string # Sort the results by column. You can also specify ascending (default if not specified) or descending, e.g., *column:asc* . You can also sort by multiple columns, e.g., *column1:desc,column2:asc*
]: nothing -> record<accounts: table<blocked: bool, clientVersion: string, created: int, description: string, id: int, lastlogin: int, lastprovoke: int, userid: string>, totalnumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/accounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "marker": $marker, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete all attributes of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/attributes/
# operationId: deleteUserAttributes
export def "servers-users-attributes delete-by-serverid-userid" [
  serverid: string
  userid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/attributes/") $auth.query)
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

# Get all attributes of a specific user
#
# GET /servers/{serverid}/users/{userid}/attributes/
# operationId: getUserAttributes
export def "servers-users-attributes get" [
  serverid: string
  userid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/attributes/") $auth.query)
  let accept_val = "text/plain"
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

# Set all attributes of a specific user
#
# POST /servers/{serverid}/users/{userid}/attributes/
# operationId: setUserAttributes
export def "servers-users-attributes update-by-serverid-userid" [
  serverid: string
  userid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/attributes/") $auth.query)
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

# Update specified attributes of a specific user
#
# PUT /servers/{serverid}/users/{userid}/attributes/
# operationId: updateUserAttributes
export def "servers-users-attributes update-by-serverid-userid-1" [
  serverid: string
  userid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/attributes/") $auth.query)
  let req_body = $body
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

# Delete specific attribute of a specific user
#
# DELETE /servers/{serverid}/users/{userid}/attributes/{attributekey}
# operationId: deleteUserAttribute
export def "servers-users-attributes delete-by-serverid-userid-attributekey" [
  serverid: string
  userid: string
  attributekey: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  if ($attributekey | is-empty) { error make --unspanned { msg: "path parameter 'attributekey' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid), attributekey: (encode-path-segment $attributekey)} | format pattern "/servers/{serverid}/users/{userid}/attributes/{attributekey}") $auth.query)
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

# Push a login confirmation to the user's app
#
# POST /servers/{serverid}/users/{userid}/provokelogin
# operationId: provokeLoginOnUser
# --announceinfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
# --sessioninfo shape: {info?: record, ip?: string, logo?: string, useragent?: string}
export def "servers-users-provokelogin create-provoke-login" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-nonce: string # Nonce to identify the browser/webserver session
  --announceinfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
  --sessioninfo: any # shape: {info?: record, ip?: string, logo?: string, useragent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/provokelogin") $auth.query)
  let req_body = {"announceinfo": $announceinfo, "sessioninfo": $sessioninfo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-nonce": $x_nonce} | compact
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

# Get role for a specific user.
#
# GET /servers/{serverid}/users/{userid}/role/
# operationId: getUserRole
export def "servers-users-role get" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/role/") $auth.query)
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

# Get or create a role for a specific user.
#
# POST /servers/{serverid}/users/{userid}/role/
# operationId: getOrCreateUserRole
export def "servers-users-role get-or-create" [
  serverid: string
  userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid), userid: (encode-path-segment $userid)} | format pattern "/servers/{serverid}/users/{userid}/role/") $auth.query)
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

# Visual hash of this server
#
# GET /servers/{serverid}/vash
# operationId: getServerVash
export def "servers-vash get" [
  serverid: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($serverid | is-empty) { error make --unspanned { msg: "path parameter 'serverid' must be non-empty" } }
  let full_url = (build-url $base ({serverid: (encode-path-segment $serverid)} | format pattern "/servers/{serverid}/vash") $auth.query)
  let accept_val = "application/octet-stream"
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
