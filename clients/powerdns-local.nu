# Auto-generated client for PowerDNS Authoritative HTTP API v0.0.13
# Source: https://api.apis.guru/v2/specs/powerdns.local/0.0.13/swagger.json
# Auth: --token flag or $env.POWERDNS_AUTHORITATIVE_HTTP_API_TOKEN

const BASE_URL = "https://localhost/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POWERDNS_AUTHORITATIVE_HTTP_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://localhost/api/v1"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def kind-completer [] { ["Master" "Native" "Slave"] }
def keytype-completer [] { ["csk" "ksk" "zsk"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "servers list" } } | get name | first)
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

# List all servers
#
# GET /servers
# operationId: listServers
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
]: nothing -> table<config_url: string, daemon_type: string, id: string, type: string, url: string, version: string, zones_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/servers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List a server
#
# GET /servers/{server_id}
# operationId: listServer
export def "servers list-1" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config_url: string, daemon_type: string, id: string, type: string, url: string, version: string, zones_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Flush a cache-entry by name
#
# PUT /servers/{server_id}/cache/flush
# operationId: cacheFlushByName
export def "servers-cache-flush update-by-name" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The domain name to flush from the cache
]: nothing -> record<count: float, result: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/cache/flush") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"domain": $domain} | compact), body: null}
}

# Returns all ConfigSettings for a single server
#
# GET /servers/{server_id}/config
# operationId: getConfig
export def "servers-config list" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a specific ConfigSetting for a single server
#
# GET /servers/{server_id}/config/{config_setting_name}
# operationId: getConfigSetting
export def "servers-config get" [
  server_id: string
  config_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($config_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'config_setting_name' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), config_setting_name: (encode-path-segment $config_setting_name)} | format pattern "/servers/{server_id}/config/{config_setting_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search the data inside PowerDNS
#
# GET /servers/{server_id}/search-data
# operationId: searchData
export def "servers-search-data list" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The string to search for
  --max: int # Maximum number of entries to return
  --object-type: string # Type of data to search for, one of “all”, “zone”, “record”, “comment”
]: nothing -> table<content: string, disabled: bool, name: string, object_type: string, ttl: int, type: string, zone: string, zone_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "object_type" $object_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/search-data") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "max": $max, "object_type": $object_type} | compact), body: null}
}

# Query statistics.
#
# GET /servers/{server_id}/statistics
# operationId: getStats
export def "servers-statistics get-stats" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --statistic: string # When set to the name of a specific statistic, only this value is returned. If no statistic with that name exists, the response has a 422 status and an error message.
  --includerings: oneof<nothing, bool> # “true” (default) or “false”, whether to include the Ring items, which can contain thousands of log messages or queried domains. Setting this to ”false” may make the response a lot smaller. (default: true)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let qp = [(serialize-qp "statistic" $statistic "scalar") (serialize-qp "includerings" $includerings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"statistic": $statistic, "includerings": $includerings} | compact), body: null}
}

# Get all TSIGKeys on the server, except the actual key
#
# GET /servers/{server_id}/tsigkeys
# operationId: listTSIGKeys
export def "servers-tsigkeys list-tsig-keys" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<algorithm: string, id: string, key: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/tsigkeys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a TSIG key
#
# POST /servers/{server_id}/tsigkeys
# operationId: createTSIGKey
export def "servers-tsigkeys create-tsig-key" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # The algorithm of the TSIG key
  --key: string # The Base64 encoded secret key, empty when listing keys. MAY be empty when POSTing to have the server generate the key material
  --name: string # The name of the key
]: any -> record<algorithm: string, id: string, key: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/tsigkeys"))
  let req_body = {"algorithm": $algorithm, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the TSIGKey with tsigkey_id
#
# DELETE /servers/{server_id}/tsigkeys/{tsigkey_id}
# operationId: deleteTSIGKey
export def "servers-tsigkeys delete-tsig-key" [
  server_id: string
  tsigkey_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($tsigkey_id | is-empty) { error make --unspanned { msg: "path parameter 'tsigkey_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), tsigkey_id: (encode-path-segment $tsigkey_id)} | format pattern "/servers/{server_id}/tsigkeys/{tsigkey_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific TSIGKeys on the server, including the actual key
#
# GET /servers/{server_id}/tsigkeys/{tsigkey_id}
# operationId: getTSIGKey
export def "servers-tsigkeys get-tsig-key" [
  server_id: string
  tsigkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algorithm: string, id: string, key: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($tsigkey_id | is-empty) { error make --unspanned { msg: "path parameter 'tsigkey_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), tsigkey_id: (encode-path-segment $tsigkey_id)} | format pattern "/servers/{server_id}/tsigkeys/{tsigkey_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# The TSIGKey at tsigkey_id can be changed in multiple ways: * Changing the Name, this will remove the key with tsigkey_id after adding. * Changing the Algorithm * Changing the Key Only the relevant fields have to be provided in the request body.
#
# PUT /servers/{server_id}/tsigkeys/{tsigkey_id}
# operationId: putTSIGKey
export def "servers-tsigkeys update-tsig-key" [
  server_id: string
  tsigkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string # The algorithm of the TSIG key
  --key: string # The Base64 encoded secret key, empty when listing keys. MAY be empty when POSTing to have the server generate the key material
  --name: string # The name of the key
]: any -> record<algorithm: string, id: string, key: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($tsigkey_id | is-empty) { error make --unspanned { msg: "path parameter 'tsigkey_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), tsigkey_id: (encode-path-segment $tsigkey_id)} | format pattern "/servers/{server_id}/tsigkeys/{tsigkey_id}"))
  let req_body = {"algorithm": $algorithm, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all Zones in a server
#
# GET /servers/{server_id}/zones
# operationId: listZones
export def "servers-zones list" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zone: string # When set to the name of a zone, only this zone is returned. If no zone with that name exists, the response is an empty array. This can e.g. be used to check if a zone exists in the database without having to guess/encode the zone's id or to check if a zone exists.
  --dnssec: oneof<nothing, bool> # “true” (default) or “false”, whether to include the “dnssec” and ”edited_serial” fields in the Zone objects. Setting this to ”false” will make the query a lot faster. (default: true)
]: nothing -> table<account: string, api_rectify: bool, dnssec: bool, edited_serial: int, id: string, kind: string, master_tsig_key_ids: list<string>, masters: list<string>, name: string, nameservers: list<string>, notified_serial: int, nsec3narrow: bool, nsec3param: string, presigned: bool, rrsets: list<record>, serial: int, slave_tsig_key_ids: list<string>, soa_edit: string, soa_edit_api: string, type: string, url: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let qp = [(serialize-qp "zone" $zone "scalar") (serialize-qp "dnssec" $dnssec "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/zones") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"zone": $zone, "dnssec": $dnssec} | compact), body: null}
}

# Creates a new domain, returns the Zone on creation.
#
# POST /servers/{server_id}/zones
# operationId: createZone
# --rrsets item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
export def "servers-zones create" [
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rrsets: oneof<nothing, bool> # “true” (default) or “false”, whether to include the “rrsets” in the response Zone object. (default: true) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --account: string # MAY be set. Its value is defined by local policy
  --api-rectify: oneof<nothing, bool> # Whether or not the zone will be rectified on data changes via the API
  --dnssec: oneof<nothing, bool> # Whether or not this zone is DNSSEC signed (inferred from presigned being true XOR presence of at least one cryptokey with active being true)
  --edited-serial: int # The SOA serial as seen in query responses. Calculated using the SOA-EDIT metadata, default-soa-edit and default-soa-edit-signed settings
  --id: string # Opaque zone id (string), assigned by the server, should not be interpreted by the application. Guaranteed to be safe for embedding in URLs.
  --kind: string@kind-completer # Zone kind, one of “Native”, “Master”, “Slave”
  --master-tsig-key-ids: list<string> # The id of the TSIG keys used for master operation in this zone
  --masters: list<string> # List of IP addresses configured as a master for this zone (“Slave” type zones only)
  --name: string # Name of the zone (e.g. “example.com.”) MUST have a trailing dot
  --nameservers: list<string> # MAY be sent in client bodies during creation, and MUST NOT be sent by the server. Simple list of strings of nameserver names, including the trailing dot. Not required for slave zones.
  --notified-serial: int # The SOA serial notifications have been sent out for
  --nsec3narrow: oneof<nothing, bool> # Whether or not the zone uses NSEC3 narrow
  --nsec3param: string # The NSEC3PARAM record
  --presigned: oneof<nothing, bool> # Whether or not the zone is pre-signed
  --rrsets-body: list # RRSets in this zone (for zones/{zone_id} endpoint only; omitted during GET on the .../zones list endpoint) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string} (body field)
  --serial: int # The SOA serial number
  --slave-tsig-key-ids: list<string> # The id of the TSIG keys used for slave operation in this zone
  --soa-edit: string # The SOA-EDIT metadata item
  --soa-edit-api: string # The SOA-EDIT-API metadata item
  --type: string # Set to “Zone”
  --url: string # API endpoint for this zone
  --zone: string # MAY contain a BIND-style zone file when creating a zone
]: any -> record<account: string, api_rectify: bool, dnssec: bool, edited_serial: int, id: string, kind: string, master_tsig_key_ids: list<string>, masters: list<string>, name: string, nameservers: list<string>, notified_serial: int, nsec3narrow: bool, nsec3param: string, presigned: bool, rrsets: table<changetype: string, comments: list, name: string, records: list, ttl: int, type: string>, serial: int, slave_tsig_key_ids: list<string>, soa_edit: string, soa_edit_api: string, type: string, url: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  let qp = [(serialize-qp "rrsets" $rrsets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id)} | format pattern "/servers/{server_id}/zones") $qp)
  let req_body = {"account": $account, "api_rectify": $api_rectify, "dnssec": $dnssec, "edited_serial": $edited_serial, "id": $id, "kind": $kind, "master_tsig_key_ids": $master_tsig_key_ids, "masters": $masters, "name": $name, "nameservers": $nameservers, "notified_serial": $notified_serial, "nsec3narrow": $nsec3narrow, "nsec3param": $nsec3param, "presigned": $presigned, "rrsets": $rrsets_body, "serial": $serial, "slave_tsig_key_ids": $slave_tsig_key_ids, "soa_edit": $soa_edit, "soa_edit_api": $soa_edit_api, "type": $type, "url": $url, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"rrsets": $rrsets} | compact), body: $req_body}
}

# Deletes this zone, all attached metadata and rrsets.
#
# DELETE /servers/{server_id}/zones/{zone_id}
# operationId: deleteZone
export def "servers-zones delete" [
  server_id: string
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# zone managed by a server
#
# GET /servers/{server_id}/zones/{zone_id}
# operationId: listZone
export def "servers-zones list-1" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rrsets: oneof<nothing, bool> # “true” (default) or “false”, whether to include the “rrsets” in the response Zone object. (default: true)
]: nothing -> record<account: string, api_rectify: bool, dnssec: bool, edited_serial: int, id: string, kind: string, master_tsig_key_ids: list<string>, masters: list<string>, name: string, nameservers: list<string>, notified_serial: int, nsec3narrow: bool, nsec3param: string, presigned: bool, rrsets: table<changetype: string, comments: list, name: string, records: list, ttl: int, type: string>, serial: int, slave_tsig_key_ids: list<string>, soa_edit: string, soa_edit_api: string, type: string, url: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let qp = [(serialize-qp "rrsets" $rrsets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rrsets": $rrsets} | compact), body: null}
}

# Creates/modifies/deletes RRsets present in the payload and their comments. Returns 204 No Content on success.
#
# PATCH /servers/{server_id}/zones/{zone_id}
# operationId: patchZone
# --rrsets item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
export def "servers-zones update-by-server-id-zone-id" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # MAY be set. Its value is defined by local policy
  --api-rectify: oneof<nothing, bool> # Whether or not the zone will be rectified on data changes via the API
  --dnssec: oneof<nothing, bool> # Whether or not this zone is DNSSEC signed (inferred from presigned being true XOR presence of at least one cryptokey with active being true)
  --edited-serial: int # The SOA serial as seen in query responses. Calculated using the SOA-EDIT metadata, default-soa-edit and default-soa-edit-signed settings
  --id: string # Opaque zone id (string), assigned by the server, should not be interpreted by the application. Guaranteed to be safe for embedding in URLs.
  --kind: string@kind-completer # Zone kind, one of “Native”, “Master”, “Slave”
  --master-tsig-key-ids: list<string> # The id of the TSIG keys used for master operation in this zone
  --masters: list<string> # List of IP addresses configured as a master for this zone (“Slave” type zones only)
  --name: string # Name of the zone (e.g. “example.com.”) MUST have a trailing dot
  --nameservers: list<string> # MAY be sent in client bodies during creation, and MUST NOT be sent by the server. Simple list of strings of nameserver names, including the trailing dot. Not required for slave zones.
  --notified-serial: int # The SOA serial notifications have been sent out for
  --nsec3narrow: oneof<nothing, bool> # Whether or not the zone uses NSEC3 narrow
  --nsec3param: string # The NSEC3PARAM record
  --presigned: oneof<nothing, bool> # Whether or not the zone is pre-signed
  --rrsets: list # RRSets in this zone (for zones/{zone_id} endpoint only; omitted during GET on the .../zones list endpoint) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --serial: int # The SOA serial number
  --slave-tsig-key-ids: list<string> # The id of the TSIG keys used for slave operation in this zone
  --soa-edit: string # The SOA-EDIT metadata item
  --soa-edit-api: string # The SOA-EDIT-API metadata item
  --type: string # Set to “Zone”
  --url: string # API endpoint for this zone
  --zone: string # MAY contain a BIND-style zone file when creating a zone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}"))
  let req_body = {"account": $account, "api_rectify": $api_rectify, "dnssec": $dnssec, "edited_serial": $edited_serial, "id": $id, "kind": $kind, "master_tsig_key_ids": $master_tsig_key_ids, "masters": $masters, "name": $name, "nameservers": $nameservers, "notified_serial": $notified_serial, "nsec3narrow": $nsec3narrow, "nsec3param": $nsec3param, "presigned": $presigned, "rrsets": $rrsets, "serial": $serial, "slave_tsig_key_ids": $slave_tsig_key_ids, "soa_edit": $soa_edit, "soa_edit_api": $soa_edit_api, "type": $type, "url": $url, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Modifies basic zone data.
#
# PUT /servers/{server_id}/zones/{zone_id}
# operationId: putZone
# --rrsets item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
export def "servers-zones update-by-server-id-zone-id-1" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # MAY be set. Its value is defined by local policy
  --api-rectify: oneof<nothing, bool> # Whether or not the zone will be rectified on data changes via the API
  --dnssec: oneof<nothing, bool> # Whether or not this zone is DNSSEC signed (inferred from presigned being true XOR presence of at least one cryptokey with active being true)
  --edited-serial: int # The SOA serial as seen in query responses. Calculated using the SOA-EDIT metadata, default-soa-edit and default-soa-edit-signed settings
  --id: string # Opaque zone id (string), assigned by the server, should not be interpreted by the application. Guaranteed to be safe for embedding in URLs.
  --kind: string@kind-completer # Zone kind, one of “Native”, “Master”, “Slave”
  --master-tsig-key-ids: list<string> # The id of the TSIG keys used for master operation in this zone
  --masters: list<string> # List of IP addresses configured as a master for this zone (“Slave” type zones only)
  --name: string # Name of the zone (e.g. “example.com.”) MUST have a trailing dot
  --nameservers: list<string> # MAY be sent in client bodies during creation, and MUST NOT be sent by the server. Simple list of strings of nameserver names, including the trailing dot. Not required for slave zones.
  --notified-serial: int # The SOA serial notifications have been sent out for
  --nsec3narrow: oneof<nothing, bool> # Whether or not the zone uses NSEC3 narrow
  --nsec3param: string # The NSEC3PARAM record
  --presigned: oneof<nothing, bool> # Whether or not the zone is pre-signed
  --rrsets: list # RRSets in this zone (for zones/{zone_id} endpoint only; omitted during GET on the .../zones list endpoint) — item shape: {changetype: string, comments?: list, name: string, records: list, ttl: int, type: string}
  --serial: int # The SOA serial number
  --slave-tsig-key-ids: list<string> # The id of the TSIG keys used for slave operation in this zone
  --soa-edit: string # The SOA-EDIT metadata item
  --soa-edit-api: string # The SOA-EDIT-API metadata item
  --type: string # Set to “Zone”
  --url: string # API endpoint for this zone
  --zone: string # MAY contain a BIND-style zone file when creating a zone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}"))
  let req_body = {"account": $account, "api_rectify": $api_rectify, "dnssec": $dnssec, "edited_serial": $edited_serial, "id": $id, "kind": $kind, "master_tsig_key_ids": $master_tsig_key_ids, "masters": $masters, "name": $name, "nameservers": $nameservers, "notified_serial": $notified_serial, "nsec3narrow": $nsec3narrow, "nsec3param": $nsec3param, "presigned": $presigned, "rrsets": $rrsets, "serial": $serial, "slave_tsig_key_ids": $slave_tsig_key_ids, "soa_edit": $soa_edit, "soa_edit_api": $soa_edit_api, "type": $type, "url": $url, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve slave zone from its master.
#
# PUT /servers/{server_id}/zones/{zone_id}/axfr-retrieve
# operationId: axfrRetrieveZone
export def "servers-zones-axfr-retrieve get" [
  server_id: string
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/axfr-retrieve"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all CryptoKeys for a zone, except the privatekey
#
# GET /servers/{server_id}/zones/{zone_id}/cryptokeys
# operationId: listCryptokeys
export def "servers-zones-cryptokeys list" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, algorithm: string, bits: int, dnskey: string, ds: list<string>, id: int, keytype: string, privatekey: string, published: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/cryptokeys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a Cryptokey
#
# POST /servers/{server_id}/zones/{zone_id}/cryptokeys
# operationId: createCryptokey
export def "servers-zones-cryptokeys create" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether or not the key is in active use
  --algorithm: string # The name of the algorithm of the key, should be a mnemonic
  --bits: int # The size of the key
  --dnskey: string # The DNSKEY record for this key
  --ds: list<string> # An array of DS records for this key
  --id: int # The internal identifier, read only
  --keytype: string@keytype-completer
  --privatekey: string # The private key in ISC format
  --published: oneof<nothing, bool> # Whether or not the DNSKEY record is published in the zone
  --type: string # set to "Cryptokey"
]: any -> record<active: bool, algorithm: string, bits: int, dnskey: string, ds: list<string>, id: int, keytype: string, privatekey: string, published: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/cryptokeys"))
  let req_body = {"active": $active, "algorithm": $algorithm, "bits": $bits, "dnskey": $dnskey, "ds": $ds, "id": $id, "keytype": $keytype, "privatekey": $privatekey, "published": $published, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This method deletes a key specified by cryptokey_id.
#
# DELETE /servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}
# operationId: deleteCryptokey
export def "servers-zones-cryptokeys delete" [
  server_id: string
  zone_id: string
  cryptokey_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($cryptokey_id | is-empty) { error make --unspanned { msg: "path parameter 'cryptokey_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id), cryptokey_id: (encode-path-segment $cryptokey_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns all data about the CryptoKey, including the privatekey.
#
# GET /servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}
# operationId: getCryptokey
export def "servers-zones-cryptokeys get" [
  server_id: string
  zone_id: string
  cryptokey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, algorithm: string, bits: int, dnskey: string, ds: list<string>, id: int, keytype: string, privatekey: string, published: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($cryptokey_id | is-empty) { error make --unspanned { msg: "path parameter 'cryptokey_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id), cryptokey_id: (encode-path-segment $cryptokey_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method (de)activates a key from zone_name specified by cryptokey_id
#
# PUT /servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}
# operationId: modifyCryptokey
export def "servers-zones-cryptokeys update-modify" [
  server_id: string
  zone_id: string
  cryptokey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Whether or not the key is in active use
  --algorithm: string # The name of the algorithm of the key, should be a mnemonic
  --bits: int # The size of the key
  --dnskey: string # The DNSKEY record for this key
  --ds: list<string> # An array of DS records for this key
  --id: int # The internal identifier, read only
  --keytype: string@keytype-completer
  --privatekey: string # The private key in ISC format
  --published: oneof<nothing, bool> # Whether or not the DNSKEY record is published in the zone
  --type: string # set to "Cryptokey"
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($cryptokey_id | is-empty) { error make --unspanned { msg: "path parameter 'cryptokey_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id), cryptokey_id: (encode-path-segment $cryptokey_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/cryptokeys/{cryptokey_id}"))
  let req_body = {"active": $active, "algorithm": $algorithm, "bits": $bits, "dnskey": $dnskey, "ds": $ds, "id": $id, "keytype": $keytype, "privatekey": $privatekey, "published": $published, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the zone in AXFR format.
#
# GET /servers/{server_id}/zones/{zone_id}/export
# operationId: axfrExportZone
export def "servers-zones-export export-axfr" [
  server_id: string
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/export"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the Metadata associated with the zone.
#
# GET /servers/{server_id}/zones/{zone_id}/metadata
# operationId: listMetadata
export def "servers-zones-metadata list" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<kind: string, metadata: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a set of metadata entries
#
# POST /servers/{server_id}/zones/{zone_id}/metadata
# operationId: createMetadata
export def "servers-zones-metadata create" [
  server_id: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Name of the metadata
  --metadata: list<string> # Array with all values for this metadata kind.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/metadata"))
  let req_body = {"kind": $kind, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete all items of a single kind of domain metadata.
#
# DELETE /servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}
# operationId: deleteMetadata
export def "servers-zones-metadata delete" [
  server_id: string
  zone_id: string
  metadata_kind: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($metadata_kind | is-empty) { error make --unspanned { msg: "path parameter 'metadata_kind' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id), metadata_kind: (encode-path-segment $metadata_kind)} | format pattern "/servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the content of a single kind of domain metadata as a Metadata object.
#
# GET /servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}
# operationId: getMetadata
export def "servers-zones-metadata get" [
  server_id: string
  zone_id: string
  metadata_kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kind: string, metadata: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($metadata_kind | is-empty) { error make --unspanned { msg: "path parameter 'metadata_kind' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id), metadata_kind: (encode-path-segment $metadata_kind)} | format pattern "/servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Replace the content of a single kind of domain metadata.
#
# PUT /servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}
# operationId: modifyMetadata
export def "servers-zones-metadata update-modify" [
  server_id: string
  zone_id: string
  metadata_kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Name of the metadata
  --metadata: list<string> # Array with all values for this metadata kind.
]: any -> record<kind: string, metadata: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  if ($metadata_kind | is-empty) { error make --unspanned { msg: "path parameter 'metadata_kind' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id), metadata_kind: (encode-path-segment $metadata_kind)} | format pattern "/servers/{server_id}/zones/{zone_id}/metadata/{metadata_kind}"))
  let req_body = {"kind": $kind, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a DNS NOTIFY to all slaves.
#
# PUT /servers/{server_id}/zones/{zone_id}/notify
# operationId: notifyZone
export def "servers-zones-notify notify" [
  server_id: string
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/notify"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Rectify the zone data.
#
# PUT /servers/{server_id}/zones/{zone_id}/rectify
# operationId: rectifyZone
export def "servers-zones-rectify update" [
  server_id: string
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'server_id' must be non-empty" } }
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zone_id' must be non-empty" } }
  let full_url = (build-url $base ({server_id: (encode-path-segment $server_id), zone_id: (encode-path-segment $zone_id)} | format pattern "/servers/{server_id}/zones/{zone_id}/rectify"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
